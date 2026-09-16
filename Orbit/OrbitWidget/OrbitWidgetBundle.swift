import WidgetKit
import SwiftUI

@main
struct OrbitWidgetBundle: WidgetBundle {
    var body: some Widget {
        OrbitWidget()
    }
}

struct OrbitWidget: Widget {
    let kind: String = OrbitWidgetKind.identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrbitTimelineProvider()) { entry in
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
    OrbitTimelineEntry(date: .now, loadState: .loaded(MockUsageProvider.snapshot()), selected: .session)
    OrbitTimelineEntry(date: .now, loadState: .loaded(MockUsageProvider.snapshot()), selected: .weekly)
}

#Preview(as: .systemMedium) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry(date: .now, loadState: .loaded(MockUsageProvider.snapshot()), selected: .session)
}

#Preview(as: .systemLarge) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry(date: .now, loadState: .loaded(MockUsageProvider.snapshot()), selected: .weekly)
}
