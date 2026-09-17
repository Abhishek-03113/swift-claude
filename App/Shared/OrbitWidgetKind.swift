/// The widget's kind string.
///
/// Lives in the shared layer because both sides need it: the widget declares
/// itself with it, and the app and the selection intent use it to ask
/// WidgetKit for a reload.
enum OrbitWidgetKind {
    static let identifier = "OrbitWidget"
}
