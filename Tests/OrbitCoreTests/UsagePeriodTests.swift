import XCTest
@testable import OrbitCore

final class UsagePeriodTests: XCTestCase {
    private func period(used: Double, limit: Double) -> UsagePeriod {
        UsageFixtures.period(used: used, limit: limit)
    }

    func testZeroUsageHasZeroProgressAndFullRemaining() {
        let period = period(used: 0, limit: 100)
        XCTAssertEqual(period.progress, 0, accuracy: 1e-9)
        XCTAssertEqual(period.remaining.secondsDouble, 100, accuracy: 1e-9)
        XCTAssertFalse(period.isExhausted)
    }

    func testFullUsageIsExhausted() {
        let period = period(used: 100, limit: 100)
        XCTAssertEqual(period.progress, 1, accuracy: 1e-9)
        XCTAssertEqual(period.remaining.secondsDouble, 0, accuracy: 1e-9)
        XCTAssertTrue(period.isExhausted)
    }

    func testHalfUsage() {
        let period = period(used: 50, limit: 100)
        XCTAssertEqual(period.progress, 0.5, accuracy: 1e-9)
        XCTAssertEqual(period.remaining.secondsDouble, 50, accuracy: 1e-9)
    }

    func testOverusageClampsProgressAndFloorsRemainingAtZero() {
        let period = period(used: 150, limit: 100)
        XCTAssertEqual(period.progress, 1, accuracy: 1e-9)
        XCTAssertEqual(period.remaining.secondsDouble, 0, accuracy: 1e-9)
        XCTAssertTrue(period.isExhausted)
    }

    func testZeroLimitDoesNotCrashAndReportsZeroProgress() {
        XCTAssertEqual(period(used: 10, limit: 0).progress, 0, accuracy: 1e-9)
    }

    func testNegativeUsageClampsProgressToZero() {
        XCTAssertEqual(period(used: -20, limit: 100).progress, 0, accuracy: 1e-9)
    }
}
