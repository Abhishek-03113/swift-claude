import AppIntents

/// Asks `OrbitAgent` — the always-running background login item — to re-read
/// usage, for the widget states that have no dial to tap, the unavailable
/// view in particular.
///
/// Like every widget interaction, this cannot fetch anything itself; it posts
/// the signal and lets the daemon do the work. The daemon reloads the
/// widget's timeline itself once the new reading is cached, so this does not
/// have to: reloading now would just repaint the same stale entry.
struct RefreshUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Usage"
    static var description = IntentDescription("Asks Orbit to re-read each connected agent's usage.")

    func perform() async throws -> some IntentResult {
        RefreshSignal.postRefreshRequested()
        return .result()
    }
}
