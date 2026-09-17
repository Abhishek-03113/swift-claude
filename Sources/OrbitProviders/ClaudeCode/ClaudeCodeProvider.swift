import Foundation
import OrbitCore

/// The Claude Code adapter: fetch through a `ClaudeCodeUsageClient`, attribute
/// the result to this provider. A second agent means writing exactly this
/// shape of type against the same protocol.
public struct ClaudeCodeProvider: UsageRepository {
    private let client: ClaudeCodeUsageClient

    public init(client: ClaudeCodeUsageClient = FallbackClaudeCodeUsageClient()) {
        self.client = client
    }

    public func snapshot() async throws -> UsageSnapshot {
        let reading = try await client.fetchUsage()

        guard reading.periods.contains(where: { $0.type == .session }),
              reading.periods.contains(where: { $0.type == .weekly }) else {
            throw UsageRepositoryError.malformedResponse("Reading is missing a session or weekly period")
        }

        return UsageSnapshot(
            provider: .claudeCode,
            periods: reading.periods,
            lastUpdated: reading.generatedAt,
            analytics: reading.analytics
        )
    }
}
