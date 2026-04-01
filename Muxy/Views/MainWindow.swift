import SwiftUI

struct MainWindow: View {
    @Environment(AppState.self) private var appState
    @Environment(ProjectStore.self) private var projectStore

    var body: some View {
        HStack(spacing: 0) {
            Sidebar()
            Rectangle().fill(MuxyTheme.border).frame(width: 1)

            ZStack {
                MuxyTheme.bg
                ForEach(projectStore.projects) { project in
                    let isActive = project.id == appState.activeProjectID
                    TerminalArea(project: project, isActiveProject: isActive)
                        .opacity(isActive ? 1 : 0)
                        .allowsHitTesting(isActive)
                }
                if activeProject == nil {
                    WelcomeView()
                }
            }
        }
        .background(MuxyTheme.bg)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            appState.restoreSelection(projects: projectStore.projects)
        }
    }

    private var activeProject: Project? {
        guard let pid = appState.activeProjectID else { return nil }
        return projectStore.projects.first { $0.id == pid }
    }
}
