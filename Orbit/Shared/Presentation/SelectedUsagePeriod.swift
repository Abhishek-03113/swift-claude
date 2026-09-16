import Foundation

/// Which quota is currently focused at the center of the dial. This is the
/// entire interactive state of the widget — nothing else needs to vary.
public enum SelectedUsagePeriod: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case session
    case weekly

    public var periodType: UsagePeriodType {
        switch self {
        case .session: return .session
        case .weekly: return .weekly
        }
    }

    public var toggled: SelectedUsagePeriod {
        switch self {
        case .session: return .weekly
        case .weekly: return .session
        }
    }
}
