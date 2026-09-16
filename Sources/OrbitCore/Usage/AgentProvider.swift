import Foundation

/// Identity of an AI agent whose usage Orbit can display. Generic views
/// depend on this type rather than on any specific provider, so adding a
/// second agent stays purely additive.
public struct AgentProvider: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let name: String
    /// SF Symbol name for the provider badge. A string rather than an `Image`
    /// so the type stays `Sendable`/`Codable` across the app/widget boundary.
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
    /// Anthropic's brand coral is this provider's own accent only; generic UI
    /// never references it by name.
    static let claudeCode = AgentProvider(
        id: "claude-code",
        name: "Claude Code",
        symbolName: "sparkle",
        accent: ColorToken(hex: "#DA7756")
    )
}
