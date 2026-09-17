import Foundation
import OrbitCore

/// Parses the text Claude Code's `/usage` command prints.
///
/// Kept entirely separate from process execution so every format quirk —
/// progress-bar glyphs, ANSI colouring, a same-day versus dated reset, a
/// missing quota section — is testable against fixture strings without
/// spawning anything.
///
/// The shape it reads:
///
/// ```text
/// Current session
/// ███                                                6% used
/// Resets 8:40pm (Asia/Calcutta)
///
/// Current week (all models)
/// ████████████▌                                      25% used
/// Resets Sep 21 at 1:30am (Asia/Calcutta)
/// ```
public enum ClaudeUsageTextParser {
    /// A quota section recognized in the output.
    enum Section {
        case session
        case weekly
        /// "Current week (Opus)" and friends — a model-specific weekly cap,
        /// carried through as an extra period rather than discarded.
        case modelWeekly(String)
    }

    public static func parse(_ text: String, now: Date = .now) throws -> ClaudeCodeUsageReading {
        let lines = stripANSI(text).components(separatedBy: .newlines)

        var periods: [UsagePeriod] = []
        var current: Section?
        var pendingPercent: Double?

        func finishSection(resetDate: Date) throws {
            guard let section = current, let percent = pendingPercent else { return }

            switch section {
            case .session:
                periods.append(UsagePeriod(id: "session", type: .session, usedFraction: percent / 100, resetDate: resetDate))
            case .weekly:
                periods.append(UsagePeriod(id: "weekly", type: .weekly, usedFraction: percent / 100, resetDate: resetDate))
            case .modelWeekly(let model):
                periods.append(UsagePeriod(id: "weekly-\(model.lowercased())", type: .custom, usedFraction: percent / 100, resetDate: resetDate))
            }

            current = nil
            pendingPercent = nil
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if let section = section(for: trimmed) {
                current = section
                pendingPercent = nil
                continue
            }

            guard current != nil else { continue }

            if let percent = percentUsed(in: trimmed) {
                pendingPercent = percent
                continue
            }

            if let resetText = resetClause(in: trimmed) {
                let resetDate = try ClaudeResetDateParser.date(from: resetText, now: now)
                try finishSection(resetDate: resetDate)
            }
        }

        guard periods.contains(where: { $0.type == .session }),
              periods.contains(where: { $0.type == .weekly }) else {
            throw UsageRepositoryError.malformedResponse(
                """
                No usage limits found in `claude /usage` output. Claude Code only \
                reports session and weekly limits for subscription accounts; an \
                API-key login prints cost totals with no quota section.
                """
            )
        }

        return ClaudeCodeUsageReading(periods: periods, generatedAt: now)
    }

    private static func section(for line: String) -> Section? {
        let lowered = line.lowercased()
        guard lowered.hasPrefix("current ") else { return nil }

        if lowered.hasPrefix("current session") { return .session }
        guard lowered.hasPrefix("current week") else { return nil }

        // "Current week (all models)" is the overall weekly cap; anything
        // else in parentheses is a model-specific one.
        if let parenthesized = line.firstMatch(of: #"\(([^)]*)\)"#, group: 1) {
            let label = parenthesized.trimmingCharacters(in: .whitespaces)
            if label.lowercased() != "all models" {
                return .modelWeekly(label)
            }
        }
        return .weekly
    }

    /// "███   6% used" -> 6. Progress-bar glyphs are ignored: the percentage
    /// is authoritative and the bar is only a redrawing of it.
    private static func percentUsed(in line: String) -> Double? {
        guard let match = line.firstMatch(of: #"([0-9]+(?:\.[0-9]+)?)\s*%\s+used"#, group: 1) else { return nil }
        return Double(match)
    }

    /// "Resets 8:40pm (Asia/Calcutta)" -> "8:40pm (Asia/Calcutta)".
    private static func resetClause(in line: String) -> String? {
        line.firstMatch(of: #"(?i)^resets\s+(.+)$"#, group: 1)
    }

    /// Claude Code omits ANSI styling when stdout is a pipe, but strip it
    /// anyway so output captured from a PTY parses identically.
    static func stripANSI(_ text: String) -> String {
        text.replacingOccurrences(
            of: "\u{001B}\\[[0-9;?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
    }
}

private extension String {
    /// First capture group of `pattern`, or nil. `NSRegularExpression` rather
    /// than a `Regex` literal so the package keeps building on Linux, where
    /// `swift test` runs.
    func firstMatch(of pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range),
              let captured = Range(match.range(at: group), in: self) else {
            return nil
        }
        return String(self[captured])
    }
}
