import Foundation

@MainActor
@Observable
final class ProjectStore {
    private(set) var projects: [Project] = []
    private let persistence: any ProjectPersisting

    init(persistence: any ProjectPersisting) {
        self.persistence = persistence
        load()
    }

    func add(_ project: Project) {
        projects.append(project)
        save()
    }

    func remove(id: UUID) {
        projects.removeAll { $0.id == id }
        save()
    }

    func reorder(fromOffsets source: IndexSet, toOffset destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        for (index, project) in projects.enumerated() {
            project.sortOrder = index
        }
        save()
    }

    func save() {
        do {
            try persistence.saveProjects(projects)
        } catch {
            print("Failed to save projects: \(error)")
        }
    }

    private func load() {
        do {
            projects = try persistence.loadProjects()
            projects.sort { $0.sortOrder < $1.sortOrder }
        } catch {
            print("Failed to load projects: \(error)")
        }
    }
}
