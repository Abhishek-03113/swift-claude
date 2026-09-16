import Foundation
import OrbitPresentation
import SwiftUI

/// A reusable ring: a band of radial tick marks around a shared center, with
/// a lit arc drawn in `accent` over a dim track. Drawn with `Canvas` for
/// direct control over tick geometry rather than by masking shapes.
///
/// `progress` is the *used* fraction (0...1) — lit ticks represent
/// consumption, matching the product rule of ring = used, center = remaining.
struct UsageRing: View {
    let progress: Double
    let style: RingStyle
    let accent: Color
    let trackOpacity: Double
    let arcOpacity: Double
    let glowRadiusAtReferenceSize: CGFloat
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Initializes a ring, clamping `progress` so an out-of-range value can
    /// never overdraw the arc.
    init(
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

    var body: some View {
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
        let geometry = Geometry(size: size, style: style)
        let glow = DialMetrics.scaledGlow(glowRadiusAtReferenceSize, diameter: geometry.diameter)
        let strokeStyle = StrokeStyle(lineWidth: geometry.tickWidth, lineCap: .round)
        let progressAngle = progress * 360

        for index in 0..<style.tickCount {
            let tick = geometry.tick(at: index)
            let litFraction = tick.litFraction(upTo: progressAngle)

            guard litFraction > 0 else {
                context.stroke(tick.path, with: .color(accent.opacity(trackOpacity)), style: strokeStyle)
                continue
            }

            // Blend rather than switch, so the tick the arc ends inside fades
            // across the boundary instead of popping on.
            let opacity = arcOpacity * litFraction + trackOpacity * (1 - litFraction)
            var litContext = context
            if glow > 0 {
                litContext.addFilter(.shadow(color: accent.opacity(0.9), radius: glow))
            }
            litContext.stroke(tick.path, with: .color(accent.opacity(opacity)), style: strokeStyle)
        }
    }
}

private extension UsageRing {
    /// Resolves the ring's fixed geometry once per draw, then produces one
    /// tick at a time. Keeps the trigonometry out of the drawing loop.
    struct Geometry {
        let diameter: CGFloat
        let tickWidth: CGFloat

        private let center: CGPoint
        private let midRadius: CGFloat
        private let tickLength: CGFloat
        private let slotDegrees: Double
        private let litSlotDegrees: Double

        init(size: CGSize, style: RingStyle) {
            diameter = min(size.width, size.height)
            tickWidth = max(diameter * 0.012, 1.2)
            center = CGPoint(x: size.width / 2, y: size.height / 2)

            let radius = diameter / 2
            let band = style.band
            let innerRadius = radius * band.inner
            let outerRadius = radius * band.outer
            midRadius = (innerRadius + outerRadius) / 2
            tickLength = outerRadius - innerRadius

            slotDegrees = 360 / Double(style.tickCount)
            litSlotDegrees = slotDegrees * Double(style.dutyCycle)
        }

        func tick(at index: Int) -> Tick {
            let slotStart = Double(index) * slotDegrees
            let angle = Angle(degrees: DialMetrics.startAngleDegrees + slotStart + litSlotDegrees / 2)

            let position = CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * midRadius,
                y: center.y + CGFloat(sin(angle.radians)) * midRadius
            )

            var path = Path()
            path.move(to: CGPoint(x: -tickLength / 2, y: 0))
            path.addLine(to: CGPoint(x: tickLength / 2, y: 0))

            let transform = CGAffineTransform(translationX: position.x, y: position.y)
                .rotated(by: angle.radians + .pi / 2)

            return Tick(
                path: path.applying(transform),
                startDegrees: slotStart,
                endDegrees: slotStart + litSlotDegrees
            )
        }
    }

    struct Tick {
        let path: Path
        let startDegrees: Double
        let endDegrees: Double

        /// How much of this tick falls before the progress boundary, `0...1`.
        func litFraction(upTo progressAngle: Double) -> Double {
            if endDegrees <= progressAngle { return 1 }
            if startDegrees >= progressAngle { return 0 }
            return (progressAngle - startDegrees) / (endDegrees - startDegrees)
        }
    }
}
