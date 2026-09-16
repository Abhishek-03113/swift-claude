import XCTest

private struct FailingRepository: UsageRepository {
    func snapshot() async throws -> UsageSnapshot {
        throw UsageRepositoryError.unavailable
    }
}

private struct SucceedingRepository: UsageRepository {
    let snapshotToReturn: UsageSnapshot
    func snapshot() async throws -> UsageSnapshot { snapshotToReturn }
}

final class CachingUsageRepositoryTests: XCTestCase {
    private func freshCache() -> UsageSnapshotCache {
        // A unique suite per test avoids cross-test pollution through the
        // shared App Group defaults.
        UsageSnapshotCache(suiteName: "orbit.tests.\(UUID().uuidString)")
    }

    func testFailedFetchWithNoCacheReturnsFailedState() async {
        let repo = CachingUsageRepository(wrapping: FailingRepository(), cache: freshCache())
        let state = await repo.loadState()
        guard case .failed = state else {
            return XCTFail("expected .failed, got \(state)")
        }
    }

    func testSuccessfulFetchIsCachedAndReturnedAsLoaded() async throws {
        let snapshot = MockUsageProvider.snapshot()
        let repo = CachingUsageRepository(wrapping: SucceedingRepository(snapshotToReturn: snapshot), cache: freshCache())
        let state = await repo.loadState()
        guard case .loaded(let loaded) = state else {
            return XCTFail("expected .loaded, got \(state)")
        }
        XCTAssertEqual(loaded, snapshot)
    }

    func testFailedFetchFallsBackToCachedSnapshotAsStale() async {
        let cache = freshCache()
        let snapshot = MockUsageProvider.snapshot()
        cache.save(snapshot)

        let repo = CachingUsageRepository(wrapping: FailingRepository(), cache: cache)
        let state = await repo.loadState()
        guard case .stale(let stale) = state else {
            return XCTFail("expected .stale, got \(state)")
        }
        XCTAssertEqual(stale, snapshot)
    }
}
