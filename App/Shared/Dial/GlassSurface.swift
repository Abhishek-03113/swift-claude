import SwiftUI

/// The dial's core surface: a raised glass dome, not a translucency blur.
/// The design specifies its own gradient (lighter at the top, darkening
/// toward the edge) plus an inset rim highlight — a system `Material` reads
/// as flat and near-black against the dial's dark background, losing the
/// "instrument glass" look, so the recipe is authored explicitly here
/// instead.
struct GlassSurface<Content: View>: View {
    let diameter: CGFloat
    @ViewBuilder var content: () -> Content

    private var background: RadialGradient {
        RadialGradient(
            colors: [Color(hex: "1e242e"), Color(hex: "0d1015"), Color(hex: "080a0e")],
            center: UnitPoint(x: 0.5, y: 0.14),
            startRadius: 0,
            endRadius: diameter * 0.64
        )
    }

    var body: some View {
        content().background(background, in: Circle())
    }
}

private extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255
        )
    }
}
