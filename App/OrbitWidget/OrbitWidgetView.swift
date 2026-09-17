import OrbitCore
import OrbitPresentation
import OrbitProviders
import SwiftUI
import WidgetKit

struct OrbitWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: OrbitTimelineEntry

    var body: some View {
        content(layout: DialLayout.layout(for: family))
            .containerBackground(for: .widget) { Self.background }
    }

    private static let background = RadialGradient(
        colors: [Color(white: 0.09), Color(white: 0.04), .black],
        center: UnitPoint(x: 0.5, y: 0.42),
        startRadius: 0,
        endRadius: 260
    )

    @ViewBuilder
    private func content(layout: DialLayout) -> some View {
        switch entry.loadState {
        case .loading:
            LoadingDialPlaceholder(layout: layout)

        case .loaded(let snapshot), .stale(let snapshot):
            if let presentation = DialPresentationBuilder.build(
                snapshot: snapshot,
                selected: entry.selected,
                staleness: entry.loadState
            ) {
                dial(presentation: presentation, layout: layout)
            } else {
                UsageUnavailableView(provider: snapshot.provider)
            }

        case .failed:
            UsageUnavailableView(provider: entry.provider)
        }
    }

    @ViewBuilder
    private func dial(presentation: DialPresentation, layout: DialLayout) -> some View {
        if family == .systemSmall {
            UsageDialContainer(presentation: presentation, layout: layout)
                .padding(8)
        } else {
            VStack(spacing: 6) {
                if layout.showsProviderBadge {
                    HStack {
                        ProviderBadge(provider: presentation.provider, size: 11)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }

                UsageDialContainer(presentation: presentation, layout: layout)

                if layout.showsSecondaryPeriodLabel {
                    Text(presentation.secondaryPeriodLabel)
                        .font(UsageTypography.periodLabel(size: 9))
                        .tracking(UsageTypography.periodLabelTracking)
                        .foregroundStyle(.white.opacity(UsageOpacity.inactive))
                }
            }
            .padding(12)
        }
    }
}

/// Keeps the dial's silhouette on screen — dim, static rings rather than a
/// spinner — while the first read is in flight.
private struct LoadingDialPlaceholder: View {
    let layout: DialLayout

    var body: some View {
        let empty = MockUsageProvider.snapshot(sessionUsedFraction: 0, weeklyUsedFraction: 0)

        Group {
            if let presentation = DialPresentationBuilder.build(snapshot: empty, selected: .session) {
                UsageDialContainer(presentation: presentation, layout: layout)
                    .opacity(0.5)
            } else {
                Color.clear
            }
        }
        .accessibilityLabel("Loading usage")
    }
}

/// Preserves provider identity and offers a next step, without destroying the
/// widget's visual identity with a raw error dump.
///
/// The next step is always "open Orbit": the widget reads the app's cache and
/// cannot refresh on its own, so pointing at a retry it can't perform would
/// be a lie.
private struct UsageUnavailableView: View {
    let provider: AgentProvider

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: provider.symbolName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
            Text("Usage unavailable")
                .font(UsageTypography.periodLabel(size: 12))
                .foregroundStyle(.white)
            Text("Open Orbit")
                .font(UsageTypography.metadata(size: 11))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(provider.name) usage unavailable. Open Orbit to refresh.")
    }
}
