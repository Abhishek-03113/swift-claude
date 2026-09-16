import Foundation

/// The green -> amber -> red ramp from the approved design file, keyed by
/// usage (0 = untouched quota, 100 = fully consumed).
///
/// Returns plain components rather than a `Color` so it stays usable from the
/// model layer and from tests without importing SwiftUI.
public enum UsageColorRamp {
    struct Stop {
        let at: Double
        let rgb: (red: Double, green: Double, blue: Double)
    }

    static let stops: [Stop] = [
        Stop(at: 0, rgb: (62, 226, 149)),
        Stop(at: 20, rgb: (95, 224, 140)),
        Stop(at: 40, rgb: (134, 223, 118)),
        Stop(at: 55, rgb: (174, 216, 99)),
        Stop(at: 65, rgb: (206, 206, 92)),
        Stop(at: 75, rgb: (232, 194, 90)),
        Stop(at: 82, rgb: (240, 170, 80)),
        Stop(at: 90, rgb: (243, 138, 72)),
        Stop(at: 95, rgb: (250, 112, 74)),
        Stop(at: 100, rgb: (255, 82, 78)),
    ]

    /// - Parameter usagePercent: consumption in `0...100`. Values outside that
    ///   range are clamped, so a malformed reading never breaks interpolation.
    /// - Returns: sRGB components in `0...1`.
    public static func components(forUsagePercent usagePercent: Double) -> (red: Double, green: Double, blue: Double) {
        let usage = min(max(usagePercent, 0), 100)

        let (lower, upper) = surroundingStops(for: usage)
        let span = upper.at - lower.at
        let t = span == 0 ? 0 : (usage - lower.at) / span

        func interpolate(_ from: Double, _ to: Double) -> Double {
            (from + (to - from) * t) / 255
        }

        return (
            interpolate(lower.rgb.red, upper.rgb.red),
            interpolate(lower.rgb.green, upper.rgb.green),
            interpolate(lower.rgb.blue, upper.rgb.blue)
        )
    }

    public static func token(forUsagePercent usagePercent: Double) -> ColorToken {
        let components = components(forUsagePercent: usagePercent)
        return ColorToken(red: components.red, green: components.green, blue: components.blue)
    }

    private static func surroundingStops(for usage: Double) -> (lower: Stop, upper: Stop) {
        for index in 0..<(stops.count - 1) where usage >= stops[index].at && usage <= stops[index + 1].at {
            return (stops[index], stops[index + 1])
        }
        return (stops[0], stops[stops.count - 1])
    }
}
