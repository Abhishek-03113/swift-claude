import Foundation

/// Raw shape of a Claude Code usage reading, before normalization into the
/// generic `UsageSnapshot`. This is intentionally the *only* place that
/// knows Claude Code's field names — everything downstream of
/// `ClaudeCodeProvider.normalize(_:)` is provider-agnostic.
struct ClaudeCodeUsageDTO: Decodable {
    struct Period: Decodable {
        let usedSeconds: Double
        let limitSeconds: Double
        let resetsAt: Date
    }
    let session: Period
    let weekly: Period
    let generatedAt: Date
}

enum ClaudeCodeUsageParsing {
    /// Turns a raw DTO into a `UsageSnapshot`, rejecting values that would
    /// otherwise silently corrupt the dial (negative durations, a
    /// zero/negative limit, a reset date that isn't actually in the
    /// future relative to `generatedAt`).
    static func normalize(_ dto: ClaudeCodeUsageDTO) throws -> UsageSnapshot {
        func period(_ raw: ClaudeCodeUsageDTO.Period, id: String, type: UsagePeriodType) throws -> UsagePeriod {
            guard raw.limitSeconds > 0 else {
                throw UsageRepositoryError.malformedResponse("\(id): limitSeconds must be positive")
            }
            guard raw.usedSeconds.isFinite, raw.usedSeconds >= 0 else {
                throw UsageRepositoryError.malformedResponse("\(id): usedSeconds must be a non-negative number")
            }
            return UsagePeriod(
                id: id,
                type: type,
                used: .seconds(raw.usedSeconds),
                limit: .seconds(raw.limitSeconds),
                resetDate: raw.resetsAt
            )
        }

        let session = try period(dto.session, id: "session", type: .session)
        let weekly = try period(dto.weekly, id: "weekly", type: .weekly)

        return UsageSnapshot(provider: .claudeCode, periods: [session, weekly], lastUpdated: dto.generatedAt)
    }
}
