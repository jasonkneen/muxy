import SwiftUI

@main
struct MuxyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var projectStore = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(projectStore)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            MuxyCommands(appState: appState)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Initialize ghostty engine
        _ = GhosttyService.shared
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
