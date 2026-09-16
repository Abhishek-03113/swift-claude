import CoreGraphics
import WidgetKit

/// What a given widget family has room to show. The dial's own geometry is
/// identical at every size (see `DialMetrics`) — this only decides which
/// surrounding elements appear.
struct DialLayout: Equatable {
    let showsProviderBadge: Bool
    let showsResetLine: Bool
    let showsSecondaryPeriodLabel: Bool
    /// Dial diameter as a fraction of the container's shortest side.
    let dialDiameterFraction: CGFloat

    static func layout(for family: WidgetFamily) -> DialLayout {
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
