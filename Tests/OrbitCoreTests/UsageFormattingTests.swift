import XCTest
@testable import OrbitCore

final class UsageFormattingTests: XCTestCase {
    func testRemainingTextUsesHoursAndMinutesUnderADay() {
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(2 * 3600 + 17 * 60)), "2h 17m")
    }

    func testRemainingTextUsesDaysAndHoursOverADay() {
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(2 * 86400 + 8 * 3600)), "2d 8h")
    }

    func testRemainingTextUnderAnHourOmitsHours() {
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(45 * 60)), "45m")
    }

    func testRemainingTextFloorsAtZeroMinutesNeverNegative() {
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(-30)), "0m")
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(-86400)), "0m")
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(0)), "0m")
    }

    func testResetTextForSessionIsACountdown() {
        let now = Date(timeIntervalSince1970: 0)
        let reset = now.addingTimeInterval(2 * 3600 + 43 * 60)
        XCTAssertEqual(UsageFormatting.resetText(for: .session, resetDate: reset, now: now), "resets in 2h 43m")
    }

    func testResetTextForANearTermWeeklyWindowIsStillACountdown() {
        let now = Date(timeIntervalSince1970: 0)
        let reset = now.addingTimeInterval(3 * 3600)
        XCTAssertEqual(UsageFormatting.resetText(for: .weekly, resetDate: reset, now: now), "resets in 3h 0m")
    }

    func testResetTextForPastDateIsRestrained() {
        let now = Date(timeIntervalSince1970: 1000)
        let reset = Date(timeIntervalSince1970: 500)
        XCTAssertEqual(UsageFormatting.resetText(for: .session, resetDate: reset, now: now), "resets shortly")
    }

    func testSpokenRemainingTextSpellsOutUnits() {
        XCTAssertEqual(UsageFormatting.spokenRemainingText(.seconds(2 * 3600 + 17 * 60)), "2 hours 17 minutes")
        XCTAssertEqual(UsageFormatting.spokenRemainingText(.seconds(60)), "1 minute")
        XCTAssertEqual(UsageFormatting.spokenRemainingText(.seconds(0)), "0 minutes")
        XCTAssertEqual(UsageFormatting.spokenRemainingText(.seconds(86400 + 3600)), "1 day 1 hour")
    }

    func testUpdatedAgoTextBucketsByMinuteThenHour() {
        let now = Date(timeIntervalSince1970: 100_000)
        XCTAssertEqual(UsageFormatting.updatedAgoText(now, now: now), "updated just now")
        XCTAssertEqual(UsageFormatting.updatedAgoText(now.addingTimeInterval(-900), now: now), "updated 15m ago")
        XCTAssertEqual(UsageFormatting.updatedAgoText(now.addingTimeInterval(-7200), now: now), "updated 2h ago")
        // A future date must not read as a negative age.
        XCTAssertEqual(UsageFormatting.updatedAgoText(now.addingTimeInterval(600), now: now), "updated just now")
    }
}
