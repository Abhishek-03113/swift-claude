import Foundation
import OrbitPresentation
import SwiftUI

/// A reusable ring: a band of radial tick marks around a shared center, with
/// a lit arc drawn in `accent` over a dim track. Drawn with `Canvas` for
/// direct control over tick geometry rather than by masking shapes.
///
/// `progress` is the *used* fraction (0...1) — lit ticks represent
/// consumption, matching the product rule of ring = used, center = remaining.
///
/// Conforms to `Animatable` so progress changes redraw frame by frame. A
/// `Canvas` reads its inputs inside a closure and SwiftUI cannot interpolate
/// those on its own; without `animatableData` the ring would jump straight to
/// its new value and the caller's sweep animation would have nothing to drive.
struct UsageRing: View, Animatable {
    var progress: Double
    let style: RingStyle
    let accent: Color
    let trackOpacity: Double
    let arcOpacity: Double
    let glowRadiusAtReferenceSize: CGFloat
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Interpolated by SwiftUI during an animation. Clamped on the way in, so
    /// a spring that overshoots past 1 still cannot overdraw the arc.
    var animatableData: Double {
        get { progress }
        set { progress = min(max(newValue, 0), 1) }
    }

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
        // Progress is animated by whoever changes it — the dial's sweep owns
        // that timing, and an animation here would override the spring.
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: arcOpacity)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let geometry = Geometry(size: size, style: style)
        let glow = DialMetrics.scaledGlow(glowRadiusAtReferenceSize, diameter: geometry.diameter)
        let progressAngle = progress * 360

        for index in 0..<style.tickCount {
            let tick = geometry.tick(at: index)
            let litFraction = tick.litFraction(upTo: progressAngle)

            guard litFraction > 0 else {
                context.fill(tick.path, with: .color(accent.opacity(trackOpacity)))
                continue
            }

            // Blend rather than switch, so the tick the arc ends inside fades
            // across the boundary instead of popping on.
            let opacity = arcOpacity * litFraction + trackOpacity * (1 - litFraction)
            var litContext = context
            if glow > 0 {
                litContext.addFilter(.shadow(color: accent.opacity(0.9), radius: glow))
            }
            litContext.fill(tick.path, with: .color(accent.opacity(opacity)))
        }
    }
}

private extension UsageRing {
    /// Resolves the ring's fixed geometry once per draw, then produces one
    /// tick at a time. Keeps the trigonometry out of the drawing loop.
    ///
    /// Each tick is a filled annular wedge — the radial band between the
    /// ring's inner/outer edge, cut to the duty-cycle's angular width — a
    /// direct port of the design's `conic-gradient` + radial `mask-image`
    /// intersection, rather than a stroked line approximating it.
    struct Geometry {
        let diameter: CGFloat

        private let center: CGPoint
        private let innerRadius: CGFloat
        private let outerRadius: CGFloat
        private let slotDegrees: Double
        private let litSlotDegrees: Double

        init(size: CGSize, style: RingStyle) {
            diameter = min(size.width, size.height)
            center = CGPoint(x: size.width / 2, y: size.height / 2)

            let radius = diameter / 2
            let band = style.band
            innerRadius = radius * band.inner
            outerRadius = radius * band.outer

            slotDegrees = 360 / Double(style.tickCount)
            litSlotDegrees = slotDegrees * Double(style.dutyCycle)
        }

        func tick(at index: Int) -> Tick {
            let slotStart = Double(index) * slotDegrees
            let startAngle = Angle(degrees: DialMetrics.startAngleDegrees + slotStart)
            let endAngle = Angle(degrees: DialMetrics.startAngleDegrees + slotStart + litSlotDegrees)

            var path = Path()
            path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
            path.closeSubpath()

            return Tick(
                path: path,
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
