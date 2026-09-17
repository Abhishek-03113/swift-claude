import Foundation
import OrbitCore

/// Tries the direct API client first — no subprocess, a stable JSON
/// contract — and falls back to running `claude -p /usage` and parsing its
/// text only if the API path fails (no Keychain item, network error,
/// unrecognized response shape). Both clients report the same errors when
/// both fail, so the caller sees a coherent single failure rather than the
/// primary's.
public struct FallbackClaudeCodeUsageClient: ClaudeCodeUsageClient {
    private let primary: ClaudeCodeUsageClient
    private let fallback: ClaudeCodeUsageClient

    public init(
        primary: ClaudeCodeUsageClient = ClaudeCodeAPIUsageClient(),
        fallback: ClaudeCodeUsageClient = ClaudeCodeCLIUsageClient()
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    public func fetchUsage() async throws -> ClaudeCodeUsageReading {
        do {
            return try await primary.fetchUsage()
        } catch {
            return try await fallback.fetchUsage()
        }
    }
}
