import Foundation

/// The single place that knows how Orbit persists small values into the
/// shared App Group container. Both things the widget remembers — the last
/// known-good snapshot and the currently focused period — go through here,
/// so there is one JSON strategy and one suite name rather than a copy per
/// call site.
///
/// `UserDefaults` is documented as thread-safe, so no additional locking is
/// needed; the `@unchecked` conformance only works around its lack of a
/// `Sendable` annotation.
public struct AppGroupStore: @unchecked Sendable {
    public static let shared = AppGroupStore()

    private let defaults: UserDefaults?

    /// - Parameter suiteName: defaults to the shared App Group. Tests pass a
    ///   unique suite so they never collide with each other or with the
    ///   installed widget's real state.
    public init(suiteName: String = AppGroup.identifier) {
        self.defaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Codable values

    public func read<Value: Decodable>(_ type: Value.Type = Value.self, forKey key: String) -> Value? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    public func write<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }

    // MARK: - Raw string values

    /// Stored plainly rather than as JSON, so single-token values stay
    /// readable in `defaults read` output when debugging a live widget.
    public func readString(forKey key: String) -> String? {
        defaults?.string(forKey: key)
    }

    public func writeString(_ value: String, forKey key: String) {
        defaults?.set(value, forKey: key)
    }
}
