import Foundation

public extension Duration {
    /// `Duration` as a plain seconds count. Used wherever quota math or
    /// serialization needs a scalar rather than the attosecond pair.
    var secondsDouble: Double {
        let c = components
        return Double(c.seconds) + Double(c.attoseconds) / 1e18
    }
}
