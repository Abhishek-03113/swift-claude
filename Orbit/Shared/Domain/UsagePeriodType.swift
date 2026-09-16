import Foundation

/// The kind of quota window a provider tracks. New providers may introduce
/// new period types without touching any generic UI code.
public enum UsagePeriodType: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case session
    case weekly
    case daily
    case monthly
    case custom
}
