import Foundation
import OrbitCore

/// Turns Claude Code's raw reading into the provider-agnostic model. The last
/// point at which Claude-specific vocabulary exists.
public enum ClaudeCodeUsageParsing {
    /// Rejects values that would otherwise silently corrupt the dial: a
    /// non-positive limit, or a negative/non-finite used count.
    public static func normalize(_ dto: ClaudeCodeUsageDTO) throws -> UsageSnapshot {
        let session = try period(dto.session, id: "session", type: .session)
        let weekly = try period(dto.weekly, id: "weekly", type: .weekly)

        return UsageSnapshot(
            provider: .claudeCode,
            periods: [session, weekly],
            lastUpdated: dto.generatedAt
        )
    }

    private static func period(
        _ raw: ClaudeCodeUsageDTO.Period,
        id: String,
        type: UsagePeriodType
    ) throws -> UsagePeriod {
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
}
