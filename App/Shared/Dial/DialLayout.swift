import CoreGraphics

/// What the surrounding context has room to show. The dial's own geometry is
/// identical at every size (see `DialMetrics`) — this only decides which
/// elements appear around it.
///
/// Deliberately free of WidgetKit so the app can use the same dial; the
/// widget maps `WidgetFamily` onto these presets in its own target.
struct DialLayout: Equatable {
    /// How much the dial's core can say. The core is only ~47% of the dial,
    /// so at small diameters it cannot hold four lines legibly — the text
    /// clips rather than shrinking gracefully. Each preset names the most it
    /// can carry, and `UsageCenterContent` renders exactly that.
    enum CenterDetail {
        /// Value only. Everything else moves outside the dial.
        case value
        /// Value plus the period label.
        case labelled
        /// Value, period label, and time remaining.
        case timed
        /// Everything, including the reset line.
        case full
    }

    let showsProviderBadge: Bool
    let centerDetail: CenterDetail
    let showsSecondaryPeriodLabel: Bool
    /// Dial diameter as a fraction of the container's shortest side.
    let dialDiameterFraction: CGFloat

    /// Just the instrument and its value — the small widget. The core is too
    /// small here for the reset line, and the time-remaining line reads only
    /// because nothing else competes with it.
    static let compact = DialLayout(
        showsProviderBadge: false,
        centerDetail: .timed,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.96
    )

    /// The wide medium widget, where the dial sits beside its details rather
    /// than above them. The core carries the value and its label; the reset
    /// line and provider identity live in the column next to the dial, which
    /// is the space the vertical stack was wasting.
    static let split = DialLayout(
        showsProviderBadge: true,
        centerDetail: .labelled,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.98
    )

    /// Adds provider identity and the reset line — a tall, narrow context.
    static let standard = DialLayout(
        showsProviderBadge: true,
        centerDetail: .timed,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.86
    )

    /// Everything, with room to breathe — the large widget and the app.
    static let expanded = DialLayout(
        showsProviderBadge: true,
        centerDetail: .full,
        showsSecondaryPeriodLabel: true,
        dialDiameterFraction: 0.78
    )

    /// The app's hero dial: the instrument reads on its own there, with
    /// provider identity and reset details spelled out in the surrounding
    /// layout rather than crowded inside the ring.
    static let app = DialLayout(
        showsProviderBadge: false,
        centerDetail: .full,
        showsSecondaryPeriodLabel: false,
        dialDiameterFraction: 0.86
    )
}
