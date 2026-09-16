import XCTest

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
        XCTAssertEqual(UsageFormatting.remainingText(.seconds(0)), "0m")
    }

    func testResetTextForSessionIsACountdown() {
        let now = Date(timeIntervalSince1970: 0)
        let reset = now.addingTimeInterval(2 * 3600 + 43 * 60)
        XCTAssertEqual(UsageFormatting.resetText(for: .session, resetDate: reset, now: now), "resets in 2h 43m")
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
    }
}
