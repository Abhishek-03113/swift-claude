import OrbitCore
import OrbitPresentation
import SwiftUI
import WidgetKit

struct OrbitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: OrbitWidgetKind.identifier, provider: OrbitTimelineProvider()) { entry in
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
}

#Preview(as: .systemLarge) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry.preview(selected: .weekly)
}
