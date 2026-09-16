import WidgetKit
import CoreGraphics

/// What a given widget family has room to show. The dial's own geometry is
/// always identical (see `DialMetrics`) — this only decides which
/// surrounding elements appear, per the spec's responsive-design section.
public struct DialLayout: Equatable {
    public let showsProviderBadge: Bool
    public let showsResetLine: Bool
    public let showsSecondaryPeriodLabel: Bool
    public let dialDiameterFraction: CGFloat // fraction of the shortest side

    public static func layout(for family: WidgetFamily) -> DialLayout {
        switch family {
        case .systemSmall:
            return DialLayout(
                showsProviderBadge: false,
                showsResetLine: false,
                showsSecondaryPeriodLabel: false,
                dialDiameterFraction: 0.92
            )
        case .systemLarge, .systemExtraLarge:
            return DialLayout(
                showsProviderBadge: true,
                showsResetLine: true,
                showsSecondaryPeriodLabel: true,
                dialDiameterFraction: 0.72
            )
        case .systemMedium:
            fallthrough
        default:
            return DialLayout(
                showsProviderBadge: true,
                showsResetLine: true,
                showsSecondaryPeriodLabel: false,
                dialDiameterFraction: 0.82
            )
        }
    }
}
