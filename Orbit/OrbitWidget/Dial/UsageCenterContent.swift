import SwiftUI

/// The dial's optical center: the primary remaining-quota value, the period
/// label, and (when there's room) the reset line. This is the single most
/// important view in the widget — everything else is context around it.
struct UsageCenterContent: View {
    let presentation: DialPresentation
    let diameter: CGFloat
    let showsResetLine: Bool

    var body: some View {
        let valueSize = diameter * 0.19
        let labelSize = max(diameter * 0.05, 8)
        let metaSize = max(diameter * 0.045, 8)
        let focusColor = Color(presentation.focusColor)

        VStack(spacing: diameter * 0.01) {
            RemainingValueText(remaining: presentation.focusRemaining, resetDate: presentation.focusResetDate, size: valueSize)
                .foregroundStyle(.white)

            Text(presentation.focusPeriodLabel)
                .font(UsageTypography.periodLabel(size: labelSize))
                .tracking(UsageTypography.periodLabelTracking)
                .foregroundStyle(focusColor)
                .padding(.top, diameter * 0.02)

            if showsResetLine {
                Text(presentation.lastUpdatedText ?? presentation.focusResetText)
                    .font(UsageTypography.metadata(size: metaSize))
                    .foregroundStyle(.white.opacity(UsageOpacity.secondary))
                    .padding(.top, 1)
            }
        }
        .multilineTextAlignment(.center)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .id(presentation.selected) // drives the cross-fade between session/weekly
        .accessibilityElement(children: .combine)
    }
}

/// Renders the remaining-time value. Uses `Text(timerInterval:)` — the
/// system-managed live countdown API — so the number ticks forward without
/// the widget rebuilding on a per-second timer, per the spec's guidance to
/// prefer a system-supported relative-date representation over a manual
/// refresh loop. Falls back to a static formatted string once the period
/// has already reset or has no time component worth animating.
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
