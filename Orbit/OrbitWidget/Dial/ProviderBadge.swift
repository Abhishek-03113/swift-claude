import SwiftUI

/// Tertiary provider identity — an icon plus name, small and quiet. Never
/// competes visually with the quota number per the information hierarchy.
struct ProviderBadge: View {
    let name: String
    let symbolName: String
    let accent: Color
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.28) {
            Image(systemName: symbolName)
                .font(.system(size: size * 0.85, weight: .medium))
                .foregroundStyle(accent)
            Text(name)
                .font(UsageTypography.providerBadge(size: size))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Provider: \(name)")
    }
}
