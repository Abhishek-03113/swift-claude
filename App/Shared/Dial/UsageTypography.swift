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

    /// Letter-spacing for the period label at its display size.
    static let periodLabelTracking: CGFloat = 2.2

    /// Tracking as a ratio of the font size. Held fixed, 2.2pt of spacing on a
    /// 9pt label is proportionally more than twice what it is on a 20pt one,
    /// and "WEEKLY" outgrows the dial's core at the smaller widget sizes.
    static func periodLabelTracking(forSize size: CGFloat) -> CGFloat {
        min(periodLabelTracking, size * 0.13)
    }

    static func metadata(size: CGFloat) -> Font {
        .system(size: size).monospacedDigit()
    }

    static func providerBadge(size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
}
