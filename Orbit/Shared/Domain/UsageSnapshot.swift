import Foundation

/// A complete, normalized read of one provider's usage at a point in time.
/// This is the only type the presentation layer consumes — it has no idea
/// whether it came from a network call, a local CLI, or mock data.
public struct UsageSnapshot: Equatable, Sendable {
    public let provider: AgentProvider
    public let periods: [UsagePeriod]
    public let lastUpdated: Date

    public init(provider: AgentProvider, periods: [UsagePeriod], lastUpdated: Date) {
        self.provider = provider
        self.periods = periods
        self.lastUpdated = lastUpdated
    }

    public func period(_ type: UsagePeriodType) -> UsagePeriod? {
        periods.first { $0.type == type }
    }
}
