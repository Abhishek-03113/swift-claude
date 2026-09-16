import SwiftUI

/// System-typography roles used across the dial. No custom font is ever
/// introduced — only configurations of the system font — so the widget
/// reads as native macOS rather than an imported web design.
public enum UsageTypography {
    /// The dominant remaining-quota value. Rounded design reads slightly
    /// warmer/more instrument-like than the default system font at display
    /// sizes, and tabular numerals keep "2h 43m" -> "2h 42m" from causing
    /// any layout shift as digits change width.
    public static func primaryValue(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .rounded)
            .monospacedDigit()
    }

    public static func primaryUnit(size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    public static func periodLabel(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    public static let periodLabelTracking: CGFloat = 2.2

    public static func metadata(size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
            .monospacedDigit()
    }

    public static func providerBadge(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}
