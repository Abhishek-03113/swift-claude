import XCTest
import OrbitCore
@testable import OrbitProviders

final class ClaudeCodeUsageParsingTests: XCTestCase {
    private func dto(
        sessionUsed: Double = 9_000,
        sessionLimit: Double = 18_000,
        weeklyUsed: Double = 300_000,
        weeklyLimit: Double = 604_800
    ) -> ClaudeCodeUsageDTO {
        let now = Date(timeIntervalSince1970: 1_000_000)
        return ClaudeCodeUsageDTO(
            session: .init(
                usedSeconds: sessionUsed,
                limitSeconds: sessionLimit,
                resetsAt: now.addingTimeInterval(sessionLimit - sessionUsed)
            ),
            weekly: .init(
                usedSeconds: weeklyUsed,
                limitSeconds: weeklyLimit,
                resetsAt: now.addingTimeInterval(weeklyLimit - weeklyUsed)
            ),
            generatedAt: now
        )
    }

    private func assertMalformed(
        _ expression: @autoclosure () throws -> UsageSnapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)", file: file, line: line)
            }
        }
    }

    func testValidDTONormalizesToTwoPeriodsUnderClaudeCode() throws {
        let snapshot = try ClaudeCodeUsageParsing.normalize(dto())
        XCTAssertEqual(snapshot.provider.id, "claude-code")
        XCTAssertNotNil(snapshot.period(.session))
        XCTAssertNotNil(snapshot.period(.weekly))
    }

    func testNonPositiveLimitIsRejectedAsMalformed() {
        assertMalformed(try ClaudeCodeUsageParsing.normalize(dto(sessionLimit: 0)))
        assertMalformed(try ClaudeCodeUsageParsing.normalize(dto(weeklyLimit: -1)))
    }

    func testNegativeOrNonFiniteUsedSecondsIsRejectedAsMalformed() {
        assertMalformed(try ClaudeCodeUsageParsing.normalize(dto(sessionUsed: -1)))
        assertMalformed(try ClaudeCodeUsageParsing.normalize(dto(sessionUsed: .nan)))
        assertMalformed(try ClaudeCodeUsageParsing.normalize(dto(sessionUsed: .infinity)))
    }

    func testDTODecodesFromWellFormedJSON() throws {
        let json = Data("""
        {
          "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
          "weekly":  { "usedSeconds": 356400, "limitSeconds": 604800, "resetsAt": "2026-09-22T09:00:00Z" },
          "generatedAt": "2026-09-16T18:00:00Z"
        }
        """.utf8)

        let decoded = try Self.decoder.decode(ClaudeCodeUsageDTO.self, from: json)
        XCTAssertEqual(decoded.session.usedSeconds, 8820)

        let snapshot = try ClaudeCodeUsageParsing.normalize(decoded)
        XCTAssertEqual(snapshot.period(.session)?.progress ?? 0, 8820 / 18000, accuracy: 1e-9)
    }

    func testMissingFieldFailsToDecode() {
        let json = Data("""
        {
          "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
          "generatedAt": "2026-09-16T18:00:00Z"
        }
        """.utf8)
        XCTAssertThrowsError(try Self.decoder.decode(ClaudeCodeUsageDTO.self, from: json))
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
