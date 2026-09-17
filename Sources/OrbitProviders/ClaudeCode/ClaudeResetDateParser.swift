import Foundation
import OrbitCore

/// Turns the reset clause of `claude /usage` into an absolute `Date`.
///
/// Two shapes appear, depending on how far out the reset is:
///
/// ```text
/// 8:40pm (Asia/Calcutta)              // later today, or tomorrow
/// Sep 21 at 1:30am (Asia/Calcutta)    // a dated reset, no year given
/// ```
///
/// Neither carries a year, and the time-only form carries no date at all, so
/// both are resolved relative to `now` in the timezone the output names.
enum ClaudeResetDateParser {
    static func date(from clause: String, now: Date) throws -> Date {
        let (body, timeZone) = splitTimeZone(from: clause)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        if let dated = datedReset(body, calendar: calendar, timeZone: timeZone, now: now) {
            return dated
        }
        if let sameDay = timeOnlyReset(body, calendar: calendar, timeZone: timeZone, now: now) {
            return sameDay
        }

        throw UsageRepositoryError.malformedResponse("Unrecognized reset time: \"\(clause)\"")
    }

    /// Trailing "(Asia/Calcutta)" names the timezone the times are given in.
    /// An unparseable or absent identifier falls back to the current one,
    /// which is the machine that ran the command.
    private static func splitTimeZone(from clause: String) -> (body: String, timeZone: TimeZone) {
        guard let open = clause.lastIndex(of: "("), let close = clause.lastIndex(of: ")"), open < close else {
            return (clause.trimmingCharacters(in: .whitespaces), .current)
        }

        let identifier = String(clause[clause.index(after: open)..<close]).trimmingCharacters(in: .whitespaces)
        let body = String(clause[clause.startIndex..<open]).trimmingCharacters(in: .whitespaces)
        return (body, TimeZone(identifier: identifier) ?? .current)
    }

    /// "Sep 21 at 1:30am" — no year, so assume the next occurrence.
    private static func datedReset(_ body: String, calendar: Calendar, timeZone: TimeZone, now: Date) -> Date? {
        let normalized = normalize(body)
        let year = calendar.component(.year, from: now)

        for format in ["MMM d 'AT' h:mma", "MMM d 'AT' HH:mm", "MMM d h:mma", "MMM d HH:mm"] {
            let formatter = formatter(format: "\(format) yyyy", timeZone: timeZone)
            guard let parsed = formatter.date(from: "\(normalized) \(year)") else { continue }

            // A date that already passed means the output wrapped into next
            // year (a late-December reading resetting in January).
            if parsed.timeIntervalSince(now) < -24 * 3600,
               let nextYear = formatter.date(from: "\(normalized) \(year + 1)") {
                return nextYear
            }
            return parsed
        }
        return nil
    }

    /// "8:40pm" — today if that is still ahead, otherwise tomorrow.
    private static func timeOnlyReset(_ body: String, calendar: Calendar, timeZone: TimeZone, now: Date) -> Date? {
        let normalized = normalize(body)

        for format in ["h:mma", "HH:mm"] {
            let formatter = formatter(format: format, timeZone: timeZone)
            guard let timeOfDay = formatter.date(from: normalized) else { continue }

            let time = calendar.dateComponents([.hour, .minute], from: timeOfDay)
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = time.hour
            components.minute = time.minute
            components.second = 0

            guard let candidate = calendar.date(from: components) else { continue }
            if candidate <= now, let tomorrow = calendar.date(byAdding: .day, value: 1, to: candidate) {
                return tomorrow
            }
            return candidate
        }
        return nil
    }

    /// The CLI prints "8:40pm"; `DateFormatter`'s POSIX locale expects "PM".
    /// Only the am/pm and "at" tokens are uppercased — the month name is left
    /// alone, since POSIX month symbols are "Sep", not "SEP".
    private static func normalize(_ body: String) -> String {
        // No month abbreviation contains "am", "pm" or "at", so these plain
        // replacements cannot corrupt the date portion.
        body
            .replacingOccurrences(of: "am", with: "AM", options: .caseInsensitive)
            .replacingOccurrences(of: "pm", with: "PM", options: .caseInsensitive)
            .replacingOccurrences(of: "at", with: "AT", options: .caseInsensitive)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func formatter(format: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }
}
