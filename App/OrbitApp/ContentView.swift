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
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            if let agent = selectedAgent {
                AgentDetailView(agent: agent, store: store)
            } else {
                ContentUnavailableView("No Agent Selected", systemImage: "gauge.with.dots.needle.bottom.50percent")
            }
        }
        // `.balanced` gives the detail column the remaining width rather than
        // letting the sidebar prop the window open at its ideal size; the
        // sidebar's own `max` is what stops it being dragged over the dial.
        .navigationSplitViewStyle(.balanced)
        // The window's floor. It belongs here rather than on the scene's root
        // view: the split view reports its own sizing, which swallows a
        // minimum declared outside it (the height minimum in particular).
        // Below this the sidebar and the dial cannot both be read.
        .frame(minWidth: 620, minHeight: 440)
        .navigationTitle("Orbit")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refreshAll() }
                } label: {
                    Label {
                        Text("Refresh")
                    } icon: {
                        RefreshGlyph(size: 13, color: .primary)
                    }
                }
                .disabled(store.isRefreshing)
                .help("Re-read usage from each connected agent")
            }
        }
        .task {
            await store.start()
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
