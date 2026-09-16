import Foundation
import CoreGraphics

/// Fully-resolved visual state for one ring. Every number here is already
/// selection-aware — the view has no `if isSelected` branching to do beyond
/// picking which ring is "inner" vs "outer" on screen.
public struct RingPresentation: Equatable, Sendable {
    public let progress: Double
    public let color: ColorToken
    public let trackOpacity: Double
    public let arcOpacity: Double
    public let glowRadiusAtReferenceSize: CGFloat
    public let isSelected: Bool
    public let accessibilityLabel: String
}

/// Everything `UsageDialContainer` needs to render one frame. Built once per
/// snapshot+selection by `DialPresentationBuilder` and otherwise inert data —
/// this is what keeps the dial views themselves free of Claude-specific or
/// even usage-math logic.
public struct DialPresentation: Equatable, Sendable {
    public let inner: RingPresentation
    public let outer: RingPresentation

    public let focusColor: ColorToken
    public let focusRemaining: Duration
    public let focusResetDate: Date
    public let focusPeriodLabel: String
    public let focusResetText: String
    public let secondaryPeriodLabel: String

    public let providerName: String
    public let providerSymbolName: String
    public let providerAccent: ColorToken

    public let lastUpdatedText: String?
    public let selected: SelectedUsagePeriod
}

public enum DialPresentationBuilder {
    public static func build(
        snapshot: UsageSnapshot,
        selected: SelectedUsagePeriod,
        now: Date = .now,
        staleness: UsageLoadState? = nil
    ) -> DialPresentation? {
        guard let sessionPeriod = snapshot.period(.session),
              let weeklyPeriod = snapshot.period(.weekly) else {
            return nil
        }

        let sessionColor = UsageColorRamp.token(forUsagePercent: sessionPeriod.progress * 100)
        let weeklyColor = UsageColorRamp.token(forUsagePercent: weeklyPeriod.progress * 100)
        let onSession = selected == .session

        let inner = RingPresentation(
            progress: sessionPeriod.progress,
            color: sessionColor,
            trackOpacity: onSession ? DialMetrics.innerTrackOpacitySelected : DialMetrics.innerTrackOpacityUnselected,
            arcOpacity: onSession ? DialMetrics.innerArcOpacitySelected : DialMetrics.innerArcOpacityUnselected,
            glowRadiusAtReferenceSize: onSession ? DialMetrics.innerGlowSelected : DialMetrics.innerGlowUnselected,
            isSelected: onSession,
            accessibilityLabel: accessibilityLabel(
                providerName: snapshot.provider.name,
                periodName: "session",
                limitDescription: "5-hour limit",
                period: sessionPeriod,
                now: now
            )
        )

        let outer = RingPresentation(
            progress: weeklyPeriod.progress,
            color: weeklyColor,
            trackOpacity: !onSession ? DialMetrics.outerTrackOpacitySelected : DialMetrics.outerTrackOpacityUnselected,
            arcOpacity: !onSession ? DialMetrics.outerArcOpacitySelected : DialMetrics.outerArcOpacityUnselected,
            glowRadiusAtReferenceSize: !onSession ? DialMetrics.outerGlowSelected : DialMetrics.outerGlowUnselected,
            isSelected: !onSession,
            accessibilityLabel: accessibilityLabel(
                providerName: snapshot.provider.name,
                periodName: "weekly",
                limitDescription: "weekly limit",
                period: weeklyPeriod,
                now: now
            )
        )

        let focusPeriod = onSession ? sessionPeriod : weeklyPeriod
        let focusColor = onSession ? sessionColor : weeklyColor

        var lastUpdatedText: String?
        if case .stale = staleness {
            lastUpdatedText = UsageFormatting.updatedAgoText(snapshot.lastUpdated, now: now)
        }

        return DialPresentation(
            inner: inner,
            outer: outer,
            focusColor: focusColor,
            focusRemaining: focusPeriod.remaining,
            focusResetDate: focusPeriod.resetDate,
            focusPeriodLabel: onSession ? "SESSION" : "WEEKLY",
            focusResetText: UsageFormatting.resetText(for: focusPeriod.type, resetDate: focusPeriod.resetDate, now: now),
            secondaryPeriodLabel: onSession ? "WEEKLY" : "SESSION",
            providerName: snapshot.provider.name,
            providerSymbolName: snapshot.provider.symbolName,
            providerAccent: snapshot.provider.accent,
            lastUpdatedText: lastUpdatedText,
            selected: selected
        )
    }

    private static func accessibilityLabel(providerName: String, periodName: String, limitDescription: String, period: UsagePeriod, now: Date) -> String {
        let remaining = UsageFormatting.spokenRemainingText(period.remaining)
        let reset = UsageFormatting.resetText(for: period.type, resetDate: period.resetDate, now: now)
        return "\(providerName) \(periodName) usage: \(remaining) remaining of a \(limitDescription). \(reset.prefix(1).uppercased() + reset.dropFirst())."
    }
}
