import Foundation

/// Deterministic mock data for previews, tests, and the widget's loading
/// placeholder. Not a `UsageRepository` conformer with network-style
/// failure modes — just a snapshot factory, since previews never need to
/// exercise the error path.
public enum MockUsageProvider {
    public static func snapshot(
        sessionUsedFraction: Double = 0.32,
        weeklyUsedFraction: Double = 0.59,
        now: Date = .now
    ) -> UsageSnapshot {
        let sessionLimit = Duration.seconds(5 * 3600)
        let weeklyLimit = Duration.seconds(7 * 24 * 3600)

        let session = UsagePeriod(
            id: "session",
            type: .session,
            used: .seconds(sessionLimit.secondsDouble * sessionUsedFraction),
            limit: sessionLimit,
            resetDate: now.addingTimeInterval(sessionLimit.secondsDouble * (1 - sessionUsedFraction))
        )
        let weekly = UsagePeriod(
            id: "weekly",
            type: .weekly,
            used: .seconds(weeklyLimit.secondsDouble * weeklyUsedFraction),
            limit: weeklyLimit,
            resetDate: nextMonday9am(from: now)
        )

        return UsageSnapshot(provider: .claudeCode, periods: [session, weekly], lastUpdated: now)
    }

    private static func nextMonday9am(from date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var components = DateComponents()
        components.weekday = 2 // Monday
        components.hour = 9
        return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime) ?? date.addingTimeInterval(7 * 24 * 3600)
    }
}
