import XCTest
import OrbitCore
@testable import OrbitProviders

final class ClaudeUsageTextParserTests: XCTestCase {
    /// Verbatim `claude /usage` output, indentation and progress-bar glyphs
    /// included, so the fixture stays honest about what the CLI prints.
    private let realOutput = """
       Settings  Status   Config   Usage   Stats

       Session

       Total cost:            $0.0000
       Total duration (API):  0s
       Total duration (wall): 1s
       Total code changes:    0 lines added, 0 lines removed
       Usage:                 0 input, 0 output, 0 cache read, 0 cache write

       Current session
       ███                                                6% used
       Resets 8:40pm (Asia/Calcutta)

       Current week (all models)
       ████████████▌                                      25% used
       Resets Sep 21 at 1:30am (Asia/Calcutta)
    """

    /// Mid-afternoon in Asia/Calcutta on 17 Sep 2026, so the 8:40pm session
    /// reset is later the same day.
    private var now: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 17
        components.hour = 15
        components.minute = 0

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Calcutta")!
        return calendar.date(from: components)!
    }

    func testParsesBothQuotaPercentages() throws {
        let reading = try ClaudeUsageTextParser.parse(realOutput, now: now)

        let session = try XCTUnwrap(reading.periods.first { $0.type == .session })
        let weekly = try XCTUnwrap(reading.periods.first { $0.type == .weekly })

        XCTAssertEqual(session.progress, 0.06, accuracy: 1e-9)
        XCTAssertEqual(weekly.progress, 0.25, accuracy: 1e-9)
        XCTAssertEqual(session.usedPercent, 6)
        XCTAssertEqual(weekly.remainingPercent, 75)
    }

    func testParsesSameDayResetTimeInTheReportedTimeZone() throws {
        let reading = try ClaudeUsageTextParser.parse(realOutput, now: now)
        let session = try XCTUnwrap(reading.periods.first { $0.type == .session })

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Calcutta")!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: session.resetDate)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 17)
        XCTAssertEqual(components.hour, 20)
        XCTAssertEqual(components.minute, 40)
    }

    func testParsesDatedResetWithNoYearGiven() throws {
        let reading = try ClaudeUsageTextParser.parse(realOutput, now: now)
        let weekly = try XCTUnwrap(reading.periods.first { $0.type == .weekly })

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Calcutta")!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: weekly.resetDate)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 21)
        XCTAssertEqual(components.hour, 1)
        XCTAssertEqual(components.minute, 30)
    }

    /// A reset time already past today means tomorrow, not a date in the past.
    func testTimeOnlyResetRollsToTomorrowWhenAlreadyPast() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Calcutta")!
        let lateEvening = calendar.date(from: DateComponents(year: 2026, month: 9, day: 17, hour: 23, minute: 0))!

        let reading = try ClaudeUsageTextParser.parse(realOutput, now: lateEvening)
        let session = try XCTUnwrap(reading.periods.first { $0.type == .session })

        XCTAssertEqual(calendar.dateComponents([.day], from: session.resetDate).day, 18)
        XCTAssertGreaterThan(session.resetDate, lateEvening)
    }

    /// The cost-only output an API-key login produces has no quota section;
    /// that must be an explicit failure rather than a dial reading zero.
    func testOutputWithoutAQuotaSectionThrows() {
        let costOnly = """
        Total cost:            $0.0000
        Total duration (API):  0s
        Usage:                 0 input, 0 output, 0 cache read, 0 cache write
        """

        XCTAssertThrowsError(try ClaudeUsageTextParser.parse(costOnly, now: now)) { error in
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)")
            }
        }
    }

    func testModelSpecificWeeklyCapIsCarriedAsAnExtraPeriod() throws {
        let withOpus = realOutput + """

           Current week (Opus)
           ██████                                             12% used
           Resets Sep 21 at 1:30am (Asia/Calcutta)
        """

        let reading = try ClaudeUsageTextParser.parse(withOpus, now: now)
        let opus = try XCTUnwrap(reading.periods.first { $0.id == "weekly-opus" })

        XCTAssertEqual(opus.type, .custom)
        XCTAssertEqual(opus.progress, 0.12, accuracy: 1e-9)
        // The all-models weekly is still the one the dial reads.
        XCTAssertEqual(reading.periods.filter { $0.type == .weekly }.count, 1)
    }

    func testANSIStylingIsStripped() throws {
        let styled = realOutput
            .replacingOccurrences(of: "6% used", with: "\u{001B}[32m6% used\u{001B}[0m")
            .replacingOccurrences(of: "Current session", with: "\u{001B}[1mCurrent session\u{001B}[0m")

        let reading = try ClaudeUsageTextParser.parse(styled, now: now)
        let session = try XCTUnwrap(reading.periods.first { $0.type == .session })
        XCTAssertEqual(session.progress, 0.06, accuracy: 1e-9)
    }

    func testFractionalPercentageIsParsed() throws {
        let fractional = realOutput.replacingOccurrences(of: "6% used", with: "6.5% used")
        let reading = try ClaudeUsageTextParser.parse(fractional, now: now)
        let session = try XCTUnwrap(reading.periods.first { $0.type == .session })

        XCTAssertEqual(session.progress, 0.065, accuracy: 1e-9)
    }

    func testEmptyOutputThrowsRatherThanReportingZeroUsage() {
        XCTAssertThrowsError(try ClaudeUsageTextParser.parse("", now: now))
    }
}
