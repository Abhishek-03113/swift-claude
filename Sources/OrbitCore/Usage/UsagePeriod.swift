import Foundation

/// A single quota window (a 5-hour session, a weekly allowance), normalized
/// to one shape regardless of which provider it came from.
///
/// Consumption is stored as a **fraction**, not as an amount, because that is
/// what providers actually report: Claude Code's `/usage` gives "6% used" and
/// a reset time, with no notion of "hours of quota left". Sources that do
/// report amounts use `init(used:limit:)`, which normalizes to the same
/// fraction. Every derived value is clamped: a malformed reading (negative
/// usage, a zero limit, usage past the limit) must never produce a broken
/// ring or a crash.
public struct UsagePeriod: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let type: UsagePeriodType

    /// Fraction of the quota consumed, always within `0...1`. This is what
    /// the ring's lit arc represents.
    public let progress: Double

    public let resetDate: Date

    public init(id: String, type: UsagePeriodType, usedFraction: Double, resetDate: Date) {
        self.id = id
        self.type = type
        self.progress = Self.clamped(usedFraction)
        self.resetDate = resetDate
    }

    /// For sources that report consumption as amounts rather than a fraction.
    /// A non-positive limit yields zero progress rather than a divide-by-zero.
    public init(id: String, type: UsagePeriodType, used: Duration, limit: Duration, resetDate: Date) {
        let limitSeconds = limit.secondsDouble
        let usedSeconds = used.secondsDouble
        let fraction = limitSeconds > 0 && usedSeconds.isFinite ? usedSeconds / limitSeconds : 0

        self.init(id: id, type: type, usedFraction: fraction, resetDate: resetDate)
    }

    /// Decoding goes through the clamping initializer, so a hand-edited or
    /// corrupted cache file cannot reintroduce an out-of-range fraction.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            type: try container.decode(UsagePeriodType.self, forKey: .type),
            usedFraction: try container.decode(Double.self, forKey: .progress),
            resetDate: try container.decode(Date.self, forKey: .resetDate)
        )
    }

    public var remainingFraction: Double { 1 - progress }

    public var usedPercent: Int { Int((progress * 100).rounded()) }

    public var remainingPercent: Int { Int((remainingFraction * 100).rounded()) }

    /// How long until this window resets — the only "time left" figure the
    /// underlying data actually supports.
    public func timeUntilReset(now: Date = .now) -> Duration {
        .seconds(max(resetDate.timeIntervalSince(now), 0))
    }

    public var isExhausted: Bool { progress >= 1 }

    private static func clamped(_ fraction: Double) -> Double {
        guard fraction.isFinite else { return 0 }
        return min(max(fraction, 0), 1)
    }
}
