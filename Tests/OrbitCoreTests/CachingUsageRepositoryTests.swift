import XCTest
@testable import OrbitCore

private struct FailingRepository: UsageRepository {
    let error: UsageRepositoryError
    func snapshot() async throws -> UsageSnapshot { throw error }
}

private struct SucceedingRepository: UsageRepository {
    let result: UsageSnapshot
    func snapshot() async throws -> UsageSnapshot { result }
}

final class CachingUsageRepositoryTests: XCTestCase {
    /// A unique suite per test keeps them from leaking into each other, or
    /// into the real widget's App Group state on a developer's machine.
    private func freshCache() -> UsageSnapshotCache {
        UsageSnapshotCache(suiteName: "orbit.tests.\(UUID().uuidString)")
    }

    func testFailedFetchWithNoCacheReturnsFailedState() async {
        let repository = CachingUsageRepository(
            wrapping: FailingRepository(error: .notAuthenticated),
            cache: freshCache()
        )
        guard case .failed(let error) = await repository.loadState() else {
            return XCTFail("expected .failed")
        }
        XCTAssertEqual(error, .notAuthenticated)
    }

    func testSuccessfulFetchIsCachedAndReturnedAsLoaded() async {
        let cache = freshCache()
        let snapshot = UsageFixtures.snapshot()
        let repository = CachingUsageRepository(wrapping: SucceedingRepository(result: snapshot), cache: cache)

        guard case .loaded(let loaded) = await repository.loadState() else {
            return XCTFail("expected .loaded")
        }
        XCTAssertEqual(loaded, snapshot)
        XCTAssertEqual(cache.load(), snapshot)
    }

    func testFailedFetchFallsBackToCachedSnapshotAsStale() async {
        let cache = freshCache()
        let snapshot = UsageFixtures.snapshot()
        cache.save(snapshot)

        let repository = CachingUsageRepository(
            wrapping: FailingRepository(error: .unavailable),
            cache: cache
        )
        guard case .stale(let stale) = await repository.loadState() else {
            return XCTFail("expected .stale")
        }
        XCTAssertEqual(stale, snapshot)
    }

    func testSnapshotRethrowsTheUnderlyingErrorWhenNothingIsCached() async {
        let repository = CachingUsageRepository(
            wrapping: FailingRepository(error: .malformedResponse("bad")),
            cache: freshCache()
        )
        do {
            _ = try await repository.snapshot()
            XCTFail("expected snapshot() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .malformedResponse("bad"))
        }
    }

    func testSnapshotReturnsCachedValueWhenTheFetchFails() async throws {
        let cache = freshCache()
        let snapshot = UsageFixtures.snapshot()
        cache.save(snapshot)

        let repository = CachingUsageRepository(
            wrapping: FailingRepository(error: .unavailable),
            cache: cache
        )
        let result = try await repository.snapshot()
        XCTAssertEqual(result, snapshot)
    }
}
