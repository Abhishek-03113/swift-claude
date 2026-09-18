import Foundation
import OSLog
import ServiceManagement

/// Registers `OrbitAgent` — the background login item that owns fetching —
/// as a `SMAppService` agent, so installing or updating Orbit.app is what
/// installs or updates the daemon. No separate installer, no LaunchAgent
/// plist the user has to trust or `launchctl load` by hand.
///
/// `SMAppService.agent(plistName:)` reads
/// `Contents/Library/LaunchAgents/com.orbit.agent.plist` inside the app
/// bundle, which XcodeGen copies there from `App/OrbitAgent/Launchd.plist`.
enum DaemonRegistration {
    private static let logger = Logger(subsystem: "com.abhishek00edu.orbit", category: "DaemonRegistration")

    private static let service = SMAppService.agent(plistName: "com.orbit.agent.plist")

    /// Called once on app launch. Registering an already-registered service
    /// is a no-op, so this is safe to call on every launch rather than only
    /// on first install.
    static func registerIfNeeded() {
        switch service.status {
        case .notRegistered, .notFound:
            do {
                try service.register()
            } catch {
                logger.error("Failed to register OrbitAgent: \(error, privacy: .public)")
            }
        case .enabled:
            break
        case .requiresApproval:
            // The user disabled it, or macOS wants Login Items approval.
            // Nothing to do here beyond surfacing this in Settings — Orbit
            // still works with the daemon off, just without a live tap.
            logger.notice("OrbitAgent requires Login Items approval in System Settings.")
        @unknown default:
            break
        }
    }
}
