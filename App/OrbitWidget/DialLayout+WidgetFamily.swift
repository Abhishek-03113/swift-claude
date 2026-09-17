import WidgetKit

extension DialLayout {
    /// Maps a widget family onto the shared presets. Lives in the widget
    /// target so `DialLayout` itself stays WidgetKit-free and usable by the app.
    static func layout(for family: WidgetFamily) -> DialLayout {
        switch family {
        case .systemSmall: return .compact
        case .systemLarge, .systemExtraLarge: return .expanded
        // Medium is wide, not tall: the dial sits beside its details, so the
        // core carries less and the dial fills the short axis.
        case .systemMedium: return .split
        default: return .standard
        }
    }
}
