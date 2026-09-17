import OrbitCore
import SwiftUI

extension Color {
    /// The one place a `ColorToken` becomes a SwiftUI `Color`, keeping every
    /// layer below the views free of a SwiftUI dependency.
    init(_ token: ColorToken) {
        self.init(.sRGB, red: token.red, green: token.green, blue: token.blue, opacity: 1)
    }
}
