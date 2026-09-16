import Foundation

/// Anything that can produce a `UsageSnapshot`. Provider adapters implement
/// it; nothing above this protocol knows how the data was obtained.
public protocol UsageRepository: Sendable {
    func snapshot() async throws -> UsageSnapshot
}

/// Errors a repository can surface. The view layer maps these to restrained
/// stale/unavailable states — never a blank widget, never a raw error dump.
public enum UsageRepositoryError: Error, Sendable, Equatable {
    case unavailable
    case malformedResponse(String)
    case notAuthenticated
}
