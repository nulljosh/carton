import Foundation
import Observation

struct Parcel: Codable, Identifiable, Hashable {
    var number: String
    var name: String
    var archived: Bool? = nil  // optional so lists saved before archiving still decode
    var id: String { number }
    var isArchived: Bool { archived ?? false }
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

    private let key = "parcels"
    // ponytail: UserDefaults, move to NSUbiquitousKeyValueStore when a second device matters

    private let cloud = NSUbiquitousKeyValueStore.default
    private var syncOn: Bool { UserDefaults.standard.object(forKey: "sync") as? Bool ?? true }

    var active: [Parcel] { parcels.filter { !$0.isArchived } }
    var archived: [Parcel] { parcels.filter(\.isArchived) }

    init() {
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
        do {
            statuses[n] = try await UPSPage().fetch(n)
            errors[n] = nil
        } catch {
            errors[n] = "UPS didn't answer. Pull to retry."
        }
    }

    func save() {
        let d = try? JSONEncoder().encode(parcels)
        UserDefaults.standard.set(d, forKey: key)
        if syncOn { cloud.set(d, forKey: key) }
    }
}
