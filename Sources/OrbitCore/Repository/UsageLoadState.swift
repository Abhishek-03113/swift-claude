import Foundation

/// What the presentation layer should show right now. Deliberately small:
/// the dial's structure never disappears, only what fills it changes.
public enum UsageLoadState: Equatable, Sendable {
    /// No cached snapshot yet, and no result back from the repository.
    case loading
    /// A fresh, successfully fetched snapshot.
    case loaded(UsageSnapshot)
    /// The last known-good snapshot, kept on screen because the most recent
    /// refresh failed. Its `lastUpdated` is the last real fetch.
    case stale(UsageSnapshot)
    /// Nothing cached and the fetch failed — the only case where the dial
    /// cannot render real data.
    case failed(UsageRepositoryError)
}
