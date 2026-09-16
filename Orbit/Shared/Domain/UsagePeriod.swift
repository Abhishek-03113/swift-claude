import Foundation

/// A single quota window (e.g. "5-hour session" or "weekly allowance"),
/// normalized to a common shape regardless of which provider it came from.
///
/// `used`/`limit` are expressed as `Duration` per the product spec, so both
/// time-boxed windows (session) and longer-running allowances (weekly) share
/// one representation. All derived quantities below are clamped defensively:
/// a malformed upstream response (negative usage, zero limit, usage past
/// limit) must never produce a broken ring or a crashing view.
public struct UsagePeriod: Identifiable, Equatable, Sendable {
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
    /// ring's lit arc represents (see design decision: ring = used).
    public var progress: Double {
        let limitSeconds = limit.secondsDouble
        guard limitSeconds > 0 else { return 0 }
        let usedSeconds = used.secondsDouble
        guard usedSeconds.isFinite else { return 0 }
        return min(max(usedSeconds / limitSeconds, 0), 1)
    }

    /// Remaining capacity, floored at zero even if `used` overshoots `limit`.
    public var remaining: Duration {
        let remainingSeconds = max(limit.secondsDouble - used.secondsDouble, 0)
        return .seconds(remainingSeconds)
    }

    public var isExhausted: Bool { progress >= 1 }
}

extension Duration {
    var secondsDouble: Double {
        let c = components
        return Double(c.seconds) + Double(c.attoseconds) / 1e18
    }
}
