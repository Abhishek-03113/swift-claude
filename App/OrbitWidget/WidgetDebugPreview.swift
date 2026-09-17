import SwiftUI
import WidgetKit

/// Renders `OrbitWidgetView` as a plain SwiftUI view rather than through
/// `#Preview(as: .systemSmall) { OrbitWidget() }`. The latter asks Xcode's
/// preview agent to launch the widget extension as its own process, which
/// this Xcode toolchain doesn't yet support ("No plugin is registered to
/// launch the process type widgetExtension"). A plain `#Preview` renders
/// in-process instead, sidestepping that.
private struct WidgetDebugPreview: View {
    let family: WidgetFamily
    let entry: OrbitTimelineEntry

    var body: some View {
        OrbitWidgetView(entry: entry)
            .environment(\.widgetFamily, family)
            .frame(width: family.debugPreviewSize.width, height: family.debugPreviewSize.height)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private extension WidgetFamily {
    var debugPreviewSize: CGSize {
        switch self {
        case .systemMedium: CGSize(width: 364, height: 170)
        case .systemLarge: CGSize(width: 364, height: 382)
        default: CGSize(width: 170, height: 170)
        }
    }
}

#Preview("Small — Session") {
    WidgetDebugPreview(family: .systemSmall, entry: .preview(selected: .session))
}

#Preview("Small — Weekly") {
    WidgetDebugPreview(family: .systemSmall, entry: .preview(selected: .weekly))
}

#Preview("Small — Loading") {
    WidgetDebugPreview(family: .systemSmall, entry: .preview(loadState: .loading))
}

#Preview("Small — Failed") {
    WidgetDebugPreview(family: .systemSmall, entry: .preview(loadState: .failed(.unavailable)))
}

#Preview("Medium — Session") {
    WidgetDebugPreview(family: .systemMedium, entry: .preview(selected: .session))
}

#Preview("Large — Weekly") {
    WidgetDebugPreview(family: .systemLarge, entry: .preview(selected: .weekly))
}
