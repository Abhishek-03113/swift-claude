import OrbitCore
import OrbitProviders

/// One agent the app can list. A slot without a repository is a provider
/// Orbit is designed for but has not implemented yet — shown as an explicit
/// "not connected" row rather than hidden, so the multi-agent shape of the
/// product is visible without inventing data for it.
struct AgentSlot: Identifiable {
    let provider: AgentProvider
    let repository: UsageRepository?

    var id: String { provider.id }
    var isConnected: Bool { repository != nil }
}

enum AgentCatalog {
    /// Claude Code reads through the caching repository, so every successful
    /// refresh also populates the App Group snapshot the widget reads.
    static func live() -> [AgentSlot] {
        [
            AgentSlot(
                provider: .claudeCode,
                repository: CachingUsageRepository(wrapping: ClaudeCodeProvider())
            ),
            AgentSlot(provider: .codex, repository: nil),
            AgentSlot(provider: .gemini, repository: nil),
        ]
    }
}

/// Placeholders for agents Orbit does not read yet. They live here, in the
/// app layer, rather than in `OrbitCore` — a provider earns a place in the
/// domain when it has an adapter, not before.
extension AgentProvider {
    static let codex = AgentProvider(
        id: "codex",
        name: "Codex",
        symbolName: "chevron.left.forwardslash.chevron.right",
        accent: ColorToken(hex: "#10A37F")
    )

    static let gemini = AgentProvider(
        id: "gemini",
        name: "Gemini",
        symbolName: "diamond",
        accent: ColorToken(hex: "#4285F4")
    )
}
