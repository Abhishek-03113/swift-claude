import CoreGraphics
import Foundation

/// Which of the two concentric rings this is. Carries geometry only — the
/// mapping from "session"/"weekly" onto inner/outer belongs to
/// `DialPresentationBuilder`, not here.
public enum RingStyle: Sendable {
    case inner
    case outer

    /// Radial extent of the ring's tick band, as fractions of dial radius.
    public var band: (inner: CGFloat, outer: CGFloat) {
        switch self {
        case .inner: return (DialMetrics.innerRingInner, DialMetrics.innerRingOuter)
        case .outer: return (DialMetrics.outerRingInner, DialMetrics.outerRingOuter)
        }
    }

    public var tickCount: Int {
        switch self {
        case .inner: return DialMetrics.innerTickCount
        case .outer: return DialMetrics.outerTickCount
        }
    }

    public var dutyCycle: CGFloat {
        switch self {
        case .inner: return DialMetrics.innerTickDutyCycle
        case .outer: return DialMetrics.outerTickDutyCycle
        }
    }
}
