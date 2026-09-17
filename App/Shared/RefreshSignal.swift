import Foundation

/// Cross-process nudge from the widget to the app: "please re-read usage".
///
/// The widget cannot fetch. Reading Claude Code's usage means running its CLI,
/// and a widget extension is sandboxed. So a tap posts this signal, and the
/// app — which is not sandboxed and can run the CLI — does the work and
/// reloads the widget's timeline afterwards.
///
/// `DistributedNotificationCenter` is the lightest thing that crosses the
/// process boundary without an XPC service. It is fire-and-forget by design:
/// if the app is not running there is no observer, the signal is dropped, and
/// the widget simply keeps showing its last reading. That is the accepted
/// trade — the alternative is launching the app on every tap.
enum RefreshSignal {
    static let name = Notification.Name("com.orbit.app.refresh-usage")

    /// Posted by the widget. `deliverImmediately` bypasses the coalescing
    /// that would otherwise delay a user-initiated tap.
    static func post() {
        DistributedNotificationCenter.default().postNotificationName(
            name,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    /// Observed by the app. The returned token must be retained; dropping it
    /// removes the observer.
    static func observe(_ handler: @escaping @Sendable () -> Void) -> NSObjectProtocol {
        DistributedNotificationCenter.default().addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { _ in handler() }
    }
}
