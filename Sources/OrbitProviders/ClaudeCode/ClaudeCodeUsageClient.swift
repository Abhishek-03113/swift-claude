import Foundation
import OrbitCore

/// The I/O boundary for Claude Code usage data. `ClaudeCodeProvider` depends
/// only on this protocol, so changing how usage is obtained — a local helper,
/// a CLI command, a future API — touches nothing else.
public protocol ClaudeCodeUsageClient: Sendable {
    func fetchRawUsage() async throws -> ClaudeCodeUsageDTO
}

/// Reads a JSON snapshot from the App Group container. See the repository
/// README ("Known gap") for why this, rather than a network call, is the
/// default: nothing currently writes this file, so the provider reports
/// `.unavailable` until a helper does.
///
/// The expected document:
///
/// ```json
/// {
///   "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
///   "weekly":  { "usedSeconds": 356400, "limitSeconds": 604800, "resetsAt": "2026-09-22T09:00:00Z" },
///   "generatedAt": "2026-09-16T18:00:00Z"
/// }
/// ```
public struct ClaudeCodeLocalFileUsageClient: ClaudeCodeUsageClient {
    /// Filename the helper process is expected to write inside the App Group.
    public static let defaultFilename = "claude-usage.json"

    public let fileURL: URL

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
    }

    public func fetchRawUsage() async throws -> ClaudeCodeUsageDTO {
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

    private static func defaultFileURL() -> URL {
        let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
        return (container ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent(defaultFilename)
    }
}
