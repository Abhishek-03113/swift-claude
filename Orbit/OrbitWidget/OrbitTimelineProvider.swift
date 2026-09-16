import WidgetKit
import Foundation

struct OrbitTimelineEntry: TimelineEntry {
    let date: Date
    let loadState: UsageLoadState
    let selected: SelectedUsagePeriod
}

struct OrbitTimelineProvider: TimelineProvider {
    let repository: CachingUsageRepository

    init(repository: CachingUsageRepository = CachingUsageRepository(wrapping: ClaudeCodeProvider())) {
        self.repository = repository
    }

    func placeholder(in context: Context) -> OrbitTimelineEntry {
        OrbitTimelineEntry(date: .now, loadState: .loaded(MockUsageProvider.snapshot()), selected: .session)
    }

    func getSnapshot(in context: Context, completion: @escaping (OrbitTimelineEntry) -> Void) {
        if context.isPreview {
            completion(OrbitTimelineEntry(date: .now, loadState: .loaded(MockUsageProvider.snapshot()), selected: .session))
            return
        }
        Task {
            let state = await repository.loadState()
            completion(OrbitTimelineEntry(date: .now, loadState: state, selected: SelectedPeriodStore.shared.get()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OrbitTimelineEntry>) -> Void) {
        Task {
            let state = await repository.loadState()
            let selected = SelectedPeriodStore.shared.get()
            let entry = OrbitTimelineEntry(date: .now, loadState: state, selected: selected)

            // Session windows are short (5h) — refresh more eagerly than the
            // weekly window needs, but stay within a sane widget refresh
            // budget rather than polling minute-by-minute.
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 10, to: .now) ?? .now.addingTimeInterval(600)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
}
