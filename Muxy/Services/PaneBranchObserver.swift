import Foundation

@MainActor
@Observable
final class PaneBranchObserver {
    typealias BranchResolver = @Sendable (String) async -> String?

    private(set) var branch: String?

    @ObservationIgnored private var repoPath: String?
    @ObservationIgnored nonisolated(unsafe) private var refreshTask: Task<Void, Never>?
    @ObservationIgnored nonisolated(unsafe) private var timer: Timer?
    @ObservationIgnored private let resolver: BranchResolver
    @ObservationIgnored private let refreshInterval: TimeInterval

    init(
        refreshInterval: TimeInterval = 5,
        resolver: @escaping BranchResolver = PaneBranchObserver.defaultResolver
    ) {
        self.refreshInterval = refreshInterval
        self.resolver = resolver
    }

    deinit {
        timer?.invalidate()
        refreshTask?.cancel()
    }

    func update(repoPath path: String?) {
        guard repoPath != path else { return }
        repoPath = path
        guard path != nil else {
            branch = nil
            return
        }
        refresh()
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.refresh() }
        }
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() {
        guard let path = repoPath else { return }
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self, resolver] in
            let resolved = await resolver(path)
            guard !Task.isCancelled, let self else { return }
            if self.branch != resolved {
                self.branch = resolved
            }
        }
    }

    static let defaultResolver: BranchResolver = { path in
        let service = GitRepositoryService()
        guard let result = try? await service.currentBranch(repoPath: path) else { return nil }
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "HEAD" else { return nil }
        return trimmed
    }
}
