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
        switch family {
        case .systemSmall:
            // No chrome at all: at this size the dial *is* the widget, and a
            // badge or caption would only steal diameter from it.
            UsageDialContainer(presentation: presentation, layout: layout)
                .padding(6)

        case .systemMedium:
            MediumDialLayout(presentation: presentation, layout: layout)

        default:
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

/// The wide widget, laid out along the axis it actually has.
///
/// A medium widget is roughly 2:1, so sizing the dial off `min(width, height)`
/// — which is what the dial does internally, correctly, for a square — leaves
/// the whole second half of the widget empty. Here the dial takes a square
/// column at full height and the details take the rest, which is also what
/// lets the core drop to two lines: the reset line has somewhere better to be.
private struct MediumDialLayout: View {
    let presentation: DialPresentation
    let layout: DialLayout

    var body: some View {
        HStack(spacing: 14) {
            // A square whose side is the widget's height, so the dial is as
            // large as the short axis allows rather than as large as the
            // leftovers of a vertical stack allow.
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(UsageDialContainer(presentation: presentation, layout: layout))
                .layoutPriority(1)

            DialDetailColumn(presentation: presentation)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }
}

/// The text that no longer fits inside a two-line core, set at sizes that
/// don't depend on the dial's diameter — this column has real width.
private struct DialDetailColumn: View {
    let presentation: DialPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProviderBadge(provider: presentation.provider, size: 11)

            Spacer(minLength: 0)

            Text("\(UsageFormatting.durationText(presentation.focusTimeUntilReset)) left")
                .font(UsageTypography.primaryValue(size: 20))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(presentation.lastUpdatedText ?? presentation.focusResetText)
                .font(UsageTypography.metadata(size: 11))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            // The period that isn't focused, as a hint that the dial is
            // tappable rather than as data.
            Text(presentation.secondaryPeriodLabel)
                .font(UsageTypography.periodLabel(size: 9))
                .tracking(UsageTypography.periodLabelTracking(forSize: 9))
                .foregroundStyle(.white.opacity(UsageOpacity.inactive))
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
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
        .padding(8)
        .accessibilityLabel("Loading usage")
    }
}

/// Preserves provider identity and offers a next step, without destroying the
/// widget's visual identity with a raw error dump.
///
/// The retry asks the app to re-read rather than fetching here — the widget
/// reads the app's cache and cannot run a provider's CLI itself. If the app
/// isn't running the tap does nothing, which is why the copy names Orbit.
private struct UsageUnavailableView: View {
    @Environment(\.widgetFamily) private var family

    let provider: AgentProvider

    var body: some View {
        // The whole surface is the button: at small sizes there is no room for
        // a separate control, and a tap anywhere meaning "try again" is the
        // behaviour people expect from a widget showing nothing useful.
        Button(intent: RefreshUsageIntent()) {
            VStack(spacing: family == .systemSmall ? 4 : 8) {
                Image(systemName: provider.symbolName)
                    .font(.system(size: family == .systemSmall ? 16 : 20, weight: .medium))
                    .foregroundStyle(.white.opacity(UsageOpacity.secondary))
                Text("Usage unavailable")
                    .font(UsageTypography.periodLabel(size: family == .systemSmall ? 10 : 12))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Tap to refresh")
                    .font(UsageTypography.metadata(size: family == .systemSmall ? 9 : 11))
                    .foregroundStyle(.white.opacity(UsageOpacity.secondary))
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(provider.name) usage unavailable. Refresh, or open Orbit if it isn't running.")
    }
}
