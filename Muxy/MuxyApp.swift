import AppKit
import SwiftUI

@main
struct MuxyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var projectStore = ProjectStore()

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environment(appState)
                .environment(projectStore)
                .preferredColorScheme(.dark)
                .background(WindowConfigurator())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .defaultSize(width: 1200, height: 800)
        .commands {
            MuxyCommands(appState: appState)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var doubleClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        _ = GhosttyService.shared

        doubleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { event in
            guard event.clickCount == 2, let window = event.window else { return event }
            let hitView = window.contentView?.hitTest(event.locationInWindow)
            if hitView is GhosttyTerminalNSView { return event }
            let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") ?? "Maximize"
            switch action {
            case "Minimize":
                window.miniaturize(nil)
            default:
                window.zoom(nil)
            }
            return nil
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.styleMask.insert(.fullSizeContentView)
            w.isMovableByWindowBackground = true
            w.backgroundColor = MuxyTheme.nsBg

            for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                if let btn = w.standardWindowButton(button) {
                    btn.superview?.frame.origin.y = -3
                }
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
