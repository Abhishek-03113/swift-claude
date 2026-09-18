import Foundation
import Observation
import OrbitCore
import OrbitPresentation
import SwiftUI

/// Holds the app's usage state: one load state per connected agent, the
/// focused period, and whether a refresh is in flight.
///
/// `OrbitAgent`, the background login item, is what keeps the widget's cache
/// current on a schedule and on a tap — this store's own refresh is purely
/// for the window's benefit: an immediate read on launch so the app is never
/// looking at data staler than what's already cached, and per-agent state to
/// show while that read is in flight.
@MainActor
@Observable
final class AgentUsageStore {
    private(set) var states: [String: UsageLoadState] = [:]
    private(set) var isRefreshing = false
    private(set) var lastRefreshed: Date?

    /// Bumped after every completed refresh. The dial watches it to replay
    /// its sweep, so a refresh that returns identical numbers still reads as
    /// "something just happened".
    private(set) var refreshToken = 0

    /// Shared with the widget through the App Group, so switching period in
    /// one is reflected in the other.
    var selectedPeriod: SelectedUsagePeriod {
        didSet { selectionStore.save(selectedPeriod) }
    }

    let agents: [AgentSlot]

    private let selectionStore: SelectedPeriodStore
    // Read and cleared only from deinit's nonisolated context, so it can't be
    // `@MainActor`-isolated like the rest of this class's storage.
    private nonisolated(unsafe) var refreshObserver: NSObjectProtocol?

    init(
        agents: [AgentSlot] = AgentCatalog.live(),
        selectionStore: SelectedPeriodStore = .shared
    ) {
        self.agents = agents
        self.selectionStore = selectionStore
        self.selectedPeriod = selectionStore.load()
        self.states = agents.reduce(into: [:]) { states, agent in
            states[agent.id] = agent.isConnected ? .loading : .failed(.unavailable)
        }
    }

    deinit {
        if let refreshObserver {
            DistributedNotificationCenter.default().removeObserver(refreshObserver)
        }
    }

    func state(for agent: AgentSlot) -> UsageLoadState {
        states[agent.id] ?? .loading
    }

    /// Called once when the window appears: read now, then stay live by
    /// reacting to whatever `OrbitAgent` refreshes in the background.
    func start() async {
        if refreshObserver == nil {
            refreshObserver = RefreshSignal.observeRefreshCompleted { [weak self] in
                Task { @MainActor in await self?.refreshAll() }
            }
        }

        await refreshAll()
    }

    /// Re-fetches every agent. Also what a manual refresh in the window
    /// calls, so a user-initiated tap in the app itself doesn't wait on the
    /// daemon's own schedule.
    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        states = await UsageRefreshCoordinator.refreshAll(agents: agents)

        lastRefreshed = .now
        refreshToken += 1
    }
}
