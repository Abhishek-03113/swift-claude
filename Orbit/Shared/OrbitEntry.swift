import Foundation

/// Data model shared between the host app and the widget extension.
/// Replace with whatever the widget actually needs to display.
struct OrbitSnapshotData: Codable, Equatable {
    var title: String
    var value: String
    var updatedAt: Date

    static let placeholder = OrbitSnapshotData(
        title: "Orbit",
        value: "--",
        updatedAt: .now
    )
}

/// Reads/writes shared state via the App Group container so the widget
/// and host app can exchange data. Update `appGroupID` to match the
/// group configured in project.yml and both entitlements files.
enum OrbitSharedStore {
    static let appGroupID = "group.com.orbit.app"
    private static let storageKey = "orbit.snapshot"

    static func save(_ data: OrbitSnapshotData) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: storageKey)
    }

    static func load() -> OrbitSnapshotData {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(OrbitSnapshotData.self, from: raw) else {
            return .placeholder
        }
        return decoded
    }
}
