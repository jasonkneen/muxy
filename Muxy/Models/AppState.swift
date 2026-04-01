import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var activeProjectID: UUID? {
        didSet { saveSelection() }
    }
    var workspaceRoots: [UUID: SplitNode] = [:]
    var focusedAreaID: [UUID: UUID] = [:]
    private var focusHistory: [UUID: [UUID]] = [:]

    private static let activeProjectKey = "muxy.activeProjectID"

    func restoreSelection(projects: [Project]) {
        guard let idString = UserDefaults.standard.string(forKey: Self.activeProjectKey),
              let id = UUID(uuidString: idString),
              let project = projects.first(where: { $0.id == id }) else { return }
        activeProjectID = project.id
        ensureWorkspaceExists(for: project)
    }

    private func saveSelection() {
        UserDefaults.standard.set(activeProjectID?.uuidString, forKey: Self.activeProjectKey)
    }

    func workspaceRoot(for projectID: UUID) -> SplitNode? {
        workspaceRoots[projectID]
    }

    func focusedArea(for projectID: UUID) -> TabArea? {
        guard let root = workspaceRoots[projectID],
              let areaID = focusedAreaID[projectID] else { return nil }
        return root.findArea(id: areaID)
    }

    func allAreas(for projectID: UUID) -> [TabArea] {
        workspaceRoots[projectID]?.allAreas() ?? []
    }

    func splitArea(_ areaID: UUID, direction: SplitDirection, projectID: UUID, projectPath: String) {
        guard let root = workspaceRoots[projectID] else { return }
        let (newRoot, newAreaID) = root.splitting(areaID: areaID, direction: direction, projectPath: projectPath)
        workspaceRoots[projectID] = newRoot
        if let newAreaID {
            if let current = focusedAreaID[projectID] {
                focusHistory[projectID, default: []].append(current)
            }
            focusedAreaID[projectID] = newAreaID
        }
    }

    func closeArea(_ areaID: UUID, projectID: UUID) {
        guard let root = workspaceRoots[projectID] else { return }
        guard let newRoot = root.removing(areaID: areaID) else {
            workspaceRoots.removeValue(forKey: projectID)
            focusedAreaID.removeValue(forKey: projectID)
            focusHistory.removeValue(forKey: projectID)
            activeProjectID = nil
            return
        }
        workspaceRoots[projectID] = newRoot
        focusHistory[projectID]?.removeAll { $0 == areaID }
        if focusedAreaID[projectID] == areaID {
            let remaining = newRoot.allAreas()
            let previousID = popFocusHistory(projectID: projectID, validAreas: remaining)
            focusedAreaID[projectID] = previousID ?? remaining.first?.id
        }
    }

    private func popFocusHistory(projectID: UUID, validAreas: [TabArea]) -> UUID? {
        let validIDs = Set(validAreas.map(\.id))
        while let last = focusHistory[projectID]?.popLast() {
            if validIDs.contains(last) {
                return last
            }
        }
        return nil
    }

    func createTab(projectID: UUID) {
        guard let area = focusedArea(for: projectID) else { return }
        area.createTab()
    }

    func closeTab(_ tabID: UUID, projectID: UUID) {
        guard let area = focusedArea(for: projectID) else { return }
        closeTabInArea(tabID, areaID: area.id, projectID: projectID)
    }

    func closeTabInArea(_ tabID: UUID, areaID: UUID, projectID: UUID) {
        guard let root = workspaceRoots[projectID],
              let area = root.findArea(id: areaID) else { return }
        let areaCount = allAreas(for: projectID).count
        if area.tabs.count <= 1 && areaCount > 1 {
            closeArea(areaID, projectID: projectID)
            return
        }
        area.closeTab(tabID)
        if area.tabs.isEmpty {
            workspaceRoots.removeValue(forKey: projectID)
            focusedAreaID.removeValue(forKey: projectID)
            focusHistory.removeValue(forKey: projectID)
            activeProjectID = nil
        }
    }

    func selectTab(_ tabID: UUID, projectID: UUID) {
        guard let area = focusedArea(for: projectID) else { return }
        area.selectTab(tabID)
    }

    func selectTabByIndex(_ index: Int, projectID: UUID) {
        guard let area = focusedArea(for: projectID) else { return }
        area.selectTabByIndex(index)
    }

    func focusArea(_ areaID: UUID, projectID: UUID) {
        if let current = focusedAreaID[projectID], current != areaID {
            focusHistory[projectID, default: []].append(current)
        }
        focusedAreaID[projectID] = areaID
    }

    func focusNextArea(projectID: UUID) {
        cycleFocus(projectID: projectID, forward: true)
    }

    func focusPreviousArea(projectID: UUID) {
        cycleFocus(projectID: projectID, forward: false)
    }

    private func cycleFocus(projectID: UUID, forward: Bool) {
        let areas = allAreas(for: projectID)
        guard areas.count > 1, let currentID = focusedAreaID[projectID],
              let index = areas.firstIndex(where: { $0.id == currentID }) else { return }
        let next = forward ? (index + 1) % areas.count : (index - 1 + areas.count) % areas.count
        focusedAreaID[projectID] = areas[next].id
    }

    func ensureWorkspaceExists(for project: Project) {
        guard workspaceRoots[project.id] == nil else { return }
        let area = TabArea(projectPath: project.path)
        workspaceRoots[project.id] = .tabArea(area)
        focusedAreaID[project.id] = area.id
    }

    func removeProject(_ projectID: UUID) {
        workspaceRoots.removeValue(forKey: projectID)
        focusedAreaID.removeValue(forKey: projectID)
        focusHistory.removeValue(forKey: projectID)
        if activeProjectID == projectID {
            activeProjectID = nil
        }
    }
}
