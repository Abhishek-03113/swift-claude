import Foundation

/// Identity of an AI agent whose usage Orbit can display. The dial and every
/// other generic view depend only on this type — never on "Claude" directly —
/// so a second provider is purely additive.
public struct AgentProvider: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    /// SF Symbol name for the provider badge. Kept as a string (rather than
    /// `Image`) so this type stays `Sendable`/`Codable`-friendly across the
    /// widget/app boundary.
    public let symbolName: String
    public let accent: ColorToken

    public init(id: String, name: String, symbolName: String, accent: ColorToken) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.accent = accent
    }
}

public extension AgentProvider {
    /// Anthropic's brand coral, used only as this provider's own accent —
    /// never referenced by name in generic UI code.
    static let claudeCode = AgentProvider(
        id: "claude-code",
        name: "Claude Code",
        symbolName: "sparkle",
        accent: ColorToken(hex: "#DA7756")
    )
}
