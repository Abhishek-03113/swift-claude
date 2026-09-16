import SwiftUI

/// Standalone reset-metadata line, used where the dial's own center content
/// doesn't have room (e.g. a secondary line on the large widget family
/// describing the *non*-focused period's reset time).
struct ResetCountdown: View {
    let periodType: UsagePeriodType
    let resetDate: Date
    let size: CGFloat

    var body: some View {
        Text(UsageFormatting.resetText(for: periodType, resetDate: resetDate))
            .font(UsageTypography.metadata(size: size))
            .foregroundStyle(.white.opacity(UsageOpacity.secondary))
    }
}
