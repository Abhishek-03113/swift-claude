import OrbitCore
import WidgetKit

/// Fetches every connected agent's usage, relying on each repository's own
/// caching to populate the App Group, then reloads the widget's timelines.
///
/// This is the one place that does that whole sequence. `AgentUsageStore`
/// calls it for an immediate foreground refresh with visible per-agent state;
/// `OrbitAgent` — the background daemon — calls it on the same schedule and
/// on every widget tap, with no UI to update. Neither reimplements the other.
enum UsageRefreshCoordinator {
    /// Refreshes every agent that has a repository and returns the resulting
    /// state per agent id, in `agents` order. Never throws: a repository
    /// failure becomes a `.failed` entry, since one agent's outage should
    /// never stop the rest from refreshing.
    @discardableResult
    static func refreshAll(agents: [AgentSlot] = AgentCatalog.live()) async -> [String: UsageLoadState] {
        var states: [String: UsageLoadState] = [:]

        for agent in agents {
            guard let repository = agent.repository else { continue }
            states[agent.id] = await load(from: repository)
        }

        WidgetCenter.shared.reloadAllTimelines()
        return states
    }

    private static func load(from repository: UsageRepository) async -> UsageLoadState {
        // A caching repository already expresses the fetch-then-fall-back
        // policy; anything else gets the same treatment applied here.
        if let caching = repository as? CachingUsageRepository {
            return await caching.loadState()
        }

        do {
            return .loaded(try await repository.snapshot())
        } catch {
            return .failed(error as? UsageRepositoryError ?? .unavailable)
        }
    }
}
