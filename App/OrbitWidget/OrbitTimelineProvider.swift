import Foundation
import OrbitCore
import OrbitPresentation
import OrbitProviders
import WidgetKit

struct OrbitTimelineEntry: TimelineEntry {
    let date: Date
    let loadState: UsageLoadState
    let selected: SelectedUsagePeriod
    /// Carried on the entry so the failure state can keep the widget's
    /// identity without any view naming a specific provider.
    let provider: AgentProvider
}

extension OrbitTimelineEntry {
    /// Sample entry for previews, the placeholder, and the widget gallery.
    static func preview(
        loadState: UsageLoadState = .loaded(MockUsageProvider.snapshot()),
        selected: SelectedUsagePeriod = .session
    ) -> OrbitTimelineEntry {
        OrbitTimelineEntry(date: .now, loadState: loadState, selected: selected, provider: .claudeCode)
    }
}

struct OrbitTimelineProvider: TimelineProvider {
    /// Session windows are short (5h), so refresh eagerly enough to stay
    /// believable while staying well inside WidgetKit's refresh budget.
    private static let refreshInterval: TimeInterval = 10 * 60

    private let provider: AgentProvider
    private let repository: CachingUsageRepository
    private let selectionStore: SelectedPeriodStore

    init(
        provider: AgentProvider = .claudeCode,
        repository: CachingUsageRepository = CachingUsageRepository(wrapping: ClaudeCodeProvider()),
        selectionStore: SelectedPeriodStore = .shared
    ) {
        self.provider = provider
        self.repository = repository
        self.selectionStore = selectionStore
    }

    func placeholder(in context: Context) -> OrbitTimelineEntry {
        .preview()
    }

    func getSnapshot(in context: Context, completion: @escaping (OrbitTimelineEntry) -> Void) {
        guard !context.isPreview else {
            return completion(.preview())
        }
        Task { completion(await currentEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OrbitTimelineEntry>) -> Void) {
        Task {
            let entry = await currentEntry()
            let nextRefresh = Date.now.addingTimeInterval(Self.refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func currentEntry() async -> OrbitTimelineEntry {
        let loadState = await repository.loadState()
        return OrbitTimelineEntry(
            date: .now,
            loadState: loadState,
            selected: selectionStore.load(),
            provider: provider
        )
    }
}
