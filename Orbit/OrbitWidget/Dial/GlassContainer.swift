import SwiftUI

/// Wraps content in the modern Liquid Glass material where the deployment
/// target supports it, falling back to a system `Material` on earlier
/// macOS. This is the only place either API is referenced, so the glass
/// treatment can evolve without touching the dial's actual content views.
struct GlassSurface<Content: View>: View {
    var shape: AnyDialShape = AnyDialShape(Circle())
    var interactive: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(macOS 26.0, *) {
            content()
                .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            content()
                .background(.thinMaterial, in: shape)
        }
    }
}

/// Type-erased shape wrapper, since `GlassSurface` needs to accept either a
/// `Circle` (the dial core) or other shapes without becoming generic over
/// `Shape` at every call site. Named distinctly from SwiftUI's own
/// `AnyShape` (macOS 14+) to avoid any ambiguity between the two.
struct AnyDialShape: Shape {
    private let path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) {
        path = { rect in shape.path(in: rect) }
    }
    func path(in rect: CGRect) -> Path { path(rect) }
}
