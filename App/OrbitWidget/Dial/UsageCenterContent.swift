import OrbitCore
import OrbitPresentation
import SwiftUI

/// The dial's optical center: the primary remaining-quota value, the period
/// label, and — where there is room — the reset line. The single most
/// important view in the widget; everything else is context around it.
struct UsageCenterContent: View {
    let presentation: DialPresentation
    let diameter: CGFloat
    let showsResetLine: Bool

    var body: some View {
        VStack(spacing: diameter * 0.01) {
            RemainingPercentText(percent: presentation.focusRemainingPercent, size: diameter * 0.24)
                .foregroundStyle(.white)

            Text(presentation.focusPeriodLabel)
                .font(UsageTypography.periodLabel(size: max(diameter * 0.05, 8)))
                .tracking(UsageTypography.periodLabelTracking)
                .foregroundStyle(Color(presentation.focusColor))
                .padding(.top, diameter * 0.02)

            Text("\(UsageFormatting.durationText(presentation.focusTimeUntilReset)) left")
                .font(UsageTypography.metadata(size: max(diameter * 0.06, 8)))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
                .padding(.top, 1)

            if showsResetLine {
                // Staleness displaces the reset line: knowing the number is
                // old matters more than knowing when it would have reset.
                Text(presentation.lastUpdatedText ?? presentation.focusResetText)
                    .font(UsageTypography.metadata(size: max(diameter * 0.045, 8)))
                    .foregroundStyle(.white.opacity(UsageOpacity.secondary))
                    .padding(.top, 1)
            }
        }
        .multilineTextAlignment(.center)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .id(presentation.selected) // drives the cross-fade between session and weekly
        .accessibilityElement(children: .combine)
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
            Text("%")
                .font(UsageTypography.primaryValue(size: size * 0.42))
        }
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
}
