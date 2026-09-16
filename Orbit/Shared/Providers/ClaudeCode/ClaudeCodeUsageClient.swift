import Foundation

/// The actual I/O boundary for Claude Code usage data. `ClaudeCodeProvider`
/// depends only on this protocol, so swapping how usage is actually
/// obtained — a local CLI invocation, a background daemon's cache file, a
/// future first-party API — never touches the domain model or any view.
///
/// INTEGRATION NOTE: Anthropic does not currently publish a consumer-facing
/// API for a signed-in user's own 5-hour/weekly Claude Code quota, so there
/// is no network endpoint to wire up here yet. `ClaudeCodeLocalFileUsageClient`
/// below is the seam meant for whatever the real source turns out to be —
/// most likely a small local helper (or the `claude` CLI itself, if/when it
/// exposes a usage-reporting command) writing a JSON snapshot to the App
/// Group container, which this reads. Until that exists, `ClaudeCodeProvider`
/// falls back to realistic mock data rather than pretending to have live
/// numbers.
protocol ClaudeCodeUsageClient: Sendable {
    func fetchRawUsage() async throws -> ClaudeCodeUsageDTO
}

/// Reads a JSON snapshot from the App Group container. This is the
/// documented contract an external helper process should write to:
///
/// ```json
/// {
///   "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
///   "weekly":  { "usedSeconds": 356400, "limitSeconds": 604800, "resetsAt": "2026-09-22T09:00:00Z" },
///   "generatedAt": "2026-09-16T18:00:00Z"
/// }
/// ```
struct ClaudeCodeLocalFileUsageClient: ClaudeCodeUsageClient {
    let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
            self.fileURL = (container ?? FileManager.default.temporaryDirectory)
                .appendingPathComponent("claude-usage.json")
        }
    }

    func fetchRawUsage() async throws -> ClaudeCodeUsageDTO {
        guard let data = try? Data(contentsOf: fileURL) else {
            throw UsageRepositoryError.unavailable
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(ClaudeCodeUsageDTO.self, from: data)
        } catch {
            throw UsageRepositoryError.malformedResponse(String(describing: error))
        }
    }
}
