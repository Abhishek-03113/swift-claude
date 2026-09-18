import Foundation

/// `OrbitAgent`: the background login item that owns fetching.
///
/// It has no window and no dock icon (`LSUIElement`/`LSBackgroundOnly` in its
/// Info.plist) — just this run loop. It exists so a tap on the widget, and
/// the periodic refresh that used to belong to the app, both work without the
/// main app running at all. Fetching usage is now a Keychain read plus one
/// network call (`ClaudeCodeAPIUsageClient`, with the CLI-subprocess parser
/// only as a fallback), so there is nothing here that needs the app's own
/// process — the daemon reads the same OAuth token straight from Keychain and
/// writes the same App Group cache the app and widget already share.
///
/// Registered and kept up to date by `DaemonRegistration`, which the main app
/// calls into on launch — installing or updating Orbit.app is what installs
/// or updates this LaunchAgent, with no separate installer step.
@main
struct OrbitAgentMain {
    @MainActor
    static func main() async {
        let scheduler = PeriodicRefreshScheduler(identifier: "com.orbit.agent.periodic-refresh")

        let requestObserver = RefreshSignal.observeRefreshRequested {
            Task { await refreshAndAnnounce() }
        }
        // Retained for the process's lifetime; there is nothing to tear this
        // down for since the daemon only exits when the system stops it.
        withExtendedLifetime(requestObserver) {}

        scheduler.start {
            await refreshAndAnnounce()
        }

        await refreshAndAnnounce()

        RunLoop.main.run()
    }

    private static func refreshAndAnnounce() async {
        await UsageRefreshCoordinator.refreshAll()
        RefreshSignal.postRefreshCompleted()
    }
}
