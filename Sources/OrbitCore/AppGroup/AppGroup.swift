import Foundation

/// The App Group shared by the host app and the widget extension.
///
/// Read from the bundle rather than hard-coded, because the correct value
/// differs per developer and per target configuration. macOS requires a
/// **team-ID-prefixed** group identifier (`ABCDE12345.group.com.orbit.app`)
/// for a non-sandboxed app — which Orbit's app is, since reading Claude Code's
/// usage means running its CLI and the sandbox forbids that. The widget
/// extension is sandboxed, as extensions must be, and both must name the same
/// group or they silently read different containers.
///
/// `ORBIT_APP_GROUP` is set in `App/project.yml` and injected into both
/// targets' Info.plists and entitlements from one place.
public enum AppGroup {
    /// Used when the key is absent, e.g. in package unit tests that have no
    /// app bundle around them.
    public static let fallbackIdentifier = "group.com.orbit.app"

    public static let identifier: String = {
        guard let configured = Bundle.main.object(forInfoDictionaryKey: "ORBIT_APP_GROUP") as? String,
              !configured.isEmpty,
              // An unexpanded build setting means the project wasn't configured.
              !configured.hasPrefix("$(") else {
            return fallbackIdentifier
        }
        return configured
    }()
}
