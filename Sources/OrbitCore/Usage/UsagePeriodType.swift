import Foundation

/// The kind of quota window a provider tracks. New providers may add period
/// types without any generic UI code changing.
public enum UsagePeriodType: String, Codable, Sendable, CaseIterable, Hashable {
    case session
    case weekly
    case daily
    case monthly
    case custom
}
