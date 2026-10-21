import AppIntents

/// "When is my package coming?" for Siri, Spotlight and Shortcuts. Reads the last check, never the network.
struct NextDeliveryIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Delivery"
    static let description = IntentDescription("How many days until your next package shows up.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let parcels = (try? JSONDecoder().decode([Parcel].self, from: defaults.data(forKey: "parcels") ?? Data())) ?? []
        let etas = defaults.dictionary(forKey: "lastETA") as? [String: Date] ?? [:]
        let next = parcels.filter { !$0.isArchived }
            .compactMap { p in etas[p.number].map { (p, $0) } }
            .min { $0.1 < $1.1 }
        guard let (parcel, date) = next else { return .result(dialog: "Nothing's on the way right now.") }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: .now), to: cal.startOfDay(for: date)).day ?? 0
        let name = parcel.name.isEmpty ? String(localized: "Your package") : parcel.name
        let when = days <= 0 ? String(localized: "arrives today") : days == 1 ? String(localized: "arrives tomorrow") : String(localized: "arrives in \(days) days")
        return .result(dialog: "\(name) \(when).")
    }
}

struct CartonsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: NextDeliveryIntent(),
                    phrases: ["When is my package coming in \(.applicationName)", "Next delivery in \(.applicationName)"],
                    shortTitle: "Next Delivery", systemImageName: "shippingbox")
    }
}
