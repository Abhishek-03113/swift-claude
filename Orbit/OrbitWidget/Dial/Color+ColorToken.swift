import SwiftUI

extension Color {
    init(_ token: ColorToken) {
        self.init(.sRGB, red: token.red, green: token.green, blue: token.blue, opacity: 1)
    }
}
