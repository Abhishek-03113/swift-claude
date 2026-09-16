import Foundation

/// Raw shape of a Claude Code usage reading, before normalization into the
/// generic `UsageSnapshot`. This is deliberately the only type that knows
/// Claude Code's field names.
public struct ClaudeCodeUsageDTO: Decodable, Equatable, Sendable {
    public struct Period: Decodable, Equatable, Sendable {
        public let usedSeconds: Double
        public let limitSeconds: Double
        public let resetsAt: Date

        public init(usedSeconds: Double, limitSeconds: Double, resetsAt: Date) {
            self.usedSeconds = usedSeconds
            self.limitSeconds = limitSeconds
            self.resetsAt = resetsAt
        }
    }

    public let session: Period
    public let weekly: Period
    public let generatedAt: Date

    public init(session: Period, weekly: Period, generatedAt: Date) {
        self.session = session
        self.weekly = weekly
        self.generatedAt = generatedAt
    }
}
