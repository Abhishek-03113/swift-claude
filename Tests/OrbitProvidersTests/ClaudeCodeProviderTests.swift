import XCTest
import OrbitCore
@testable import OrbitProviders

private struct StubClient: ClaudeCodeUsageClient {
    let result: Result<ClaudeCodeUsageDTO, UsageRepositoryError>
    func fetchRawUsage() async throws -> ClaudeCodeUsageDTO { try result.get() }
}

final class ClaudeCodeProviderTests: XCTestCase {
    func testProviderNormalizesWhatTheClientReturns() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let dto = ClaudeCodeUsageDTO(
            session: .init(usedSeconds: 9_000, limitSeconds: 18_000, resetsAt: now),
            weekly: .init(usedSeconds: 151_200, limitSeconds: 604_800, resetsAt: now),
            generatedAt: now
        )

        let snapshot = try await ClaudeCodeProvider(client: StubClient(result: .success(dto))).snapshot()
        XCTAssertEqual(snapshot.lastUpdated, now)
        XCTAssertEqual(snapshot.period(.session)?.progress ?? 0, 0.5, accuracy: 1e-9)
        XCTAssertEqual(snapshot.period(.weekly)?.progress ?? 0, 0.25, accuracy: 1e-9)
    }

    func testProviderPropagatesClientFailure() async {
        let provider = ClaudeCodeProvider(client: StubClient(result: .failure(.unavailable)))
        do {
            _ = try await provider.snapshot()
            XCTFail("expected snapshot() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .unavailable)
        }
    }
}

final class ClaudeCodeLocalFileUsageClientTests: XCTestCase {
    private func writeTemporaryFile(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("orbit-usage-\(UUID().uuidString).json")
        try Data(contents.utf8).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testMissingFileReportsUnavailableRatherThanThrowingAFileError() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("orbit-missing-\(UUID().uuidString).json")
        do {
            _ = try await ClaudeCodeLocalFileUsageClient(fileURL: url).fetchRawUsage()
            XCTFail("expected fetchRawUsage() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .unavailable)
        }
    }

    func testMalformedFileReportsMalformedResponse() async throws {
        let url = try writeTemporaryFile("{ not json")
        do {
            _ = try await ClaudeCodeLocalFileUsageClient(fileURL: url).fetchRawUsage()
            XCTFail("expected fetchRawUsage() to throw")
        } catch {
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)")
            }
        }
    }

    func testWellFormedFileDecodesUsingISO8601Dates() async throws {
        let url = try writeTemporaryFile("""
        {
          "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
          "weekly":  { "usedSeconds": 356400, "limitSeconds": 604800, "resetsAt": "2026-09-22T09:00:00Z" },
          "generatedAt": "2026-09-16T18:00:00Z"
        }
        """)

        let dto = try await ClaudeCodeLocalFileUsageClient(fileURL: url).fetchRawUsage()
        XCTAssertEqual(dto.session.usedSeconds, 8820)
        XCTAssertEqual(dto.weekly.limitSeconds, 604_800)
    }
}
