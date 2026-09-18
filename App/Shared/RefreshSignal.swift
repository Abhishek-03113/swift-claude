import Foundation

/// Cross-process nudges between the widget, the app, and `OrbitAgent`, the
/// background login item that owns fetching.
///
/// `DistributedNotificationCenter` is the lightest thing that crosses the
/// process boundary without an XPC service.
enum RefreshSignal {
    private static let requestName = Notification.Name("com.orbit.app.refresh-usage")
    private static let completedName = Notification.Name("com.orbit.app.usage-refreshed")

    /// "Please re-read usage." Posted by a tap on the widget's unavailable
    /// state; observed by `OrbitAgent`, which is always running and does the
    /// actual fetch. `deliverImmediately` bypasses the coalescing that would
    /// otherwise delay a user-initiated tap.
    static func postRefreshRequested() {
        DistributedNotificationCenter.default().postNotificationName(
            requestName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    static func observeRefreshRequested(_ handler: @escaping @Sendable () -> Void) -> NSObjectProtocol {
        DistributedNotificationCenter.default().addObserver(
            forName: requestName,
            object: nil,
            queue: .main
        ) { _ in handler() }
    }

    /// "Usage just changed in the App Group cache." Posted by `OrbitAgent`
    /// after every refresh, whether scheduled or requested; observed by the
    /// app so its window reflects a fetch it did not itself perform, without
    /// re-fetching.
    static func postRefreshCompleted() {
        DistributedNotificationCenter.default().postNotificationName(
            completedName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    static func observeRefreshCompleted(_ handler: @escaping @Sendable () -> Void) -> NSObjectProtocol {
        DistributedNotificationCenter.default().addObserver(
            forName: completedName,
            object: nil,
            queue: .main
        ) { _ in handler() }
    }
}
