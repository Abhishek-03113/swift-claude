import Foundation

/// Runs a refresh roughly every ten minutes while the app is running.
///
/// `NSBackgroundActivityScheduler` rather than a `Timer`: it is the macOS
/// mechanism for periodic maintenance work, so the system can slide the
/// firing time to coalesce with other activity and hold it off on battery or
/// under load. Usage that is a few minutes stale is fine; waking the machine
/// on a strict ten-minute drumbeat is not.
///
/// This deliberately stops when the app does. Refreshing with the app closed
/// would need a LaunchAgent and a separate helper executable.
@MainActor
final class PeriodicRefreshScheduler {
    static let interval: TimeInterval = 10 * 60

    private let scheduler: NSBackgroundActivityScheduler
    private var isRunning = false

    init(identifier: String = "com.orbit.app.periodic-refresh") {
        scheduler = NSBackgroundActivityScheduler(identifier: identifier)
        scheduler.repeats = true
        scheduler.interval = Self.interval
        // Half the interval of slack is plenty for a number that changes
        // slowly, and it lets the system batch this with other wake-ups.
        scheduler.tolerance = Self.interval / 2
        scheduler.qualityOfService = .utility
    }

    func start(_ refresh: @escaping @Sendable () async -> Void) {
        guard !isRunning else { return }
        isRunning = true

        scheduler.schedule { completion in
            Task {
                await refresh()
                completion(.finished)
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        scheduler.invalidate()
    }

    deinit {
        scheduler.invalidate()
    }
}
