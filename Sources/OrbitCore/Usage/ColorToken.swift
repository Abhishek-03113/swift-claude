import Foundation

/// An sRGB color expressed without SwiftUI, so the model and presentation
/// layers stay free of a UI-framework dependency. Views convert it to `Color`.
public struct ColorToken: Equatable, Sendable, Codable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Initializes from a `#RRGGBB` string. Unparseable input yields black
    /// rather than trapping — a bad token must never crash a widget.
    public init(hex: String) {
        var digits = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        digits.removeAll { $0 == "#" }

        var value: UInt64 = 0
        Scanner(string: digits).scanHexInt64(&value)

        self.red = Double((value & 0xFF0000) >> 16) / 255
        self.green = Double((value & 0x00FF00) >> 8) / 255
        self.blue = Double(value & 0x0000FF) / 255
    }
}
