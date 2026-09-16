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
            RemainingValueText(
                remaining: presentation.focusRemaining,
                resetDate: presentation.focusResetDate,
                size: diameter * 0.19
            )
            .foregroundStyle(.white)

            Text(presentation.focusPeriodLabel)
                .font(UsageTypography.periodLabel(size: max(diameter * 0.05, 8)))
                .tracking(UsageTypography.periodLabelTracking)
                .foregroundStyle(Color(presentation.focusColor))
                .padding(.top, diameter * 0.02)

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

/// Renders the remaining-time value.
///
/// Uses `Text(timerInterval:)` — the system-managed live countdown — so the
/// value ticks without the widget rebuilding on a per-second timer. Falls
/// back to a static string once the window has reset or has nothing left to
/// count down.
private struct RemainingValueText: View {
    let remaining: Duration
    let resetDate: Date
    let size: CGFloat

    var body: some View {
        Group {
            if resetDate > .now, remaining.secondsDouble > 0 {
                Text(timerInterval: Date.now...resetDate, countsDown: true)
            } else {
                Text(UsageFormatting.remainingText(remaining))
            }
        }
        .font(UsageTypography.primaryValue(size: size))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
}
