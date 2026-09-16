import Foundation

/// A single quota window (a 5-hour session, a weekly allowance), normalized
/// to one shape regardless of which provider it came from.
///
/// `used` and `limit` are `Duration`s so time-boxed windows and longer
/// allowances share a representation. Every derived value is clamped: a
/// malformed upstream reading (negative usage, zero limit, usage past the
/// limit) must never produce a broken ring or a crash.
public struct UsagePeriod: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let type: UsagePeriodType
    public let used: Duration
    public let limit: Duration
    public let resetDate: Date

    public init(id: String, type: UsagePeriodType, used: Duration, limit: Duration, resetDate: Date) {
        self.id = id
        self.type = type
        self.used = used
        self.limit = limit
        self.resetDate = resetDate
    }

    /// Fraction of the quota consumed, clamped to `0...1`. This is what the
    /// ring's lit arc represents.
    public var progress: Double {
        let limitSeconds = limit.secondsDouble
        guard limitSeconds > 0 else { return 0 }

        let usedSeconds = used.secondsDouble
        guard usedSeconds.isFinite else { return 0 }

        return min(max(usedSeconds / limitSeconds, 0), 1)
    }

    /// Remaining capacity, floored at zero even when `used` overshoots.
    public var remaining: Duration {
        .seconds(max(limit.secondsDouble - used.secondsDouble, 0))
    }

    public var isExhausted: Bool { progress >= 1 }
}
