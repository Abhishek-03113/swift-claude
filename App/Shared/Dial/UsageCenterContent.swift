import OrbitCore
import OrbitPresentation
import SwiftUI

/// The dial's optical center: the primary remaining-quota value, the period
/// label, and — where there is room — the reset line. The single most
/// important view in the widget; everything else is context around it.
///
/// The core is a circle, so its usable text width is narrower than its
/// diameter. Lines are laid out against that inscribed width and the layout
/// decides how many of them appear at all, rather than every size trying to
/// show four lines and letting the short ones truncate.
struct UsageCenterContent: View {
    let presentation: DialPresentation
    let diameter: CGFloat
    let detail: DialLayout.CenterDetail

    /// Width of the square that fits inside the core circle, minus a hair of
    /// breathing room. Text wider than this collides with the rim.
    private var usableWidth: CGFloat { diameter * 0.74 }

    private var showsPeriodLabel: Bool { detail != .value }
    private var showsTimeRemaining: Bool { detail == .timed || detail == .full }
    private var showsResetLine: Bool { detail == .full }

    /// The value shrinks as more lines stack under it, so the block as a whole
    /// stays inside the core instead of the first line claiming the space.
    private var valueSize: CGFloat {
        switch detail {
        case .value: return diameter * 0.34
        case .labelled: return diameter * 0.30
        case .timed: return diameter * 0.26
        case .full: return diameter * 0.23
        }
    }

    /// 9pt is the floor below which the label stops being readable at a
    /// glance; the cap keeps it from growing into the value's territory on the
    /// large widget, where the core has room to spare.
    private var labelSize: CGFloat { min(max(diameter * 0.085, 9), 13) }
    private var metadataSize: CGFloat { min(max(diameter * 0.075, 9), 12) }

    var body: some View {
        VStack(spacing: diameter * 0.015) {
            RemainingPercentText(percent: presentation.focusRemainingPercent, size: valueSize)
                .foregroundStyle(.white)

            if showsPeriodLabel {
                Text(presentation.focusPeriodLabel)
                    .font(UsageTypography.periodLabel(size: labelSize))
                    // Tracking is what pushes "WEEKLY" past the core's width at
                    // small diameters; it scales with the text rather than
                    // staying at its display-size value.
                    .tracking(UsageTypography.periodLabelTracking(forSize: labelSize))
                    .foregroundStyle(Color(presentation.focusColor))
                    .padding(.top, diameter * 0.02)
            }

            if showsTimeRemaining {
                Text("\(UsageFormatting.durationText(presentation.focusTimeUntilReset)) left")
                    .font(UsageTypography.metadata(size: metadataSize))
                    .foregroundStyle(.white.opacity(UsageOpacity.secondary))
            }

            if showsResetLine {
                // Staleness displaces the reset line: knowing the number is
                // old matters more than knowing when it would have reset.
                Text(presentation.lastUpdatedText ?? presentation.focusResetText)
                    .font(UsageTypography.metadata(size: metadataSize * 0.88))
                    .foregroundStyle(.white.opacity(UsageOpacity.secondary))
            }
        }
        .lineLimit(1)
        // Lets a long line give up a little size rather than truncating to an
        // ellipsis, which is what produced "WEE…" and "3d 7h…".
        .minimumScaleFactor(0.55)
        .frame(width: usableWidth)
        .multilineTextAlignment(.center)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .id(presentation.selected) // drives the cross-fade between session and weekly
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Spoken in full regardless of how many lines are drawn, so the smaller
    /// sizes lose visual detail without losing information.
    private var accessibilityLabel: String {
        [
            "\(presentation.focusRemainingPercent) percent remaining",
            presentation.focusPeriodLabel,
            "\(UsageFormatting.durationText(presentation.focusTimeUntilReset)) left",
            presentation.lastUpdatedText ?? presentation.focusResetText,
        ].joined(separator: ", ")
    }
}

/// Renders the dominant remaining-quota value as "68%", with the percent
/// sign set smaller and baseline-aligned per the design's typography.
private struct RemainingPercentText: View {
    let percent: Int
    let size: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.03) {
            Text("\(percent)")
                .font(UsageTypography.primaryValue(size: size))
                // Rolls the digits rather than swapping them, so the number
                // settles with the sweep instead of snapping ahead of it.
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.5), value: percent)
            Text("%")
                .font(UsageTypography.primaryValue(size: size * 0.42))
        }
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
}
