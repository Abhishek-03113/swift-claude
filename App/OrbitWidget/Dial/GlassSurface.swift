import SwiftUI

/// Wraps the dial's core in the Liquid Glass material where the running OS
/// supports it, falling back to a system `Material` below that. The only
/// place either API is referenced, so the treatment can evolve without
/// touching the dial's content views.
struct GlassSurface<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(macOS 26.0, *) {
            content().glassEffect(.regular, in: Circle())
        } else {
            content().background(.thinMaterial, in: Circle())
        }
    }
}
