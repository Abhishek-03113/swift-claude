import Foundation

/// Wraps any `UsageRepository` with an App-Group-backed cache, so a refresh
/// that fails (no data source, malformed file) still has a last known-good
/// snapshot to show instead of going blank.
public actor CachingUsageRepository: UsageRepository {
    private let wrapped: UsageRepository
    private let cache: UsageSnapshotCache

    public init(wrapping repository: UsageRepository, cache: UsageSnapshotCache = .shared) {
        self.wrapped = repository
        self.cache = cache
    }

    /// Fetches, caches on success, and falls back to the cached snapshot on
    /// failure. `.loading` is never produced here — it is the state before a
    /// load has been attempted at all.
    public func loadState() async -> UsageLoadState {
        do {
            let fresh = try await wrapped.snapshot()
            cache.save(fresh)
            return .loaded(fresh)
        } catch {
            if let cached = cache.load() {
                return .stale(cached)
            }
            return .failed(error as? UsageRepositoryError ?? .unavailable)
        }
    }

    /// `UsageRepository` conformance, expressed in terms of `loadState()` so
    /// the fetch-and-fall-back policy exists in exactly one place.
    public func snapshot() async throws -> UsageSnapshot {
        switch await loadState() {
        case .loaded(let snapshot), .stale(let snapshot):
            return snapshot
        case .failed(let error):
            throw error
        case .loading:
            throw UsageRepositoryError.unavailable
        }
    }
}
