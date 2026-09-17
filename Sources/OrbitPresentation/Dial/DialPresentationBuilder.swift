import CoreGraphics
import Foundation
import OrbitCore

/// The snapshot + selection -> visual state transform.
///
/// This stands in for a traditional view model. Widgets re-render from
/// timeline entries rather than observing mutable state, so it is a pure
/// function rather than an `ObservableObject` — which also makes every
/// selection and staleness case directly unit testable.
public enum DialPresentationBuilder {
    /// - Returns: `nil` when the snapshot lacks the session or weekly period
    ///   the two-ring dial is built around; the caller shows its unavailable
    ///   state rather than a half-drawn instrument.
    public static func build(
        snapshot: UsageSnapshot,
        selected: SelectedUsagePeriod,
        now: Date = .now,
        staleness: UsageLoadState? = nil
    ) -> DialPresentation? {
        guard let session = snapshot.period(.session),
              let weekly = snapshot.period(.weekly) else {
            return nil
        }

        let sessionColor = UsageColorRamp.token(forUsagePercent: session.progress * 100)
        let weeklyColor = UsageColorRamp.token(forUsagePercent: weekly.progress * 100)
        let sessionIsFocused = selected == .session

        let inner = ring(
            .inner,
            period: session,
            color: sessionColor,
            isSelected: sessionIsFocused,
            provider: snapshot.provider,
            periodName: "session",
            limitDescription: "5-hour limit",
            now: now
        )
        let outer = ring(
            .outer,
            period: weekly,
            color: weeklyColor,
            isSelected: !sessionIsFocused,
            provider: snapshot.provider,
            periodName: "weekly",
            limitDescription: "weekly limit",
            now: now
        )

        let focus = sessionIsFocused ? session : weekly
        let isStale: Bool
        if case .stale = staleness { isStale = true } else { isStale = false }

        return DialPresentation(
            inner: inner,
            outer: outer,
            selected: selected,
            provider: snapshot.provider,
            focusColor: sessionIsFocused ? sessionColor : weeklyColor,
            focusRemainingPercent: Int(((1 - focus.progress) * 100).rounded()),
            focusRemaining: focus.remaining,
            focusResetDate: focus.resetDate,
            focusPeriodLabel: sessionIsFocused ? "SESSION" : "WEEKLY",
            focusResetText: UsageFormatting.resetText(for: focus.type, resetDate: focus.resetDate, now: now),
            secondaryPeriodLabel: sessionIsFocused ? "WEEKLY" : "SESSION",
            lastUpdatedText: isStale ? UsageFormatting.updatedAgoText(snapshot.lastUpdated, now: now) : nil
        )
    }

    private static func ring(
        _ style: RingStyle,
        period: UsagePeriod,
        color: ColorToken,
        isSelected: Bool,
        provider: AgentProvider,
        periodName: String,
        limitDescription: String,
        now: Date
    ) -> RingPresentation {
        RingPresentation(
            progress: period.progress,
            color: color,
            trackOpacity: trackOpacity(style, isSelected: isSelected),
            arcOpacity: arcOpacity(style, isSelected: isSelected),
            glowRadiusAtReferenceSize: glowRadius(style, isSelected: isSelected),
            isSelected: isSelected,
            accessibilityLabel: accessibilityLabel(
                provider: provider,
                periodName: periodName,
                limitDescription: limitDescription,
                period: period,
                now: now
            )
        )
    }

    private static func trackOpacity(_ style: RingStyle, isSelected: Bool) -> Double {
        switch style {
        case .inner: return isSelected ? DialMetrics.innerTrackOpacitySelected : DialMetrics.innerTrackOpacityUnselected
        case .outer: return isSelected ? DialMetrics.outerTrackOpacitySelected : DialMetrics.outerTrackOpacityUnselected
        }
    }

    private static func arcOpacity(_ style: RingStyle, isSelected: Bool) -> Double {
        switch style {
        case .inner: return isSelected ? DialMetrics.innerArcOpacitySelected : DialMetrics.innerArcOpacityUnselected
        case .outer: return isSelected ? DialMetrics.outerArcOpacitySelected : DialMetrics.outerArcOpacityUnselected
        }
    }

    private static func glowRadius(_ style: RingStyle, isSelected: Bool) -> CGFloat {
        switch style {
        case .inner: return isSelected ? DialMetrics.innerGlowSelected : DialMetrics.innerGlowUnselected
        case .outer: return isSelected ? DialMetrics.outerGlowSelected : DialMetrics.outerGlowUnselected
        }
    }

    private static func accessibilityLabel(
        provider: AgentProvider,
        periodName: String,
        limitDescription: String,
        period: UsagePeriod,
        now: Date
    ) -> String {
        let remaining = UsageFormatting.spokenRemainingText(period.remaining)
        let reset = UsageFormatting.resetText(for: period.type, resetDate: period.resetDate, now: now)
        let sentenceCasedReset = reset.prefix(1).uppercased() + reset.dropFirst()
        return "\(provider.name) \(periodName) usage: \(remaining) remaining of a \(limitDescription). \(sentenceCasedReset)."
    }
}
