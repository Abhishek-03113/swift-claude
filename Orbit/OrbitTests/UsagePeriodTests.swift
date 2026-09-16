import XCTest
// Domain sources are compiled directly into this test target (see
// project.yml), so no module import is needed to see them.

final class UsagePeriodTests: XCTestCase {
    private func period(used: Double, limit: Double) -> UsagePeriod {
        UsagePeriod(id: "t", type: .session, used: .seconds(used), limit: .seconds(limit), resetDate: .now.addingTimeInterval(limit - used))
    }

    func testZeroUsageHasZeroProgressAndFullRemaining() {
        let p = period(used: 0, limit: 100)
        XCTAssertEqual(p.progress, 0, accuracy: 1e-9)
        XCTAssertEqual(p.remaining.secondsDouble, 100, accuracy: 1e-9)
        XCTAssertFalse(p.isExhausted)
    }

    func testFullUsageIsExhausted() {
        let p = period(used: 100, limit: 100)
        XCTAssertEqual(p.progress, 1, accuracy: 1e-9)
        XCTAssertEqual(p.remaining.secondsDouble, 0, accuracy: 1e-9)
        XCTAssertTrue(p.isExhausted)
    }

    func testHalfUsage() {
        let p = period(used: 50, limit: 100)
        XCTAssertEqual(p.progress, 0.5, accuracy: 1e-9)
        XCTAssertEqual(p.remaining.secondsDouble, 50, accuracy: 1e-9)
    }

    func testOverusageClampsProgressAndFloorsRemainingAtZero() {
        let p = period(used: 150, limit: 100)
        XCTAssertEqual(p.progress, 1, accuracy: 1e-9)
        XCTAssertEqual(p.remaining.secondsDouble, 0, accuracy: 1e-9)
        XCTAssertTrue(p.isExhausted)
    }

    func testZeroLimitDoesNotCrashAndReportsZeroProgress() {
        let p = period(used: 10, limit: 0)
        XCTAssertEqual(p.progress, 0, accuracy: 1e-9)
    }

    func testNegativeUsageClampsProgressToZero() {
        let p = period(used: -20, limit: 100)
        XCTAssertEqual(p.progress, 0, accuracy: 1e-9)
    }
}
