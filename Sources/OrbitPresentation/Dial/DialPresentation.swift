import CoreGraphics
import Foundation
import OrbitCore

/// Fully resolved visual state for one ring. Every value is already
/// selection-aware, so the view has no `if isSelected` branching left to do.
public struct RingPresentation: Equatable, Sendable {
    public let progress: Double
    public let color: ColorToken
    public let trackOpacity: Double
    public let arcOpacity: Double
    public let glowRadiusAtReferenceSize: CGFloat
    public let isSelected: Bool
    public let accessibilityLabel: String

    public init(
        progress: Double,
        color: ColorToken,
        trackOpacity: Double,
        arcOpacity: Double,
        glowRadiusAtReferenceSize: CGFloat,
        isSelected: Bool,
        accessibilityLabel: String
    ) {
        self.progress = progress
        self.color = color
        self.trackOpacity = trackOpacity
        self.arcOpacity = arcOpacity
        self.glowRadiusAtReferenceSize = glowRadiusAtReferenceSize
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
    }
}

/// Everything the dial needs to render one frame: inert data built once per
/// snapshot plus selection. This is what keeps the dial views free of usage
/// math and of any provider's vocabulary.
public struct DialPresentation: Equatable, Sendable {
    public let inner: RingPresentation
    public let outer: RingPresentation

    public let selected: SelectedUsagePeriod
    public let provider: AgentProvider

    /// Center content, resolved for whichever period is currently focused.
    public let focusColor: ColorToken
    public let focusRemainingPercent: Int
    public let focusRemaining: Duration
    public let focusResetDate: Date
    public let focusPeriodLabel: String
    public let focusResetText: String

    /// Label for the period that is *not* focused, shown where there is room.
    public let secondaryPeriodLabel: String

    /// Non-nil only when the snapshot on screen is stale, e.g. "updated 12m ago".
    public let lastUpdatedText: String?

    public init(
        inner: RingPresentation,
        outer: RingPresentation,
        selected: SelectedUsagePeriod,
        provider: AgentProvider,
        focusColor: ColorToken,
        focusRemainingPercent: Int,
        focusRemaining: Duration,
        focusResetDate: Date,
        focusPeriodLabel: String,
        focusResetText: String,
        secondaryPeriodLabel: String,
        lastUpdatedText: String?
    ) {
        self.inner = inner
        self.outer = outer
        self.selected = selected
        self.provider = provider
        self.focusColor = focusColor
        self.focusRemainingPercent = focusRemainingPercent
        self.focusRemaining = focusRemaining
        self.focusResetDate = focusResetDate
        self.focusPeriodLabel = focusPeriodLabel
        self.focusResetText = focusResetText
        self.secondaryPeriodLabel = secondaryPeriodLabel
        self.lastUpdatedText = lastUpdatedText
    }
}
