import Foundation
import AppKit
import GhosttyKit

/// Singleton managing the ghostty app lifecycle.
/// Mirrors the pattern cmux uses: one ghostty_app_t for the entire process.
@MainActor
final class GhosttyService {
    static let shared = GhosttyService()

    private(set) var app: ghostty_app_t?
    private(set) var config: ghostty_config_t?
    private var tickTimer: Timer?

    private init() {
        initializeGhostty()
    }

    private func initializeGhostty() {
        // Ensure TUI apps can use colors
        if getenv("NO_COLOR") != nil {
            unsetenv("NO_COLOR")
        }

        let result = ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv)
        guard result == GHOSTTY_SUCCESS else {
            print("[Muxy] ghostty_init failed: \(result)")
            return
        }

        guard let cfg = ghostty_config_new() else {
            print("[Muxy] ghostty_config_new failed")
            return
        }

        // Load user's ghostty config (~/.config/ghostty/config)
        ghostty_config_load_default_files(cfg)
        ghostty_config_finalize(cfg)

        // Runtime callbacks
        var rt = ghostty_runtime_config_s()
        rt.userdata = Unmanaged.passUnretained(self).toOpaque()
        rt.supports_selection_clipboard = true
        rt.wakeup_cb = { _ in
            DispatchQueue.main.async {
                GhosttyService.shared.tick()
            }
        }
        rt.action_cb = { app, target, action in
            return GhosttyService.shared.handleAction(target: target, action: action)
        }
        rt.read_clipboard_cb = { userdata, location, state in
            let pb = NSPasteboard.general
            let text = pb.string(forType: .string) ?? ""
            text.withCString { ptr in
                ghostty_surface_complete_clipboard_request(
                    GhosttyService.callbackSurface(from: userdata),
                    ptr, state, false
                )
            }
            return true
        }
        rt.confirm_read_clipboard_cb = { userdata, content, state, _ in
            guard let content else { return }
            ghostty_surface_complete_clipboard_request(
                GhosttyService.callbackSurface(from: userdata),
                content, state, true
            )
        }
        rt.write_clipboard_cb = { _, location, content, len, _ in
            guard let content, len > 0 else { return }
            let buffer = UnsafeBufferPointer(start: content, count: Int(len))
            for item in buffer {
                guard let dataPtr = item.data else { continue }
                let value = String(cString: dataPtr)
                if let mimePtr = item.mime {
                    let mime = String(cString: mimePtr)
                    if mime.hasPrefix("text/plain") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(value, forType: .string)
                        return
                    }
                }
            }
        }
        rt.close_surface_cb = { userdata, needsConfirm in
            // Surface close is handled by the view layer
        }

        guard let createdApp = ghostty_app_new(&rt, cfg) else {
            print("[Muxy] ghostty_app_new failed")
            ghostty_config_free(cfg)
            return
        }

        self.app = createdApp
        self.config = cfg

        // Start tick timer for animation/rendering
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    func tick() {
        guard let app else { return }
        _ = ghostty_app_tick(app)
    }

    private func handleAction(target: ghostty_target_s, action: ghostty_action_s) -> Bool {
        let tag = action.tag
        switch tag {
        case GHOSTTY_ACTION_SET_TITLE:
            // Title updates are handled via surface userdata
            return true
        case GHOSTTY_ACTION_DESKTOP_NOTIFICATION:
            return true
        default:
            return false
        }
    }

    nonisolated static func callbackSurface(from userdata: UnsafeMutableRawPointer?) -> ghostty_surface_t? {
        // In our setup, surface userdata points to the GhosttyTerminalNSView
        return nil // clipboard reads require surface — handled per-surface
    }

    // Singleton — lives for the entire app lifetime, no cleanup needed
}
