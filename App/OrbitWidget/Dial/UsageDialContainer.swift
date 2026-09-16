import OrbitCore
import OrbitPresentation
import SwiftUI
import WidgetKit

/// The complete instrument: outer (weekly) ring, inner (session) ring, the
/// glass core with its center content, a soft bloom behind everything, and
/// the two tap targets that drive `SelectUsagePeriodIntent`.
///
/// Driven entirely by `DialPresentation` — no usage math, no provider
/// vocabulary.
struct UsageDialContainer: View {
    let presentation: DialPresentation
    let layout: DialLayout

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height) * layout.dialDiameterFraction
            let focusColor = Color(presentation.focusColor)

            ZStack {
                bloom(diameter: diameter, color: focusColor)
                startMarker(diameter: diameter, color: focusColor)
                ring(presentation.outer, style: .outer, diameter: diameter)
                ring(presentation.inner, style: .inner, diameter: diameter)
                rimHighlight(diameter: diameter)
                glassCore(diameter: diameter)
                selectionTargets(diameter: diameter)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(
                reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.9),
                value: presentation.selected
            )
        }
        .accessibilityElement(children: .contain)
    }

    private func ring(_ ring: RingPresentation, style: RingStyle, diameter: CGFloat) -> some View {
        UsageRing(
            progress: ring.progress,
            style: style,
            accent: Color(ring.color),
            trackOpacity: ring.trackOpacity,
            arcOpacity: ring.arcOpacity,
            glowRadiusAtReferenceSize: ring.glowRadiusAtReferenceSize,
            accessibilityLabel: ring.accessibilityLabel
        )
        .frame(width: diameter, height: diameter)
    }

    /// Layered hit regions, mirroring the approved design: the full disc
    /// selects weekly, and the smaller central disc — drawn afterwards, so it
    /// wins hit-testing — selects session.
    private func selectionTargets(diameter: CGFloat) -> some View {
        ZStack {
            selectionTarget(.weekly, diameter: diameter, label: "Show weekly usage")
            selectionTarget(.session, diameter: diameter * DialMetrics.innerRingOuter, label: "Show session usage")
        }
    }

    private func selectionTarget(_ period: SelectedUsagePeriod, diameter: CGFloat, label: String) -> some View {
        Button(intent: SelectUsagePeriodIntent(period: period)) {
            Circle().fill(.clear).contentShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(width: diameter, height: diameter)
        .accessibilityLabel(label)
    }

    private func bloom(diameter: CGFloat, color: Color) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.16), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.55
                )
            )
            .frame(width: diameter * 0.95, height: diameter * 0.95)
            .blur(radius: diameter * 0.08)
            .allowsHitTesting(false)
    }

    /// The 12 o'clock origin marker the arcs grow away from.
    private func startMarker(diameter: CGFloat, color: Color) -> some View {
        Triangle()
            .fill(color.opacity(0.9))
            .frame(width: diameter * 0.03, height: diameter * 0.02)
            .shadow(color: color.opacity(0.7), radius: diameter * 0.01)
            .offset(y: -diameter / 2 - diameter * 0.01)
            .allowsHitTesting(false)
    }

    /// Faint highlight in the gap between the two tick bands.
    private func rimHighlight(diameter: CGFloat) -> some View {
        let bandWidth = diameter * (DialMetrics.rimHighlightOuter - DialMetrics.rimHighlightInner) / 2
        let ringDiameter = diameter * (DialMetrics.rimHighlightInner + DialMetrics.rimHighlightOuter) / 2

        return Circle()
            .strokeBorder(.white.opacity(0.05), lineWidth: bandWidth)
            .frame(width: ringDiameter, height: ringDiameter)
            .allowsHitTesting(false)
    }

    private func glassCore(diameter: CGFloat) -> some View {
        let coreDiameter = diameter * DialMetrics.coreDiameterFraction

        return GlassSurface {
            UsageCenterContent(
                presentation: presentation,
                diameter: coreDiameter,
                showsResetLine: layout.showsResetLine
            )
            .frame(width: coreDiameter, height: coreDiameter)
        }
        .frame(width: coreDiameter, height: coreDiameter)
        .overlay(Circle().strokeBorder(.white.opacity(0.09), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: diameter * 0.05, y: diameter * 0.02)
        .allowsHitTesting(false)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
