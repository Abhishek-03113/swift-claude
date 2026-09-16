import CoreGraphics

/// Centralized geometry constants for the dial, expressed as fractions of
/// the dial's own diameter so the same visual language holds at every
/// widget size (small/medium/large) rather than being tuned once for a
/// fixed pixel size. Ported from the proportions in the approved design
/// file's large and "actual size" renderings, which agreed closely enough
/// to treat as one continuous scale.
public enum DialMetrics {
    // Ring bands, as fraction of dial radius (0...1 from center to edge).
    public static let outerRingInner: CGFloat = 0.82
    public static let outerRingOuter: CGFloat = 0.97
    public static let innerRingInner: CGFloat = 0.56
    public static let innerRingOuter: CGFloat = 0.73

    // Faint rim highlight sitting in the gap between the two rings.
    public static let rimHighlightInner: CGFloat = 0.74
    public static let rimHighlightOuter: CGFloat = 0.81

    // Glass core (center content background), as fraction of dial diameter.
    public static let coreDiameterFraction: CGFloat = 0.47

    // Tick geometry: (count, dutyCycle) — dutyCycle is the lit fraction of
    // each tick's angular slot, the remainder is the gap between ticks.
    public static let outerTickCount = 60
    public static let outerTickDutyCycle: CGFloat = 0.4 // 2.4deg lit of 6deg slot
    public static let innerTickCount = 40
    public static let innerTickDutyCycle: CGFloat = 0.378 // 3.4deg lit of 9deg slot

    // Progress starts at 12 o'clock and runs clockwise.
    public static let startAngleDegrees: Double = -90

    // Selection-dependent opacity, matched to the design file's constants.
    public static let innerTrackOpacitySelected: Double = 0.55
    public static let innerTrackOpacityUnselected: Double = 0.2
    public static let outerTrackOpacitySelected: Double = 0.62
    public static let outerTrackOpacityUnselected: Double = 0.34

    public static let innerArcOpacitySelected: Double = 1.0
    public static let innerArcOpacityUnselected: Double = 0.14
    public static let outerArcOpacitySelected: Double = 1.0
    public static let outerArcOpacityUnselected: Double = 0.42

    // Glow radius at the 170pt reference size; scaled by actual diameter.
    public static let referenceDiameter: CGFloat = 170
    public static let innerGlowSelected: CGFloat = 4
    public static let innerGlowUnselected: CGFloat = 0
    public static let outerGlowSelected: CGFloat = 6
    public static let outerGlowUnselected: CGFloat = 2

    public static func scaledGlow(_ reference: CGFloat, diameter: CGFloat) -> CGFloat {
        reference * (diameter / referenceDiameter)
    }
}

/// Non-geometric visual weights (used outside the dial proper).
public enum UsageOpacity {
    public static let active: Double = 1.0
    public static let secondary: Double = 0.55
    public static let inactive: Double = 0.3
}
