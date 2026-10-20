import SwiftUI

struct SettingsView: View {
    @Environment(Store.self) private var store
    @AppStorage("profileName") private var name = ""
    @AppStorage("sync") private var sync = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack(spacing: 16) {
                        Text(String(name.first ?? "C").uppercased())
                            .font(.title2.weight(.semibold)).foregroundStyle(.white)
                            .frame(width: 48, height: 48).background(Brand.accent, in: Circle())
                        TextField("Your name", text: $name).font(.headline)
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    Toggle("iCloud Sync", isOn: $sync)
                        .onChange(of: sync) { _, on in if on { store.pullFromCloud(); store.save() } }
                } header: {
                    Text("Sync")
                } footer: {
                    Text("Keeps your packages the same on every device signed into your Apple Account. Nothing goes to our servers. We don't have any.")
                }
                Section("Packages") {
                    LabeledContent("Tracking", value: "\(store.active.count)")
                    LabeledContent("Archived", value: "\(store.archived.count)")
                    Button("Refresh all") { Task { await store.refreshAll() } }
                }
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                    LabeledContent("Carriers", value: "UPS")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
