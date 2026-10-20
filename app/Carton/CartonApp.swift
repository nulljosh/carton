import SwiftUI

@main
struct CartonApp: App {
    @State private var store = Store()

    init() { Brand.registerFonts() }
    @State private var tab = ProcessInfo.processInfo.arguments.firstIndex(of: "-tab").map { Int(ProcessInfo.processInfo.arguments[$0 + 1]) ?? 0 } ?? 0  // QA hook: -tab 2

    var body: some Scene {
        WindowGroup {
            TabView(selection: $tab) {
                PackageList(archive: false).tabItem { Label("Packages", systemImage: "shippingbox") }.tag(0)
                PackageList(archive: true).tabItem { Label("Archive", systemImage: "archivebox") }.tag(1)
                SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(2)
            }
            .environment(store)
            .font(.carton(.body))
            .tint(Brand.accent)
        }
    }
}
