import Foundation

/// The App Group shared by the host app and the widget extension.
///
/// Also declared in `App/project.yml` entitlements for both targets — the two
/// must stay in sync.
public enum AppGroup {
    public static let identifier = "group.com.orbit.app"
}
