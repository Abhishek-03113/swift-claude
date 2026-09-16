import SwiftUI
import WidgetKit

struct OrbitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OrbitTimelineEntry

    var body: some View {
        let layout = DialLayout.layout(for: family)

        content(layout: layout)
            .containerBackground(for: .widget) {
                RadialGradient(
                    colors: [Color(white: 0.09), Color(white: 0.04), .black],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 0,
                    endRadius: 260
                )
            }
    }

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
                dialLayout(presentation: presentation, layout: layout)
            } else {
                UsageUnavailableView(providerName: snapshot.provider.name, providerSymbol: snapshot.provider.symbolName)
            }

        case .failed:
            UsageUnavailableView(providerName: AgentProvider.claudeCode.name, providerSymbol: AgentProvider.claudeCode.symbolName)
        }
    }

    @ViewBuilder
    private func dialLayout(presentation: DialPresentation, layout: DialLayout) -> some View {
        switch family {
        case .systemSmall:
            UsageDialContainer(presentation: presentation, layout: layout)
                .padding(8)

        default:
            VStack(spacing: 6) {
                if layout.showsProviderBadge {
                    HStack {
                        ProviderBadge(
                            name: presentation.providerName,
                            symbolName: presentation.providerSymbolName,
                            accent: Color(presentation.providerAccent),
                            size: 11
                        )
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

/// Loading state: keeps the dial's silhouette on screen (dim, static rings)
/// rather than a spinner, per the "don't show a giant spinner" requirement.
private struct LoadingDialPlaceholder: View {
    let layout: DialLayout

    var body: some View {
        UsageDialContainer(
            presentation: DialPresentationBuilder.build(
                snapshot: MockUsageProvider.snapshot(sessionUsedFraction: 0, weeklyUsedFraction: 0),
                selected: .session
            )!,
            layout: layout
        )
        .opacity(0.5)
        .accessibilityLabel("Loading usage")
    }
}

/// Error state: preserves provider identity, gives the user a next step,
/// but doesn't destroy the widget's visual identity with a raw error dump.
private struct UsageUnavailableView: View {
    let providerName: String
    let providerSymbol: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: providerSymbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
            Text("Usage unavailable")
                .font(UsageTypography.periodLabel(size: 12))
                .foregroundStyle(.white)
            Text("Try again")
                .font(UsageTypography.metadata(size: 11))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(providerName) usage unavailable. Try again.")
    }
}
