import OrbitCore
import OrbitPresentation
import SwiftUI

/// How tapping a ring changes the selection.
///
/// The widget and the app cannot share one mechanism: a widget can only act
/// through an `AppIntent`, while the app just mutates its own state. The
/// dial itself stays identical either way.
enum DialSelectionBehavior {
    case appIntent
    case action((SelectedUsagePeriod) -> Void)
}

/// The complete instrument: outer (weekly) ring, inner (session) ring, the
/// glass core with its center content, a soft bloom behind everything, and
/// the two tap targets that change the focused period.
///
/// Driven entirely by `DialPresentation` — no usage math, no provider
/// vocabulary.
struct UsageDialContainer: View {
    let presentation: DialPresentation
    let layout: DialLayout
    var selectionBehavior: DialSelectionBehavior = .appIntent

    /// Replays the speedometer sweep whenever this value changes; `nil`
    /// disables the sweep entirely.
    ///
    /// The widget passes `nil`: WidgetKit renders archived snapshots rather
    /// than running an animation loop, so a timed 0 -> value sweep is not
    /// something it can perform. The app drives it with its refresh counter.
    var sweepToken: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far through the sweep the rings currently are. Multiplies both
    /// rings' progress, so they wind up together like a needle sweep on
    /// ignition rather than animating independently.
    @State private var sweepFraction: Double = 1

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
        .onAppear { replaySweep() }
        .onChange(of: sweepToken) { _, _ in replaySweep() }
    }

    /// Winds both rings up from zero to their real values.
    ///
    /// The spring is deliberately underdamped: a speedometer needle overruns
    /// its mark and settles back, and `UsageRing` clamps at 1 so the overshoot
    /// can never draw more than a full ring.
    private func replaySweep() {
        guard sweepToken != nil else {
            sweepFraction = 1
            return
        }
        guard !reduceMotion else {
            sweepFraction = 1
            return
        }

        // Committed without animation first, so the rings are actually at
        // zero before the spring starts rather than animating from wherever
        // they happened to be.
        withTransaction(Transaction(animation: nil)) { sweepFraction = 0 }

        Task { @MainActor in
            withAnimation(.interpolatingSpring(stiffness: 42, damping: 9)) {
                sweepFraction = 1
            }
        }
    }

    private func ring(_ ring: RingPresentation, style: RingStyle, diameter: CGFloat) -> some View {
        UsageRing(
            progress: ring.progress * sweepFraction,
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

    @ViewBuilder
    private func selectionTarget(_ period: SelectedUsagePeriod, diameter: CGFloat, label: String) -> some View {
        switch selectionBehavior {
        case .appIntent:
            Button(intent: SelectUsagePeriodIntent(period: period)) {
                Circle().fill(.clear).contentShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: diameter, height: diameter)
            .accessibilityLabel(label)

        case .action(let select):
            Button { select(period) } label: {
                Circle().fill(.clear).contentShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: diameter, height: diameter)
            .accessibilityLabel(label)
        }
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
        let width: CGFloat = diameter * 0.03
        let height: CGFloat = diameter * 0.02
        let shadowRadius: CGFloat = diameter * 0.01
        let verticalOffset: CGFloat = -diameter / 2 - diameter * 0.01
        let fillColor: Color = color.opacity(0.9)
        let shadowColor: Color = color.opacity(0.7)

        return Triangle()
            .fill(fillColor)
            .frame(width: width, height: height)
            .shadow(color: shadowColor, radius: shadowRadius)
            .offset(y: verticalOffset)
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

        return GlassSurface(diameter: coreDiameter) {
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
