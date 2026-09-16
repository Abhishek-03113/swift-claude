import Foundation

/// Stores the last known-good snapshot in the App Group container so a failed
/// refresh has something to fall back on. Kept separate from
/// `CachingUsageRepository` so it can be exercised without an async
/// repository in the loop.
public struct UsageSnapshotCache: Sendable {
    public static let shared = UsageSnapshotCache()

    private static let key = "orbit.usage.snapshot.cache"

    private let store: AppGroupStore

    public init(store: AppGroupStore = .shared) {
        self.store = store
    }

    public init(suiteName: String) {
        self.init(store: AppGroupStore(suiteName: suiteName))
    }

    public func load() -> UsageSnapshot? {
        store.read(UsageSnapshot.self, forKey: Self.key)
    }

    public func save(_ snapshot: UsageSnapshot) {
        store.write(snapshot, forKey: Self.key)
    }
}
