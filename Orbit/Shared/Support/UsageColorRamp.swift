import Foundation

/// The green → amber → red ramp lifted directly from the approved design
/// file (`Runway Widget.dc.html`), keyed by usage (0 = untouched quota,
/// 100 = fully consumed). Kept provider-agnostic and UI-framework-agnostic:
/// it returns plain component values, not `Color`, so it's usable from the
/// domain/presentation boundary and from unit tests without importing
/// SwiftUI.
public enum UsageColorRamp {
    public struct Stop {
        let at: Double
        let rgb: (Double, Double, Double)
    }

    static let stops: [Stop] = [
        Stop(at: 0,   rgb: (62,  226, 149)),
        Stop(at: 20,  rgb: (95,  224, 140)),
        Stop(at: 40,  rgb: (134, 223, 118)),
        Stop(at: 55,  rgb: (174, 216, 99)),
        Stop(at: 65,  rgb: (206, 206, 92)),
        Stop(at: 75,  rgb: (232, 194, 90)),
        Stop(at: 82,  rgb: (240, 170, 80)),
        Stop(at: 90,  rgb: (243, 138, 72)),
        Stop(at: 95,  rgb: (250, 112, 74)),
        Stop(at: 100, rgb: (255, 82,  78)),
    ]

    /// - Parameter usagePercent: 0...100, consumption of the quota. Values
    ///   outside that range are clamped so a malformed reading never breaks
    ///   color interpolation.
    /// - Returns: sRGB components in 0...1.
    public static func components(forUsagePercent usagePercent: Double) -> (red: Double, green: Double, blue: Double) {
        let u = min(max(usagePercent, 0), 100)
        var a = stops[0]
        var b = stops[stops.count - 1]
        for i in 0..<(stops.count - 1) {
            if u >= stops[i].at && u <= stops[i + 1].at {
                a = stops[i]
                b = stops[i + 1]
                break
            }
        }
        let t = b.at == a.at ? 0 : (u - a.at) / (b.at - a.at)
        func lerp(_ x: Double, _ y: Double) -> Double { (x + (y - x) * t) / 255 }
        return (lerp(a.rgb.0, b.rgb.0), lerp(a.rgb.1, b.rgb.1), lerp(a.rgb.2, b.rgb.2))
    }

    public static func token(forUsagePercent usagePercent: Double) -> ColorToken {
        let c = components(forUsagePercent: usagePercent)
        return ColorToken(red: c.red, green: c.green, blue: c.blue)
    }
}
