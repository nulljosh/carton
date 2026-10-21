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
                #if os(iOS)
                IconPicker()
                #endif
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                    LabeledContent("Carriers", value: "UPS")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#if os(iOS)
/// The kraft box is the default icon; Tuck is the alternate (iPhone and iPad only, the Mac can't switch icons).
private struct IconPicker: View {
    @State private var current = UIApplication.shared.alternateIconName

    var body: some View {
        Section("App icon") {
            row("Box", icon: nil, preview: "BoxPreview")
            row("Tuck", icon: "Tuck", preview: "TuckPreview")
        }
    }

    private func row(_ label: LocalizedStringKey, icon: String?, preview: String) -> some View {
        Button {
            Task { try? await UIApplication.shared.setAlternateIconName(icon); current = UIApplication.shared.alternateIconName }
        } label: {
            HStack(spacing: 16) {
                Image(preview).resizable().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(label).foregroundStyle(.primary)
                Spacer()
                if current == icon { Image(systemName: "checkmark").foregroundStyle(Brand.accent).fontWeight(.semibold) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(current == icon ? .isSelected : [])
    }
}
#endif
