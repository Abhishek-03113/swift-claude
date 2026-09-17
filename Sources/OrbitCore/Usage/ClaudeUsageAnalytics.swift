import Foundation

/// The extra detail `/api/oauth/usage` returns beyond the session/weekly
/// periods already captured as `UsagePeriod` — kept as its own optional
/// payload so widgets that want it can add themselves later without another
/// client or model change. Absent (`nil`) for readings that came from the
/// CLI text fallback, which cannot produce any of this.
public struct ClaudeUsageAnalytics: Equatable, Sendable, Codable {
    /// Usage-credit overage plan, when the account has one enabled.
    public struct ExtraUsage: Equatable, Sendable, Codable {
        public let isEnabled: Bool
        public let monthlyLimit: Double
        public let usedCredits: Double
        public let utilization: Double?
        public let currency: String

        public init(isEnabled: Bool, monthlyLimit: Double, usedCredits: Double, utilization: Double?, currency: String) {
            self.isEnabled = isEnabled
            self.monthlyLimit = monthlyLimit
            self.usedCredits = usedCredits
            self.utilization = utilization
            self.currency = currency
        }
    }

    /// One row of the "what's contributing to your usage" 7-day surface
    /// breakdown (Claude Code, Chats, Cowork, Other, ...).
    public struct SurfaceShare: Equatable, Sendable, Codable, Identifiable {
        public let id: String
        public let displayName: String
        public let percent: Double

        public init(id: String, displayName: String, percent: Double) {
            self.id = id
            self.displayName = displayName
            self.percent = percent
        }
    }

    public let extraUsage: ExtraUsage?
    public let sevenDayBreakdown: [SurfaceShare]
    public let generatedAt: Date

    public init(extraUsage: ExtraUsage?, sevenDayBreakdown: [SurfaceShare], generatedAt: Date) {
        self.extraUsage = extraUsage
        self.sevenDayBreakdown = sevenDayBreakdown
        self.generatedAt = generatedAt
    }
}
