import OrbitCore
import OrbitPresentation
import SwiftUI

/// One agent in full: the dial, then every quota window it reports spelled
/// out underneath. The dial answers "how much is left"; the rows below answer
/// "of what, and until when".
struct AgentDetailView: View {
    let agent: AgentSlot
    let store: AgentUsageStore

    var body: some View {
        Group {
            if !agent.isConnected {
                notConnected
            } else {
                switch store.state(for: agent) {
                case .loading:
                    ProgressView().controlSize(.large)
                case .loaded(let snapshot):
                    usage(snapshot: snapshot, isStale: false)
                case .stale(let snapshot):
                    usage(snapshot: snapshot, isStale: true)
                case .failed(let error):
                    unavailable(error)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(agent.provider.name)
    }

    @ViewBuilder
    private func usage(snapshot: UsageSnapshot, isStale: Bool) -> some View {
        if let presentation = DialPresentationBuilder.build(
            snapshot: snapshot,
            selected: store.selectedPeriod,
            staleness: isStale ? .stale(snapshot) : nil
        ) {
            GeometryReader { proxy in
                let metrics = DetailMetrics(size: proxy.size)

                ScrollView {
                    VStack(spacing: metrics.stackSpacing) {
                        dial(presentation, diameter: metrics.dialDiameter)
                        periodList(snapshot, isCompact: metrics.isCompact)
                        footer(snapshot: snapshot, isStale: isStale)
                    }
                    .padding(metrics.padding)
                    .frame(maxWidth: DetailMetrics.contentMaxWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        } else {
            ContentUnavailableView(
                "Incomplete Usage Data",
                systemImage: "exclamationmark.triangle",
                description: Text("\(agent.provider.name) did not report both a session and a weekly limit.")
            )
        }
    }

    private func dial(_ presentation: DialPresentation, diameter: CGFloat) -> some View {
        UsageDialContainer(
            presentation: presentation,
            layout: .app,
            selectionBehavior: .action { store.selectedPeriod = $0 },
            sweepToken: store.refreshToken
        )
        .frame(width: diameter, height: diameter)
        // The instrument keeps its own dark environment inside the app's
        // standard window chrome, exactly as it appears in the widget.
        .padding(20)
        .background(Color.black.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.08))
        )
        .accessibilityHint("Click the outer ring for weekly usage, the center for the session.")
    }

    private func periodList(_ snapshot: UsageSnapshot, isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(snapshot.periods.enumerated()), id: \.element.id) { index, period in
                if index > 0 { Divider() }
                PeriodRow(period: period, isCompact: isCompact)
            }
        }
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func footer(snapshot: UsageSnapshot, isStale: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if isStale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Showing the last reading Orbit could take — \(UsageFormatting.updatedAgoText(snapshot.lastUpdated)).")
                    // The stale sentence is long enough to need more than one
                    // line once the window narrows; without this it truncates.
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(UsageFormatting.updatedAgoText(snapshot.lastUpdated).capitalizedFirst)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notConnected: some View {
        ContentUnavailableView {
            Label("\(agent.provider.name) Isn't Connected", systemImage: agent.provider.symbolName)
        } description: {
            Text("Orbit is built to track several agents. \(agent.provider.name) has no usage adapter yet, so nothing is being read for it.")
        }
    }

    private func unavailable(_ error: UsageRepositoryError) -> some View {
        ContentUnavailableView {
            Label("Usage Unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            Text(explanation(for: error))
        } actions: {
            Button("Try Again") {
                Task { await store.refreshAll() }
            }
        }
    }

    /// Repository errors carry enough to say what to do about them, which is
    /// the difference between a useful empty state and a shrug.
    private func explanation(for error: UsageRepositoryError) -> String {
        switch error {
        case .unavailable:
            return """
            Orbit couldn't find the `claude` command. Install Claude Code, or make sure it \
            is at one of the usual locations such as /opt/homebrew/bin or ~/.claude/local.
            """
        case .notAuthenticated:
            return "Claude Code isn't signed in. Run `claude` in a terminal and sign in, then refresh."
        case .malformedResponse(let detail):
            return detail
        }
    }
}

/// Every size the detail layout varies with the window, resolved in one place
/// from the space actually available.
///
/// The dial is sized from *both* axes: a short wide window has as little room
/// for a large instrument as a narrow tall one, and reading only the width
/// would let the dial push the quota rows off the bottom.
private struct DetailMetrics {
    /// Past this the column stops growing and centers — long measures are
    /// harder to read, and a 2000pt-wide dial is not more informative.
    static let contentMaxWidth: CGFloat = 560

    private static let dialRange: ClosedRange<CGFloat> = 150...300
    /// The fraction of the shorter axis the instrument may claim.
    private static let dialFraction: CGFloat = 0.42
    /// Below this width the layout switches to its stacked, tighter form.
    private static let compactWidthThreshold: CGFloat = 420

    let dialDiameter: CGFloat
    let padding: CGFloat
    let stackSpacing: CGFloat
    let isCompact: Bool

    init(size: CGSize) {
        let shortestSide = min(size.width, size.height)
        // `max` with the lower bound rather than a plain clamp: when the
        // window is genuinely tiny the dial holds its floor and the ScrollView
        // takes over, which is the readable failure mode.
        let ideal = shortestSide * Self.dialFraction
        dialDiameter = min(max(ideal, Self.dialRange.lowerBound), Self.dialRange.upperBound)

        isCompact = size.width < Self.compactWidthThreshold
        padding = isCompact ? 16 : 28
        stackSpacing = isCompact ? 16 : 24
    }
}

/// One quota window, with a plain linear gauge. Deliberately not a second
/// dial: the instrument earns its complexity once per screen, and these rows
/// are for reading exact figures.
///
/// At narrow widths the figures move below the title instead of competing with
/// it for the same line — the gauge stays full-width there rather than being
/// squeezed to nothing beside truncated text.
private struct PeriodRow: View {
    let period: UsagePeriod
    let isCompact: Bool

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 8) {
                    heading
                    HStack(spacing: 12) {
                        gauge
                        usedValue
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    heading
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 4) {
                        usedValue
                        gauge
                            // A range rather than a constant, so the gauge
                            // gives width back to a long title before it
                            // truncates, and grows a little when there's room.
                            .frame(minWidth: 90, idealWidth: 140, maxWidth: 180)
                    }
                    .layoutPriority(1)
                }
            }
        }
        .padding(.horizontal, isCompact ? 12 : 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(period.usedPercent) percent used, \(period.remainingPercent) percent remaining.")
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Text(UsageFormatting.resetText(for: period.type, resetDate: period.resetDate).capitalizedFirst)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var usedValue: some View {
        Text("\(period.usedPercent)% used")
            .font(.system(.body, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }

    private var gauge: some View {
        ProgressView(value: period.progress)
            .progressViewStyle(.linear)
            .tint(Color(UsageColorRamp.token(forUsagePercent: period.progress * 100)))
    }

    private var title: String {
        switch period.type {
        case .session: return "Current session"
        case .weekly: return "Current week"
        case .daily: return "Today"
        case .monthly: return "This month"
        case .custom:
            // "weekly-opus" -> "Current week (Opus)"
            let model = period.id.replacingOccurrences(of: "weekly-", with: "")
            return "Current week (\(model.capitalizedFirst))"
        }
    }
}

extension String {
    /// Reset and freshness strings are written lowercase for use mid-sentence;
    /// this is for the places they start one.
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
