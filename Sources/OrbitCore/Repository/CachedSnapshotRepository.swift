import Foundation

/// Serves whatever the app last cached in the App Group, without fetching.
///
/// This is what the widget uses. Widget extensions are sandboxed and cannot
/// run a provider's CLI, so the split is: the app refreshes and writes, the
/// widget reads. An empty cache means the app has not successfully refreshed
/// yet, which surfaces as the unavailable state rather than a blank dial.
public struct CachedSnapshotRepository: UsageRepository {
    private let cache: UsageSnapshotCache

    public init(cache: UsageSnapshotCache = .shared) {
        self.cache = cache
    }

    public func snapshot() async throws -> UsageSnapshot {
        guard let cached = cache.load() else {
            throw UsageRepositoryError.unavailable
        }
        return cached
    }
}
