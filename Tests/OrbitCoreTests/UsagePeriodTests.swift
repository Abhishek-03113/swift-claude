import XCTest
@testable import OrbitCore

final class UsagePeriodTests: XCTestCase {
    private func period(used: Double, limit: Double) -> UsagePeriod {
        UsageFixtures.period(used: used, limit: limit)
    }

    func testZeroUsageHasZeroProgress() {
        let period = period(used: 0, limit: 100)
        XCTAssertEqual(period.progress, 0, accuracy: 1e-9)
        XCTAssertEqual(period.remainingPercent, 100)
        XCTAssertFalse(period.isExhausted)
    }

    func testFullUsageIsExhausted() {
        let period = period(used: 100, limit: 100)
        XCTAssertEqual(period.progress, 1, accuracy: 1e-9)
        XCTAssertEqual(period.remainingPercent, 0)
        XCTAssertTrue(period.isExhausted)
    }

    func testHalfUsage() {
        let period = period(used: 50, limit: 100)
        XCTAssertEqual(period.progress, 0.5, accuracy: 1e-9)
        XCTAssertEqual(period.usedPercent, 50)
        XCTAssertEqual(period.remainingPercent, 50)
    }

    func testOverusageClampsProgress() {
        let period = period(used: 150, limit: 100)
        XCTAssertEqual(period.progress, 1, accuracy: 1e-9)
        XCTAssertEqual(period.remainingPercent, 0)
        XCTAssertTrue(period.isExhausted)
    }

    func testZeroLimitDoesNotCrashAndReportsZeroProgress() {
        XCTAssertEqual(period(used: 10, limit: 0).progress, 0, accuracy: 1e-9)
    }

    func testNegativeUsageClampsProgressToZero() {
        XCTAssertEqual(period(used: -20, limit: 100).progress, 0, accuracy: 1e-9)
    }

    func testFractionInitializerClampsOutOfRangeInput() {
        let reset = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(UsagePeriod(id: "s", type: .session, usedFraction: 1.4, resetDate: reset).progress, 1, accuracy: 1e-9)
        XCTAssertEqual(UsagePeriod(id: "s", type: .session, usedFraction: -0.4, resetDate: reset).progress, 0, accuracy: 1e-9)
        XCTAssertEqual(UsagePeriod(id: "s", type: .session, usedFraction: .nan, resetDate: reset).progress, 0, accuracy: 1e-9)
    }

    func testTimeUntilResetCountsDownAndFloorsAtZero() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let period = UsagePeriod(id: "s", type: .session, usedFraction: 0.5, resetDate: now.addingTimeInterval(3600))

        XCTAssertEqual(period.timeUntilReset(now: now).secondsDouble, 3600, accuracy: 1e-9)
        XCTAssertEqual(period.timeUntilReset(now: now.addingTimeInterval(7200)).secondsDouble, 0, accuracy: 1e-9)
    }
}
