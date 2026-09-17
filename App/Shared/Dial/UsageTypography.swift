import CoreGraphics
import SwiftUI

/// System-typography roles used across the dial. No custom font is ever
/// introduced — only configurations of the system font — so the widget reads
/// as native macOS rather than an imported web design.
enum UsageTypography {
    /// The dominant remaining-quota value. The rounded design reads more
    /// instrument-like at display sizes, and tabular figures keep the layout
    /// still as digits change width.
    static func primaryValue(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .rounded)
            .monospacedDigit()
    }

    static func periodLabel(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static let periodLabelTracking: CGFloat = 2.2

    static func metadata(size: CGFloat) -> Font {
        .system(size: size).monospacedDigit()
    }

    static func providerBadge(size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
}
