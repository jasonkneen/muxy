import Foundation
import AppKit
import GhosttyKit

@MainActor
final class GhosttyService {
    static let shared = GhosttyService()

    private(set) var app: ghostty_app_t?
    private(set) var config: ghostty_config_t?
    private var tickTimer: Timer?
    private let runtimeEvents: any GhosttyRuntimeEventHandling = GhosttyRuntimeEventAdapter()

    private init() {
        initializeGhostty()
    }

    private func initializeGhostty() {
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

        ghostty_config_load_default_files(cfg)
        ghostty_config_finalize(cfg)

        var rt = ghostty_runtime_config_s()
        rt.userdata = Unmanaged.passUnretained(self).toOpaque()
        rt.supports_selection_clipboard = true
        rt.wakeup_cb = { _ in
            GhosttyService.shared.runtimeEvents.wakeup()
        }
        rt.action_cb = { app, target, action in
            return GhosttyService.shared.runtimeEvents.action(app: app, target: target, action: action)
        }
        rt.read_clipboard_cb = { userdata, location, state in
            GhosttyService.shared.runtimeEvents.readClipboard(userdata: userdata, location: location, state: state)
        }
        rt.confirm_read_clipboard_cb = { userdata, content, state, _ in
            GhosttyService.shared.runtimeEvents.confirmReadClipboard(userdata: userdata, content: content, state: state)
        }
        rt.write_clipboard_cb = { _, location, content, len, _ in
            GhosttyService.shared.runtimeEvents.writeClipboard(location: location, content: content, len: UInt(len))
        }
        rt.close_surface_cb = { userdata, needsConfirm in
            GhosttyService.shared.runtimeEvents.closeSurface(userdata: userdata, needsConfirm: needsConfirm)
        }

        guard let createdApp = ghostty_app_new(&rt, cfg) else {
            print("[Muxy] ghostty_app_new failed")
            ghostty_config_free(cfg)
            return
        }

        self.app = createdApp
        self.config = cfg

        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    func tick() {
        guard let app else { return }
        ghostty_app_tick(app)
    }
}
