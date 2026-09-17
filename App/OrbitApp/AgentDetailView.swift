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
            ScrollView {
                VStack(spacing: 24) {
                    dial(presentation)
                    periodList(snapshot)
                    footer(snapshot: snapshot, isStale: isStale)
                }
                .padding(28)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        } else {
            ContentUnavailableView(
                "Incomplete Usage Data",
                systemImage: "exclamationmark.triangle",
                description: Text("\(agent.provider.name) did not report both a session and a weekly limit.")
            )
        }
    }

    private func dial(_ presentation: DialPresentation) -> some View {
        UsageDialContainer(
            presentation: presentation,
            layout: .app,
            selectionBehavior: .action { store.selectedPeriod = $0 },
            sweepToken: store.refreshToken
        )
        .frame(width: 260, height: 260)
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

    private func periodList(_ snapshot: UsageSnapshot) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(snapshot.periods.enumerated()), id: \.element.id) { index, period in
                if index > 0 { Divider() }
                PeriodRow(period: period)
            }
        }
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func footer(snapshot: UsageSnapshot, isStale: Bool) -> some View {
        HStack(spacing: 6) {
            if isStale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Showing the last reading Orbit could take — \(UsageFormatting.updatedAgoText(snapshot.lastUpdated)).")
            } else {
                Text(UsageFormatting.updatedAgoText(snapshot.lastUpdated).capitalizedFirst)
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

/// One quota window, with a plain linear gauge. Deliberately not a second
/// dial: the instrument earns its complexity once per screen, and these rows
/// are for reading exact figures.
private struct PeriodRow: View {
    let period: UsagePeriod

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(UsageFormatting.resetText(for: period.type, resetDate: period.resetDate).capitalizedFirst)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(period.usedPercent)% used")
                    .font(.system(.body, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: period.progress)
                    .progressViewStyle(.linear)
                    .tint(Color(UsageColorRamp.token(forUsagePercent: period.progress * 100)))
                    .frame(width: 120)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(period.usedPercent) percent used, \(period.remainingPercent) percent remaining.")
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
