import SwiftUI
import WidgetKit

/// The complete instrument: outer (weekly) ring, inner (session) ring, the
/// glass core with center content, a soft color bloom behind everything,
/// and the two tap targets that drive `SelectUsagePeriodIntent`. Everything
/// here is driven entirely by `DialPresentation` — no usage math, no
/// Claude-specific knowledge.
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

                UsageRing(
                    progress: presentation.outer.progress,
                    style: .outer,
                    accent: Color(presentation.outer.color),
                    trackOpacity: presentation.outer.trackOpacity,
                    arcOpacity: presentation.outer.arcOpacity,
                    glowRadiusAtReferenceSize: presentation.outer.glowRadiusAtReferenceSize,
                    accessibilityLabel: presentation.outer.accessibilityLabel
                )
                .frame(width: diameter, height: diameter)

                UsageRing(
                    progress: presentation.inner.progress,
                    style: .inner,
                    accent: Color(presentation.inner.color),
                    trackOpacity: presentation.inner.trackOpacity,
                    arcOpacity: presentation.inner.arcOpacity,
                    glowRadiusAtReferenceSize: presentation.inner.glowRadiusAtReferenceSize,
                    accessibilityLabel: presentation.inner.accessibilityLabel
                )
                .frame(width: diameter, height: diameter)

                rimHighlight(diameter: diameter)

                glassCore(diameter: diameter)

                // Tap targets: the full disc selects weekly; the smaller
                // central disc (drawn after, so it wins hit-testing) selects
                // session — mirroring the approved design's layered hit
                // regions (outer ring = weekly, inner/center = session).
                Button(intent: SelectUsagePeriodIntent(period: .weekly)) {
                    Circle().fill(.clear).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(width: diameter, height: diameter)
                .accessibilityLabel("Show weekly usage")

                Button(intent: SelectUsagePeriodIntent(period: .session)) {
                    Circle().fill(.clear).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(width: diameter * (DialMetrics.innerRingOuter), height: diameter * (DialMetrics.innerRingOuter))
                .accessibilityLabel("Show session usage")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.9), value: presentation.selected)
        }
        .accessibilityElement(children: .contain)
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

    private func startMarker(diameter: CGFloat, color: Color) -> some View {
        Triangle()
            .fill(color.opacity(0.9))
            .frame(width: diameter * 0.03, height: diameter * 0.02)
            .shadow(color: color.opacity(0.7), radius: diameter * 0.01)
            .offset(y: -diameter / 2 - diameter * 0.01)
            .allowsHitTesting(false)
    }

    private func rimHighlight(diameter: CGFloat) -> some View {
        Circle()
            .strokeBorder(.white.opacity(0.05), lineWidth: diameter * (DialMetrics.rimHighlightOuter - DialMetrics.rimHighlightInner) / 2)
            .frame(
                width: diameter * (DialMetrics.rimHighlightInner + DialMetrics.rimHighlightOuter) / 2,
                height: diameter * (DialMetrics.rimHighlightInner + DialMetrics.rimHighlightOuter) / 2
            )
            .allowsHitTesting(false)
    }

    private func glassCore(diameter: CGFloat) -> some View {
        let coreDiameter = diameter * DialMetrics.coreDiameterFraction
        return GlassSurface(shape: AnyDialShape(Circle())) {
            UsageCenterContent(presentation: presentation, diameter: coreDiameter, showsResetLine: layout.showsResetLine)
                .frame(width: coreDiameter, height: coreDiameter)
        }
        .frame(width: coreDiameter, height: coreDiameter)
        .overlay(
            Circle().strokeBorder(.white.opacity(0.09), lineWidth: 1)
        )
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
