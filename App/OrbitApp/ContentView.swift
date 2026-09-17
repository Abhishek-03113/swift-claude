import OrbitCore
import SwiftUI

/// The app window: agents on the left, the selected agent's dial and quota
/// breakdown on the right.
///
/// Standard macOS structure throughout — a `NavigationSplitView`, a sidebar
/// list, a toolbar refresh action. The dial is the only bespoke element; the
/// chrome around it is system-drawn so the app reads as a Mac app rather than
/// a scaled-up widget.
struct ContentView: View {
    @State private var store = AgentUsageStore()
    @State private var selectedAgentID: String?

    private var selectedAgent: AgentSlot? {
        store.agents.first { $0.id == selectedAgentID } ?? store.agents.first
    }

    var body: some View {
        NavigationSplitView {
            List(store.agents, selection: $selectedAgentID) { agent in
                AgentSidebarRow(agent: agent, state: store.state(for: agent))
                    .tag(agent.id)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            if let agent = selectedAgent {
                AgentDetailView(agent: agent, store: store)
            } else {
                ContentUnavailableView("No Agent Selected", systemImage: "gauge.with.dots.needle.bottom.50percent")
            }
        }
        .navigationTitle("Orbit")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refreshAll() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(store.isRefreshing)
                .help("Re-read usage from each connected agent")
            }
        }
        .task {
            await store.refreshAll()
        }
    }
}

/// A sidebar row: provider identity, plus the one number that matters at a
/// glance. Unconnected agents read as deliberately inactive rather than broken.
private struct AgentSidebarRow: View {
    let agent: AgentSlot
    let state: UsageLoadState

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: agent.provider.symbolName)
                .foregroundStyle(agent.isConnected ? Color(agent.provider.accent) : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(agent.provider.name)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .opacity(agent.isConnected ? 1 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(agent.provider.name). \(subtitle)")
    }

    private var subtitle: String {
        guard agent.isConnected else { return "Not connected" }

        switch state {
        case .loading:
            return "Checking…"
        case .loaded(let snapshot), .stale(let snapshot):
            guard let session = snapshot.period(.session) else { return "No session data" }
            return "\(session.remainingPercent)% session left"
        case .failed:
            return "Unavailable"
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 620)
}
