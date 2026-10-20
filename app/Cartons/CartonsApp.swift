import SwiftUI

@main
struct CartonsApp: App {
    @State private var store = Store()

    init() {
        Brand.registerFonts()
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-onboarding") { UserDefaults.standard.set(false, forKey: "onboarded") }  // QA hooks
        else if args.contains("-demo") { UserDefaults.standard.set(true, forKey: "onboarded") }
    }

    var body: some Scene {
        WindowGroup {
            Root()
                .environment(store)
                .font(.carton(.body))
                .tint(Brand.accent)
        }
        #if os(macOS)
        .defaultSize(width: 520, height: 760)
        #endif
    }
}

/// Splash, then onboarding on first run, then the tabs.
private struct Root: View {
    @AppStorage("onboarded") private var onboarded = false
    @State private var splash = true
    @State private var tab = ProcessInfo.processInfo.arguments.firstIndex(of: "-tab").map { Int(ProcessInfo.processInfo.arguments[$0 + 1]) ?? 0 } ?? 0  // QA hook: -tab 2

    var body: some View {
        ZStack {
            if onboarded {
                TabView(selection: $tab) {
                    PackageList(archive: false).tabItem { Label("Packages", systemImage: "shippingbox") }.tag(0)
                    PackageList(archive: true).tabItem { Label("Archive", systemImage: "archivebox") }.tag(1)
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(2)
                }
            } else if !splash {
                Onboarding { withAnimation(.easeInOut(duration: 0.35)) { onboarded = true } }.transition(.opacity)
            }
            if splash { Splash().transition(.opacity).zIndex(1) }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("-splash") { return }  // QA hook: hold the splash
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeOut(duration: 0.35)) { splash = false }
        }
    }
}
