import OrbitCore
import OrbitPresentation
import SwiftUI
import WidgetKit

struct OrbitWidget: Widget {
    var body: some WidgetConfiguration {
        // AppIntentConfiguration rather than StaticConfiguration: WidgetKit
        // persists one SelectUsagePeriodIntent per placed widget instance, so
        // three Orbit widgets on the desktop can each show a different
        // focused period instead of all reading one shared value.
        AppIntentConfiguration(
            kind: OrbitWidgetKind.identifier,
            intent: SelectUsagePeriodIntent.self,
            provider: OrbitTimelineProvider()
        ) { entry in
            OrbitWidgetView(entry: entry)
        }
        .configurationDisplayName("Orbit")
        .description("AI agent usage, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry.preview(selected: .session)
    OrbitTimelineEntry.preview(selected: .weekly)
    OrbitTimelineEntry.preview(loadState: .loading)
    OrbitTimelineEntry.preview(loadState: .failed(.unavailable))
}

#Preview(as: .systemMedium) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry.preview(selected: .session)
    OrbitTimelineEntry.preview(selected: .weekly)
    OrbitTimelineEntry.preview(loadState: .failed(.unavailable))
}

#Preview(as: .systemLarge) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry.preview(selected: .session)
    OrbitTimelineEntry.preview(selected: .weekly)
}
