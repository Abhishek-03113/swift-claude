import XCTest
import OrbitCore
@testable import OrbitProviders

/// The mock backs previews and the widget's loading placeholder, so the
/// fractions it is asked for have to be the fractions it produces.
final class MockUsageProviderTests: XCTestCase {
    func testRequestedFractionsAreReflectedInProgress() {
        let snapshot = MockUsageProvider.snapshot(sessionUsedFraction: 0.25, weeklyUsedFraction: 0.8)
        XCTAssertEqual(snapshot.period(.session)?.progress ?? 0, 0.25, accuracy: 1e-9)
        XCTAssertEqual(snapshot.period(.weekly)?.progress ?? 0, 0.8, accuracy: 1e-9)
    }

    func testSnapshotAlwaysCarriesBothPeriodsTheDialNeeds() {
        let snapshot = MockUsageProvider.snapshot()
        XCTAssertNotNil(snapshot.period(.session))
        XCTAssertNotNil(snapshot.period(.weekly))
        XCTAssertEqual(snapshot.provider, .claudeCode)
    }

    func testWeeklyResetIsAlwaysInTheFuture() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = MockUsageProvider.snapshot(now: now)
        XCTAssertGreaterThan(snapshot.period(.weekly)?.resetDate ?? now, now)
    }
}
