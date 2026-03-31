import SwiftUI
import AppKit

struct TerminalPaneView: View {
    let paneState: TerminalPaneState
    let isFocused: Bool
    let onFocus: () -> Void
    let onSplit: (SplitDirection) -> Void
    let onClose: () -> Void

    var body: some View {
        GhosttyTerminalRepresentable(paneState: paneState, onFocus: onFocus)
            .overlay {
                if isFocused {
                    Rectangle()
                        .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
    }
}

struct GhosttyTerminalRepresentable: NSViewRepresentable {
    let paneState: TerminalPaneState
    let onFocus: () -> Void

    func makeNSView(context: Context) -> GhosttyTerminalNSView {
        let view = GhosttyTerminalNSView(workingDirectory: paneState.projectPath)
        view.onFocus = onFocus
        view.onTitleChange = { [weak paneState] title in
            paneState?.title = title
        }

        // Focus the terminal after the window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            view.window?.makeFirstResponder(view)
        }

        return view
    }

    func updateNSView(_ nsView: GhosttyTerminalNSView, context: Context) {
        // Reclaim focus on tab switch
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}
