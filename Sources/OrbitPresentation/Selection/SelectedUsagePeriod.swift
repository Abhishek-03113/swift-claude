import Foundation

/// Which quota is focused at the center of the dial. This is the widget's
/// entire interactive state — nothing else varies with user input.
///
/// A separate type from `UsagePeriodType`: that enum describes every window a
/// provider might report, while this is the strictly two-way choice the dial
/// offers.
public enum SelectedUsagePeriod: String, Codable, Sendable, CaseIterable, Hashable {
    case session
    case weekly
}
