import Foundation
import OrbitCore

/// Parses the text Claude Code's `/usage` command prints.
///
/// Kept entirely separate from process execution so every format quirk —
/// progress-bar glyphs, ANSI colouring, a same-day versus dated reset, a
/// missing quota section — is testable against fixture strings without
/// spawning anything.
///
/// Two shapes appear, and both must parse, because which one the CLI prints
/// depends on whether stdout is a terminal:
///
/// - **Interactive (TUI).** A header line, a progress bar, a reset line:
///
///   ```text
///   Current session
///   ███                                                6% used
///   Resets 8:40pm (Asia/Calcutta)
///
///   Current week (all models)
///   ████████████▌                                      25% used
///   Resets Sep 21 at 1:30am (Asia/Calcutta)
///   ```
///
/// - **Piped.** One line per quota, label and values separated by a colon and
///   a `·`. This is what the app actually receives — it always runs the CLI
///   with piped stdout — so it is the shape that matters most:
///
///   ```text
///   Current session: 59% used · resets Sep 17 at 8:40pm (Asia/Calcutta)
///   Current week (all models): 32% used · resets Sep 21 at 1:30am (Asia/Calcutta)
///   ```
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

                // The piped form puts everything on the header line. Take the
                // percent and reset from it directly; if either is absent this
                // is the multi-line form and the next lines supply them.
                if let percent = percentUsed(in: trimmed) {
                    pendingPercent = percent
                    if let resetText = resetClause(in: trimmed) {
                        try finishSection(resetDate: ClaudeResetDateParser.date(from: resetText, now: now))
                    }
                }
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
        // In the piped form the header is a label followed by a colon and the
        // values; the label alone is what identifies the quota. Splitting here
        // also keeps the timezone's "(Asia/Calcutta)" out of the model lookup
        // below.
        let label = line.split(separator: ":", maxSplits: 1).first.map(String.init) ?? line
        let lowered = label.lowercased()
        guard lowered.hasPrefix("current ") else { return nil }

        if lowered.hasPrefix("current session") { return .session }
        guard lowered.hasPrefix("current week") else { return nil }

        // "Current week (all models)" is the overall weekly cap; anything
        // else in parentheses is a model-specific one.
        if let parenthesized = label.firstMatch(of: #"\(([^)]*)\)"#, group: 1) {
            let model = parenthesized.trimmingCharacters(in: .whitespaces)
            if model.lowercased() != "all models" {
                return .modelWeekly(model)
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

    /// The reset clause, from either shape:
    ///
    /// ```text
    /// Resets 8:40pm (Asia/Calcutta)                   -> 8:40pm (Asia/Calcutta)
    /// ... 59% used · resets Sep 17 at 8:40pm (…)      -> Sep 17 at 8:40pm (…)
    /// ```
    ///
    /// "resets" is matched either at the start of the line or after the `·`
    /// separator, rather than anywhere, so a sentence that merely mentions the
    /// word cannot be read as a reset time.
    private static func resetClause(in line: String) -> String? {
        line.firstMatch(of: #"(?i)(?:^|·\s*)resets\s+(.+)$"#, group: 1)?
            .trimmingCharacters(in: .whitespaces)
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
