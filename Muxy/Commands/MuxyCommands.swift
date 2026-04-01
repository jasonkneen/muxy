import SwiftUI

struct MuxyCommands: Commands {
    let appState: AppState

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                guard let projectID = appState.activeProjectID else { return }
                appState.createTab(projectID: projectID)
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Close Tab") {
                guard let projectID = appState.activeProjectID,
                      let area = appState.focusedArea(for: projectID),
                      let tabID = area.activeTabID else { return }
                appState.closeTab(tabID, projectID: projectID)
            }
            .keyboardShortcut("w", modifiers: .command)

            Divider()

            Button("Split Right") {
                guard let projectID = appState.activeProjectID else { return }
                appState.splitFocusedArea(direction: .horizontal, projectID: projectID)
            }
            .keyboardShortcut("d", modifiers: .command)

            Button("Split Down") {
                guard let projectID = appState.activeProjectID else { return }
                appState.splitFocusedArea(direction: .vertical, projectID: projectID)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Close Pane") {
                guard let projectID = appState.activeProjectID,
                      let areaID = appState.focusedAreaID[projectID] else { return }
                appState.closeArea(areaID, projectID: projectID)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }

        CommandGroup(after: .windowList) {
            ForEach(1...9, id: \.self) { index in
                Button("Tab \(index)") {
                    guard let projectID = appState.activeProjectID else { return }
                    appState.selectTabByIndex(index - 1, projectID: projectID)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
            }
        }

        CommandGroup(after: .toolbar) {
            Button("Next Pane") {
                guard let projectID = appState.activeProjectID else { return }
                appState.focusNextArea(projectID: projectID)
            }
            .keyboardShortcut("]", modifiers: .command)

            Button("Previous Pane") {
                guard let projectID = appState.activeProjectID else { return }
                appState.focusPreviousArea(projectID: projectID)
            }
            .keyboardShortcut("[", modifiers: .command)
        }
    }
}
