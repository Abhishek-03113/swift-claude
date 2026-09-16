import Foundation
import OrbitCore

/// Snapshot fixtures for the core tests. Deliberately local rather than
/// reusing `MockUsageProvider`, so `OrbitCore` keeps no dependency — even a
/// test-only one — on the provider layer above it.
enum UsageFixtures {
    static func period(
        id: String = "session",
        type: UsagePeriodType = .session,
        used: Double,
        limit: Double
    ) -> UsagePeriod {
        UsagePeriod(
            id: id,
            type: type,
            used: .seconds(used),
            limit: .seconds(limit),
            resetDate: Date(timeIntervalSince1970: 1_000_000).addingTimeInterval(limit - used)
        )
    }

    static func snapshot(now: Date = Date(timeIntervalSince1970: 1_000_000)) -> UsageSnapshot {
        UsageSnapshot(
            provider: .claudeCode,
            periods: [
                period(id: "session", type: .session, used: 5_760, limit: 18_000),
                period(id: "weekly", type: .weekly, used: 356_400, limit: 604_800),
            ],
            lastUpdated: now
        )
    }
}
