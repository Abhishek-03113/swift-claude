import CoreGraphics

/// What the surrounding context has room to show. The dial's own geometry is
/// identical at every size (see `DialMetrics`) — this only decides which
/// elements appear around it.
///
/// Deliberately free of WidgetKit so the app can use the same dial; the
/// widget maps `WidgetFamily` onto these presets in its own target.
struct DialLayout: Equatable {
    let showsProviderBadge: Bool
    let showsResetLine: Bool
    let showsSecondaryPeriodLabel: Bool
    /// Dial diameter as a fraction of the container's shortest side.
    let dialDiameterFraction: CGFloat

    /// Just the instrument and its value — the small widget.
    static let compact = DialLayout(
        showsProviderBadge: false,
        showsResetLine: false,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.92
    )

    /// Adds provider identity and the reset line — the medium widget.
    static let standard = DialLayout(
        showsProviderBadge: true,
        showsResetLine: true,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.82
    )

    /// Everything, with room to breathe — the large widget and the app.
    static let expanded = DialLayout(
        showsProviderBadge: true,
        showsResetLine: true,
        showsSecondaryPeriodLabel: true,
        dialDiameterFraction: 0.72
    )

    /// The app's hero dial: the instrument reads on its own there, with
    /// provider identity and reset details spelled out in the surrounding
    /// layout rather than crowded inside the ring.
    static let app = DialLayout(
        showsProviderBadge: false,
        showsResetLine: true,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.86
    )
}
