import AppIntents
import WidgetKit

/// Asks the app to re-read usage, for the widget states that have no dial to
/// tap — the unavailable view in particular.
///
/// Like every widget interaction, this cannot fetch anything itself; it posts
/// the signal and lets the app do the work.
struct RefreshUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Usage"
    static var description = IntentDescription("Asks Orbit to re-read each connected agent's usage.")

    func perform() async throws -> some IntentResult {
        RefreshSignal.post()
        WidgetCenter.shared.reloadTimelines(ofKind: OrbitWidgetKind.identifier)
        return .result()
    }
}
