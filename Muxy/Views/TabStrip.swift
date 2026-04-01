import SwiftUI

struct PaneTabStrip: View {
    let area: TabArea
    let isFocused: Bool
    let onCloseTab: (UUID) -> Void
    let onSplit: (SplitDirection) -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(area.tabs) { tab in
                TabCell(
                    title: tab.title,
                    active: tab.id == area.activeTabID,
                    paneFocused: isFocused,
                    onSelect: { area.selectTab(tab.id) },
                    onClose: { onCloseTab(tab.id) }
                )
            }

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                IconButton(symbol: "square.split.2x1") { onSplit(.horizontal) }
                IconButton(symbol: "square.split.1x2") { onSplit(.vertical) }
                IconButton(symbol: "plus") { area.createTab() }
            }
            .padding(.trailing, 4)
        }
        .frame(height: 32)
        .background(WindowDragRepresentable())
    }
}

struct WindowDragRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragView { WindowDragView() }
    func updateNSView(_ nsView: WindowDragView, context: Context) {}
}

final class WindowDragView: NSView {
    private var isAtWindowTop: Bool {
        guard let window else { return false }
        let frameInWindow = convert(bounds, to: nil)
        return frameInWindow.maxY >= window.contentView!.bounds.height - 1
    }

    override public func mouseDown(with event: NSEvent) {
        guard isAtWindowTop else {
            super.mouseDown(with: event)
            return
        }
        if event.clickCount == 2 {
            let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") ?? "Maximize"
            switch action {
            case "Minimize":
                window?.miniaturize(nil)
            default:
                window?.zoom(nil)
            }
            return
        }
        window?.performDrag(with: event)
    }
}

private struct TabCell: View {
    let title: String
    let active: Bool
    let paneFocused: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(active ? MuxyTheme.text : MuxyTheme.textMuted)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(active ? MuxyTheme.text : MuxyTheme.textMuted)
                    .lineLimit(1)
            }
            .padding(.leading, 12)
            .padding(.trailing, 28)
            .frame(maxWidth: 200, alignment: .leading)
            .frame(height: 32)
            .overlay(alignment: .trailing) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MuxyTheme.textDim)
                    .padding(.trailing, 10)
                    .opacity(active || hovered ? 1 : 0)
                    .onTapGesture(perform: onClose)
            }
            .overlay(alignment: .top) {
                if active && paneFocused {
                    Rectangle()
                        .fill(MuxyTheme.accent)
                        .frame(height: 2)
                }
            }
            .background(active ? MuxyTheme.surface : .clear)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .onHover { hovered = $0 }

            Rectangle().fill(MuxyTheme.border).frame(width: 1)
        }
    }
}
