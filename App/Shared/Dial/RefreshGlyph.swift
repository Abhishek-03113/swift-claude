import OrbitPresentation
import SwiftUI

/// The refresh icon's one visual definition — an `arrow.clockwise` glyph
/// sized and weighted the same everywhere it appears, so the app's toolbar
/// button and the widget's on-dial refresh control read as the same
/// affordance rather than two different pieces of chrome that happen to do
/// the same thing.
///
/// Color is the one thing left to the call site: the widget always sits on
/// its own dark background, but a toolbar button has to follow the system's
/// label styling (tint on press, appearance-aware otherwise) — `.white` there
/// would look wrong in light mode.
struct RefreshGlyph: View {
    var size: CGFloat = 12
    var color: Color = .white.opacity(UsageOpacity.secondary)

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
    }
}
