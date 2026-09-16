import OrbitCore
import OrbitPresentation
import SwiftUI

/// Tertiary provider identity — an icon plus a name, small and quiet. Never
/// competes with the quota value for attention.
struct ProviderBadge: View {
    let provider: AgentProvider
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.28) {
            Image(systemName: provider.symbolName)
                .font(.system(size: size * 0.85, weight: .medium))
                .foregroundStyle(Color(provider.accent))
            Text(provider.name)
                .font(UsageTypography.providerBadge(size: size))
                .foregroundStyle(.white.opacity(UsageOpacity.secondary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Provider: \(provider.name)")
    }
}
