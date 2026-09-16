import XCTest

final class ClaudeCodeUsageParsingTests: XCTestCase {
    private func dto(sessionLimit: Double = 18000, sessionUsed: Double = 9000, weeklyLimit: Double = 604800, weeklyUsed: Double = 300000) -> ClaudeCodeUsageDTO {
        ClaudeCodeUsageDTO(
            session: .init(usedSeconds: sessionUsed, limitSeconds: sessionLimit, resetsAt: .now.addingTimeInterval(sessionLimit - sessionUsed)),
            weekly: .init(usedSeconds: weeklyUsed, limitSeconds: weeklyLimit, resetsAt: .now.addingTimeInterval(weeklyLimit - weeklyUsed)),
            generatedAt: .now
        )
    }

    func testValidDTONormalizesToTwoPeriodsUnderClaudeCode() throws {
        let snapshot = try ClaudeCodeUsageParsing.normalize(dto())
        XCTAssertEqual(snapshot.provider.id, "claude-code")
        XCTAssertNotNil(snapshot.period(.session))
        XCTAssertNotNil(snapshot.period(.weekly))
    }

    func testZeroSessionLimitIsRejectedAsMalformed() {
        XCTAssertThrowsError(try ClaudeCodeUsageParsing.normalize(dto(sessionLimit: 0))) { error in
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)")
            }
        }
    }

    func testNegativeUsedSecondsIsRejectedAsMalformed() {
        XCTAssertThrowsError(try ClaudeCodeUsageParsing.normalize(dto(sessionUsed: -1))) { error in
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)")
            }
        }
    }

    func testDTODecodesFromWellFormedJSON() throws {
        let json = """
        {
          "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
          "weekly":  { "usedSeconds": 356400, "limitSeconds": 604800, "resetsAt": "2026-09-22T09:00:00Z" },
          "generatedAt": "2026-09-16T18:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ClaudeCodeUsageDTO.self, from: json)
        XCTAssertEqual(decoded.session.usedSeconds, 8820)
        let snapshot = try ClaudeCodeUsageParsing.normalize(decoded)
        XCTAssertEqual(snapshot.period(.session)?.progress ?? 0, 8820 / 18000, accuracy: 1e-9)
    }

    func testMissingFieldFailsToDecode() {
        let json = """
        {
          "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
          "generatedAt": "2026-09-16T18:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        XCTAssertThrowsError(try decoder.decode(ClaudeCodeUsageDTO.self, from: json))
    }
}
