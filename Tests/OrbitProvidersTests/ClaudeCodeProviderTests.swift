import XCTest
import OrbitCore
@testable import OrbitProviders

private struct StubClient: ClaudeCodeUsageClient {
    let result: Result<ClaudeCodeUsageReading, UsageRepositoryError>
    func fetchUsage() async throws -> ClaudeCodeUsageReading { try result.get() }
}

private func reading(
    sessionFraction: Double = 0.5,
    weeklyFraction: Double = 0.25,
    includeWeekly: Bool = true,
    at now: Date
) -> ClaudeCodeUsageReading {
    var periods = [UsagePeriod(id: "session", type: .session, usedFraction: sessionFraction, resetDate: now)]
    if includeWeekly {
        periods.append(UsagePeriod(id: "weekly", type: .weekly, usedFraction: weeklyFraction, resetDate: now))
    }
    return ClaudeCodeUsageReading(periods: periods, generatedAt: now)
}

final class ClaudeCodeProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    func testProviderAttributesTheReadingToClaudeCode() async throws {
        let snapshot = try await ClaudeCodeProvider(
            client: StubClient(result: .success(reading(at: now)))
        ).snapshot()

        XCTAssertEqual(snapshot.provider.id, AgentProvider.claudeCode.id)
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

    /// The dial is built around both windows; half a reading is a failure
    /// rather than something to render partially.
    func testReadingMissingTheWeeklyPeriodIsRejected() async {
        let incomplete = reading(includeWeekly: false, at: now)
        let provider = ClaudeCodeProvider(client: StubClient(result: .success(incomplete)))

        do {
            _ = try await provider.snapshot()
            XCTFail("expected snapshot() to throw")
        } catch {
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)")
            }
        }
    }
}

final class ClaudeCodeCLIUsageClientTests: XCTestCase {
    private struct FixedOutputRunner: ProcessRunning {
        let output: String
        func run(executable: URL, arguments: [String], timeout: Duration) async throws -> String { output }
    }

    private struct FailingRunner: ProcessRunning {
        let error: UsageRepositoryError
        func run(executable: URL, arguments: [String], timeout: Duration) async throws -> String { throw error }
    }

    private func client(runner: ProcessRunning) -> ClaudeCodeCLIUsageClient {
        ClaudeCodeCLIUsageClient(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: ["-p", "/usage"],
            timeout: .seconds(5),
            runner: runner
        )
    }

    func testClientParsesCommandOutput() async throws {
        let output = """
        Current session
        ███   40% used
        Resets 8:40pm (UTC)

        Current week (all models)
        ████   70% used
        Resets Sep 21 at 1:30am (UTC)
        """

        let reading = try await client(runner: FixedOutputRunner(output: output)).fetchUsage()
        XCTAssertEqual(reading.periods.first { $0.type == .session }?.progress ?? 0, 0.4, accuracy: 1e-9)
        XCTAssertEqual(reading.periods.first { $0.type == .weekly }?.progress ?? 0, 0.7, accuracy: 1e-9)
    }

    func testCommandFailurePropagates() async {
        do {
            _ = try await client(runner: FailingRunner(error: .unavailable)).fetchUsage()
            XCTFail("expected fetchUsage() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .unavailable)
        }
    }

    /// A missing `claude` binary is "unavailable", not a crash — the app
    /// explains how to fix it rather than failing opaquely.
    func testMissingExecutableReportsUnavailable() async {
        let client = ClaudeCodeCLIUsageClient(
            executableURL: nil,
            arguments: [],
            timeout: .seconds(1),
            runner: FixedOutputRunner(output: "")
        )

        // Only meaningful when no real `claude` is installed on the test host.
        guard ClaudeCodeCLIUsageClient.locateExecutable() == nil else { return }

        do {
            _ = try await client.fetchUsage()
            XCTFail("expected fetchUsage() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .unavailable)
        }
    }
}
