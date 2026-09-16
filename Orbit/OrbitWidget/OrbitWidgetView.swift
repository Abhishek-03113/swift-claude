import SwiftUI
import WidgetKit

struct OrbitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OrbitTimelineEntry

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(alignment: .top) {
                content
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        default:
            content
                .padding()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.data.title)
                .font(.headline)
            Text(entry.data.value)
                .font(.title2.bold())
        }
    }
}

struct OrbitWidget: Widget {
    let kind: String = "OrbitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrbitTimelineProvider()) { entry in
            OrbitWidgetView(entry: entry)
        }
        .configurationDisplayName("Orbit")
        .description("Shows your Orbit data at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    OrbitWidget()
} timeline: {
    OrbitTimelineEntry(date: .now, data: .placeholder)
}
