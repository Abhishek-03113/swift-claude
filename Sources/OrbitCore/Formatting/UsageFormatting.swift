import Foundation

/// Text for the dial's center content and reset metadata. Kept out of the
/// views so short/long durations, the exhausted state and weekly weekday
/// naming are testable without rendering anything.
public enum UsageFormatting {
    /// "2h 17m", "2d 8h", "45m", or "0m" once exhausted. Never negative,
    /// never a fractional or garbled unit.
    public static func remainingText(_ duration: Duration) -> String {
        let parts = Parts(duration)
        guard parts.totalMinutes > 0 else { return "0m" }

        if parts.days > 0 { return "\(parts.days)d \(parts.hours)h" }
        if parts.hours > 0 { return "\(parts.hours)h \(parts.minutes)m" }
        return "\(parts.minutes)m"
    }

    /// Fully spelled out for VoiceOver, e.g. "2 hours 43 minutes", so
    /// accessibility never depends on the visually compact "2h 43m" form.
    public static func spokenRemainingText(_ duration: Duration) -> String {
        let parts = Parts(duration)
        guard parts.totalMinutes > 0 else { return "0 minutes" }

        var spoken: [String] = []
        if parts.days > 0 { spoken.append(pluralized(parts.days, "day")) }
        if parts.hours > 0 { spoken.append(pluralized(parts.hours, "hour")) }
        if parts.minutes > 0 || spoken.isEmpty { spoken.append(pluralized(parts.minutes, "minute")) }
        return spoken.joined(separator: " ")
    }

    /// "resets in 2h 43m" for a near-term reset, "resets Monday" once it is
    /// far enough out that a weekday reads more naturally than a countdown.
    public static func resetText(for period: UsagePeriodType, resetDate: Date, now: Date = .now) -> String {
        let interval = resetDate.timeIntervalSince(now)
        guard interval > 0 else { return "resets shortly" }

        let isLongWindow = period == .weekly || period == .monthly
        guard isLongWindow, interval >= 24 * 3600 else {
            return "resets in \(remainingText(.seconds(interval)))"
        }

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(interval < 6 * 24 * 3600 ? "EEEE" : "EEEE d MMM")
        return "resets \(formatter.string(from: resetDate))"
    }

    /// "updated 12m ago", for the secondary line shown on stale data.
    public static func updatedAgoText(_ date: Date, now: Date = .now) -> String {
        let minutes = Int(max(now.timeIntervalSince(date), 0) / 60)
        if minutes < 1 { return "updated just now" }
        if minutes < 60 { return "updated \(minutes)m ago" }
        return "updated \(minutes / 60)h ago"
    }

    /// Whole-minute decomposition shared by the compact and spoken forms, so
    /// the two can never disagree about how a duration breaks down.
    private struct Parts {
        let totalMinutes: Int
        let days: Int
        let hours: Int
        let minutes: Int

        init(_ duration: Duration) {
            totalMinutes = max(Int(duration.secondsDouble / 60), 0)
            days = totalMinutes / (24 * 60)
            hours = (totalMinutes % (24 * 60)) / 60
            minutes = totalMinutes % 60
        }
    }

    private static func pluralized(_ count: Int, _ unit: String) -> String {
        "\(count) \(unit)\(count == 1 ? "" : "s")"
    }
}
