import Foundation

/// Central place for the App Group identifier shared by the host app and the
/// widget extension. Referenced from `project.yml` entitlements — keep both
/// in sync if this ever changes.
public enum AppGroup {
    public static let identifier = "group.com.orbit.app"
}
