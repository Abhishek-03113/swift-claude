import Foundation

/// A provider's accent color, expressed without depending on SwiftUI so the
/// domain layer stays presentation-agnostic. Views convert this to `Color`.
public struct ColorToken: Equatable, Sendable, Codable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Convenience initializer from a `#RRGGBB` hex string.
    public init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s.removeAll { $0 == "#" }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        self.red = Double((value & 0xFF0000) >> 16) / 255
        self.green = Double((value & 0x00FF00) >> 8) / 255
        self.blue = Double(value & 0x0000FF) / 255
    }
}
