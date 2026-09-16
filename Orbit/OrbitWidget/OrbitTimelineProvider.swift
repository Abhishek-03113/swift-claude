import WidgetKit

struct OrbitTimelineEntry: TimelineEntry {
    let date: Date
    let data: OrbitSnapshotData
}

struct OrbitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OrbitTimelineEntry {
        OrbitTimelineEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OrbitTimelineEntry) -> Void) {
        completion(OrbitTimelineEntry(date: .now, data: OrbitSharedStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OrbitTimelineEntry>) -> Void) {
        let entry = OrbitTimelineEntry(date: .now, data: OrbitSharedStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
