import XCTest
import OrbitCore
@testable import OrbitProviders

private struct StubClient: ClaudeCodeUsageClient {
    let result: Result<ClaudeCodeUsageReading, UsageRepositoryError>
    func fetchUsage() async throws -> ClaudeCodeUsageReading { try result.get() }
}

final class FallbackUsageClientTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func reading(sessionFraction: Double) -> ClaudeCodeUsageReading {
        ClaudeCodeUsageReading(
            periods: [
                UsagePeriod(id: "session", type: .session, usedFraction: sessionFraction, resetDate: now),
                UsagePeriod(id: "weekly", type: .weekly, usedFraction: 0.1, resetDate: now),
            ],
            generatedAt: now
        )
    }

    func testUsesThePrimaryClientWhenItSucceeds() async throws {
        let client = FallbackClaudeCodeUsageClient(
            primary: StubClient(result: .success(reading(sessionFraction: 0.5))),
            fallback: StubClient(result: .success(reading(sessionFraction: 0.9)))
        )

        let result = try await client.fetchUsage()
        XCTAssertEqual(result.periods.first { $0.type == .session }?.progress ?? 0, 0.5, accuracy: 1e-9)
    }

    func testFallsBackToTheCLIClientWhenTheAPIClientFails() async throws {
        let client = FallbackClaudeCodeUsageClient(
            primary: StubClient(result: .failure(.notAuthenticated)),
            fallback: StubClient(result: .success(reading(sessionFraction: 0.9)))
        )

        let result = try await client.fetchUsage()
        XCTAssertEqual(result.periods.first { $0.type == .session }?.progress ?? 0, 0.9, accuracy: 1e-9)
    }

    func testPropagatesTheFallbacksFailureWhenBothFail() async {
        let client = FallbackClaudeCodeUsageClient(
            primary: StubClient(result: .failure(.notAuthenticated)),
            fallback: StubClient(result: .failure(.unavailable))
        )

        do {
            _ = try await client.fetchUsage()
            XCTFail("expected fetchUsage() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .unavailable)
        }
    }
}
