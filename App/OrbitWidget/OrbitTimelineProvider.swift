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

/// Builds entries from whatever the app last cached.
///
/// The widget deliberately does not fetch. Reading Claude Code's usage means
/// running its CLI, and a widget extension is sandboxed and has no business
/// spawning processes — so the app refreshes and writes to the App Group, and
/// this reads it back.
///
/// Conforms to `AppIntentTimelineProvider` rather than plain
/// `TimelineProvider`: WidgetKit hands each placed widget instance its own
/// persisted `SelectUsagePeriodIntent` here, which is what lets three
/// instances of this widget each show a different focused period instead of
/// all reading one shared value.
struct OrbitTimelineProvider: AppIntentTimelineProvider {
    /// Session windows are short (5h), so re-read often enough to stay
    /// believable while staying well inside WidgetKit's refresh budget.
    private static let refreshInterval: TimeInterval = 10 * 60

    /// Past this, the cached reading is labelled stale rather than presented
    /// as current — the app has not refreshed in a while.
    private static let stalenessThreshold: TimeInterval = 20 * 60

    private let provider: AgentProvider
    private let repository: UsageRepository

    init(
        provider: AgentProvider = .claudeCode,
        repository: UsageRepository = CachedSnapshotRepository()
    ) {
        self.provider = provider
        self.repository = repository
    }

    func placeholder(in context: Context) -> OrbitTimelineEntry {
        .preview()
    }

    func snapshot(for configuration: SelectUsagePeriodIntent, in context: Context) async -> OrbitTimelineEntry {
        guard !context.isPreview else {
            return .preview()
        }
        return await currentEntry(selected: configuration.period.selection)
    }

    func timeline(for configuration: SelectUsagePeriodIntent, in context: Context) async -> Timeline<OrbitTimelineEntry> {
        let entry = await currentEntry(selected: configuration.period.selection)
        let nextRefresh = Date.now.addingTimeInterval(Self.refreshInterval)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func currentEntry(selected: SelectedUsagePeriod) async -> OrbitTimelineEntry {
        OrbitTimelineEntry(
            date: .now,
            loadState: await loadState(),
            selected: selected,
            provider: provider
        )
    }

    private func loadState() async -> UsageLoadState {
        do {
            let snapshot = try await repository.snapshot()
            let age = Date.now.timeIntervalSince(snapshot.lastUpdated)
            return age > Self.stalenessThreshold ? .stale(snapshot) : .loaded(snapshot)
        } catch {
            return .failed(error as? UsageRepositoryError ?? .unavailable)
        }
    }
}
