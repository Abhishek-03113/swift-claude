import Foundation
import Observation
import OrbitCore
import OrbitPresentation
import SwiftUI
import WidgetKit

/// Holds the app's usage state: one load state per connected agent, the
/// focused period, and whether a refresh is in flight.
///
/// The app is the only place that can actually fetch — a widget extension is
/// sandboxed and cannot run a provider's CLI — so this is also what keeps the
/// widget's cache current, on three triggers: launch, the ten-minute
/// scheduler, and a tap on the widget relayed through `RefreshSignal`.
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
    private let scheduler: PeriodicRefreshScheduler
    private var refreshObserver: NSObjectProtocol?

    init(
        agents: [AgentSlot] = AgentCatalog.live(),
        selectionStore: SelectedPeriodStore = .shared,
        scheduler: PeriodicRefreshScheduler = PeriodicRefreshScheduler()
    ) {
        self.agents = agents
        self.selectionStore = selectionStore
        self.scheduler = scheduler
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

    /// Called once when the window appears: fetch now, then keep fetching on
    /// the scheduler and whenever the widget asks.
    func start() async {
        if refreshObserver == nil {
            refreshObserver = RefreshSignal.observe { [weak self] in
                Task { @MainActor in await self?.refreshAll() }
            }
        }

        scheduler.start { [weak self] in
            await self?.refreshAll()
        }

        await refreshAll()
    }

    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        for agent in agents {
            guard let repository = agent.repository else { continue }
            states[agent.id] = await load(from: repository)
        }

        lastRefreshed = .now
        refreshToken += 1
        // The cache the app just wrote is what the widget reads.
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func load(from repository: UsageRepository) async -> UsageLoadState {
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
