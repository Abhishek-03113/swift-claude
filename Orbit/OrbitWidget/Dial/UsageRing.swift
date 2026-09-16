import SwiftUI

/// Which concentric ring this is. Carries only geometry — no notion of
/// "session" or "weekly" belongs here, per the no-Claude-in-generic-UI rule.
public enum RingStyle {
    case inner
    case outer

    var band: (inner: CGFloat, outer: CGFloat) {
        switch self {
        case .inner: return (DialMetrics.innerRingInner, DialMetrics.innerRingOuter)
        case .outer: return (DialMetrics.outerRingInner, DialMetrics.outerRingOuter)
        }
    }

    var tickCount: Int {
        switch self {
        case .inner: return DialMetrics.innerTickCount
        case .outer: return DialMetrics.outerTickCount
        }
    }

    var dutyCycle: CGFloat {
        switch self {
        case .inner: return DialMetrics.innerTickDutyCycle
        case .outer: return DialMetrics.outerTickDutyCycle
        }
    }
}

/// A reusable, provider-agnostic ring: a band of radial tick marks around a
/// shared center, with a lit arc (progress) drawn in `accent` over a dim
/// track. Built with `Canvas` for precise control over tick geometry rather
/// than layering `ProgressView`/`Shape` masks.
///
/// `progress` is the *used* fraction (0...1) — the lit ticks represent
/// consumption, matching the product's chosen visual rule (ring = used,
/// center number = remaining).
public struct UsageRing: View {
    let progress: Double
    let style: RingStyle
    let accent: Color
    let trackOpacity: Double
    let arcOpacity: Double
    let glowRadiusAtReferenceSize: CGFloat
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        progress: Double,
        style: RingStyle,
        accent: Color,
        trackOpacity: Double,
        arcOpacity: Double,
        glowRadiusAtReferenceSize: CGFloat,
        accessibilityLabel: String
    ) {
        self.progress = min(max(progress, 0), 1)
        self.style = style
        self.accent = accent
        self.trackOpacity = trackOpacity
        self.arcOpacity = arcOpacity
        self.glowRadiusAtReferenceSize = glowRadiusAtReferenceSize
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int(progress * 100)) percent used")
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: progress)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: arcOpacity)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let diameter = min(size.width, size.height)
        let radius = diameter / 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let band = style.band
        let innerRadius = radius * band.inner
        let outerRadius = radius * band.outer
        let tickLength = outerRadius - innerRadius
        let tickWidth = max(diameter * 0.012, 1.2)
        let count = style.tickCount
        let slot = 360.0 / Double(count)
        let litSlot = slot * Double(style.dutyCycle)
        let progressAngle = progress * 360

        let glow = DialMetrics.scaledGlow(glowRadiusAtReferenceSize, diameter: diameter)

        for i in 0..<count {
            let slotStart = Double(i) * slot
            let tickMidAngle = slotStart + litSlot / 2
            // Fraction of this tick that falls before the progress boundary,
            // used to fade the single tick the arc ends in rather than
            // popping it fully on/off.
            let tickStart = slotStart
            let tickEnd = slotStart + litSlot
            let litFraction: Double
            if tickEnd <= progressAngle {
                litFraction = 1
            } else if tickStart >= progressAngle {
                litFraction = 0
            } else {
                litFraction = (progressAngle - tickStart) / litSlot
            }

            let angle = Angle(degrees: DialMetrics.startAngleDegrees + tickMidAngle)
            let midRadius = (innerRadius + outerRadius) / 2
            let dx = CGFloat(cos(angle.radians)) * midRadius
            let dy = CGFloat(sin(angle.radians)) * midRadius
            let tickCenter = CGPoint(x: center.x + dx, y: center.y + dy)

            var path = Path()
            let half = tickLength / 2
            path.move(to: CGPoint(x: -half, y: 0))
            path.addLine(to: CGPoint(x: half, y: 0))

            let transform = CGAffineTransform(translationX: tickCenter.x, y: tickCenter.y)
                .rotated(by: angle.radians + .pi / 2)
            let transformed = path.applying(transform)

            let style = StrokeStyle(lineWidth: tickWidth, lineCap: .round)

            if litFraction > 0 {
                var litContext = context
                if glow > 0 {
                    litContext.addFilter(.shadow(color: accent.opacity(0.9), radius: glow))
                }
                litContext.stroke(transformed, with: .color(accent.opacity(arcOpacity * litFraction + trackOpacity * (1 - litFraction))), style: style)
            } else {
                context.stroke(transformed, with: .color(accent.opacity(trackOpacity)), style: style)
            }
        }
    }
}
