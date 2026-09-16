import Foundation

/// Anything that can produce a `UsageSnapshot`. A provider adapter (Claude
/// Code, and later Codex/Gemini/etc.) implements this; nothing above this
/// protocol knows or cares how.
public protocol UsageRepository: Sendable {
    func snapshot() async throws -> UsageSnapshot
}

/// Errors a repository can surface. The view layer maps these to the
/// restrained error/stale states described in the spec — never a blank
/// widget, never a stack trace.
public enum UsageRepositoryError: Error, Sendable, Equatable {
    case unavailable
    case malformedResponse(String)
    case notAuthenticated
}
