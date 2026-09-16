import Foundation
import OrbitCore

/// The Claude Code adapter: fetch via `ClaudeCodeUsageClient`, normalize via
/// `ClaudeCodeUsageParsing`. A second agent means writing exactly this shape
/// of type against the same two protocols.
public struct ClaudeCodeProvider: UsageRepository {
    private let client: ClaudeCodeUsageClient

    public init(client: ClaudeCodeUsageClient = ClaudeCodeLocalFileUsageClient()) {
        self.client = client
    }

    public func snapshot() async throws -> UsageSnapshot {
        let raw = try await client.fetchRawUsage()
        return try ClaudeCodeUsageParsing.normalize(raw)
    }
}
