import Foundation
import Observation

struct Parcel: Codable, Identifiable, Hashable {
    var number: String
    var name: String
    var archived: Bool? = nil  // optional so lists saved before archiving still decode
    var id: String { number }
    var isArchived: Bool { archived ?? false }
}

struct Step: Hashable {
    var name: String
    var state: String  // completed, active or inactive
}

struct Status {
    var number: String
    var status: String
    var eta: String?
    var etaDate: Date?
    var delivered: Bool
    var lastLocation: String?
    var service: String?
    var shipTo: String?
    var steps: [Step] = []

    /// Whole days from today to the ETA, nil when UPS gave none.
    var daysLeft: Int? {
        guard let etaDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: etaDate)).day
    }
}

@Observable
@MainActor
final class Store {
    var parcels: [Parcel] = []
    var statuses: [String: Status] = [:]
    var errors: [String: String] = [:]
    var checked: [String: Date] = [:]  // last successful read per number

    private let key = "parcels"
    // ponytail: UserDefaults, move to NSUbiquitousKeyValueStore when a second device matters

    private let cloud = NSUbiquitousKeyValueStore.default
    private var syncOn: Bool { UserDefaults.standard.object(forKey: "sync") as? Bool ?? true }

    var active: [Parcel] { parcels.filter { !$0.isArchived } }
    var archived: [Parcel] { parcels.filter(\.isArchived) }

    /// Sample packages for App Store screenshots (-demo, debug builds only). Never saved, never refreshed.
    private(set) var isDemo = false

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demo") { loadDemo(); return }
        #endif
        if let d = UserDefaults.standard.data(forKey: key), let p = try? JSONDecoder().decode([Parcel].self, from: d) { parcels = p }
        // iCloud key-value sync: same list on every device signed into the same Apple Account
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.pullFromCloud() }
        }
        cloud.synchronize()
        pullFromCloud()
        let args = ProcessInfo.processInfo.arguments  // QA hook: -add <url or number>
        if let i = args.firstIndex(of: "-add"), i + 1 < args.count { add(args[i + 1]) }
    }

    #if DEBUG
    private func loadDemo() {
        isDemo = true
        let day = { (n: Int) in Calendar.current.date(byAdding: .day, value: n, to: .now)! }
        let steps = { (current: Int) in ["Label Created", "We Have Your Package", "On the Way", "Out for Delivery", "Delivery"].enumerated().map {
            Step(name: $0.element, state: $0.offset < current ? "completed" : $0.offset == current ? "active" : "inactive") } }
        // UPS's published sample number pattern; none of these are real shipments
        let demo: [(String, String, String, Int, Int, String)] = [
            ("1Z999AA10123456784", "Coffee grinder", "Out for Delivery", 0, 3, "Portland, OR"),
            ("1Z999AA10123456785", "Running shoes", "On the Way", 2, 2, "Louisville, KY"),
            ("1Z999AA10123456786", "Book", "On the Way", 7, 2, "Ontario, CA"),
            ("1Z999AA10123456787", "Desk lamp", "We Have Your Package", 9, 1, "Hodgkins, IL"),
        ]
        parcels = demo.map { Parcel(number: $0.0, name: $0.1) } + [Parcel(number: "1Z999AA10123456788", name: "Headphones", archived: true)]
        for d in demo {
            let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"
            statuses[d.0] = Status(number: d.0, status: d.2, eta: d.3 == 0 ? "Today, by 8:00 P.M." : f.string(from: day(d.3)) + ", 9:00 A.M. - 1:00 P.M.",
                                   etaDate: day(d.3), delivered: false, lastLocation: d.5, service: "UPS® Ground", shipTo: "SEATTLE, WA US", steps: steps(d.4))
        }
        statuses["1Z999AA10123456788"] = Status(number: "1Z999AA10123456788", status: "Delivered", eta: "Monday, 10/12/2026 at 2:14 P.M.",
                                                etaDate: day(-8), delivered: true, lastLocation: "Seattle, WA", service: "UPS® Ground", shipTo: "SEATTLE, WA US", steps: steps(5))
    }
    #endif

    /// Accepts a bare number or a pasted tracking link.
    static func parse(_ text: String) -> String? {
        text.range(of: "1Z[0-9A-Za-z]{16}", options: .regularExpression).map { String(text[$0]).uppercased() }
    }

    @discardableResult
    func add(_ text: String, name: String = "") -> Bool {
        guard let n = Store.parse(text) else { return false }
        if !parcels.contains(where: { $0.number == n }) {
            parcels.insert(Parcel(number: n, name: name), at: 0)
            save()
        }
        Task { await refresh(n) }
        return true
    }

    func rename(_ p: Parcel, _ name: String) {
        guard let i = parcels.firstIndex(where: { $0.number == p.number }) else { return }
        parcels[i].name = name.trimmingCharacters(in: .whitespaces)
        save()
    }

    func setArchived(_ p: Parcel, _ on: Bool) {
        guard let i = parcels.firstIndex(of: p) else { return }
        parcels[i].archived = on
        save()
    }

    /// Merges the iCloud copy in: union by number, iCloud wins on archive state.
    func pullFromCloud() {
        guard syncOn, let d = cloud.data(forKey: key), let remote = try? JSONDecoder().decode([Parcel].self, from: d) else { return }
        for r in remote {
            if let i = parcels.firstIndex(where: { $0.number == r.number }) { parcels[i].archived = r.archived } else { parcels.append(r) }
        }
        UserDefaults.standard.set(try? JSONEncoder().encode(parcels), forKey: key)
    }

    func remove(_ p: Parcel) {
        parcels.removeAll { $0 == p }
        save()
    }

    func refreshAll() async {
        for p in parcels { await refresh(p.number) }
    }

    func refresh(_ n: String) async {
        guard !isDemo else { return }
        do {
            statuses[n] = try await UPSPage().fetch(n)
            errors[n] = nil
            checked[n] = .now
        } catch {
            errors[n] = "UPS didn't answer. Pull to retry."
        }
    }

    func save() {
        guard !isDemo else { return }
        let d = try? JSONEncoder().encode(parcels)
        UserDefaults.standard.set(d, forKey: key)
        if syncOn { cloud.set(d, forKey: key) }
    }
}
