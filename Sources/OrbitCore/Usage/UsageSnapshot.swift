import Foundation

/// A complete, normalized read of one provider's usage at a point in time.
/// The only type the presentation layer consumes — it carries no trace of
/// whether it came from a network call, a local file, or mock data.
public struct UsageSnapshot: Equatable, Sendable, Codable {
    public let provider: AgentProvider
    public let periods: [UsagePeriod]
    public let lastUpdated: Date

    /// Present only when the reading came from the API client, which is the
    /// only source that has this detail. `nil` decodes cleanly from snapshots
    /// cached before this field existed, and from CLI-fallback readings.
    public let analytics: ClaudeUsageAnalytics?

    public init(provider: AgentProvider, periods: [UsagePeriod], lastUpdated: Date, analytics: ClaudeUsageAnalytics? = nil) {
        self.provider = provider
        self.periods = periods
        self.lastUpdated = lastUpdated
        self.analytics = analytics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            provider: try container.decode(AgentProvider.self, forKey: .provider),
            periods: try container.decode([UsagePeriod].self, forKey: .periods),
            lastUpdated: try container.decode(Date.self, forKey: .lastUpdated),
            analytics: try container.decodeIfPresent(ClaudeUsageAnalytics.self, forKey: .analytics)
        )
    }

    public func period(_ type: UsagePeriodType) -> UsagePeriod? {
        periods.first { $0.type == type }
    }
}
