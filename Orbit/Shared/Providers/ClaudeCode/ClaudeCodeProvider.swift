import Foundation

/// The Claude Code provider adapter: `UsageRepository` conformance that
/// fetches via `ClaudeCodeUsageClient` and normalizes through
/// `ClaudeCodeUsageParsing`. Adding a second agent (Codex, Gemini, ...)
/// means writing exactly this shape of type against the same two
/// protocols — the UI and domain layers need no changes.
public struct ClaudeCodeProvider: UsageRepository {
    private let client: ClaudeCodeUsageClient

    public init(client: ClaudeCodeUsageClient = ClaudeCodeLocalFileUsageClient()) {
        self.client = client
    }

    public func snapshot() async throws -> UsageSnapshot {
        let dto = try await client.fetchRawUsage()
        return try ClaudeCodeUsageParsing.normalize(dto)
    }
}
