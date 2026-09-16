import Foundation

/// Text formatting for the dial's center content and reset metadata. Pulled
/// out of the views so it's independently testable (short/long durations,
/// exhausted state, weekly weekday naming) without rendering anything.
public enum UsageFormatting {
    /// "2h 17m", "2d 8h", "45m", or "0m" once exhausted. Never negative,
    /// never a fractional/garbled unit.
    public static func remainingText(_ duration: Duration) -> String {
        let totalSeconds = max(duration.secondsDouble, 0)
        let totalMinutes = Int(totalSeconds / 60)

        if totalMinutes <= 0 {
            return "0m"
        }

        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// "resets in 2h 43m" for a near-term reset, "resets Monday" once it's
    /// far enough out that a weekday reads more naturally than a countdown.
    public static func resetText(for period: UsagePeriodType, resetDate: Date, now: Date = .now) -> String {
        let interval = resetDate.timeIntervalSince(now)
        guard interval > 0 else { return "resets shortly" }

        switch period {
        case .session, .daily, .custom:
            return "resets in \(remainingText(.seconds(interval)))"
        case .weekly, .monthly:
            if interval < 24 * 3600 {
                return "resets in \(remainingText(.seconds(interval)))"
            }
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate(interval < 6 * 24 * 3600 ? "EEEE" : "EEEE d MMM")
            return "resets \(formatter.string(from: resetDate))"
        }
    }

    /// Fully-spelled-out duration for VoiceOver, e.g. "2 hours 43 minutes",
    /// so accessibility never relies on the visually-compact "2h 43m" form.
    public static func spokenRemainingText(_ duration: Duration) -> String {
        let totalMinutes = max(Int(duration.secondsDouble / 60), 0)
        if totalMinutes <= 0 { return "0 minutes" }

        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days) \(days == 1 ? "day" : "days")") }
        if hours > 0 { parts.append("\(hours) \(hours == 1 ? "hour" : "hours")") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")") }
        return parts.joined(separator: " ")
    }

    /// "updated 12m ago" for the stale-data secondary line.
    public static func updatedAgoText(_ date: Date, now: Date = .now) -> String {
        let interval = max(now.timeIntervalSince(date), 0)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "updated just now" }
        if minutes < 60 { return "updated \(minutes)m ago" }
        let hours = minutes / 60
        return "updated \(hours)h ago"
    }
}
