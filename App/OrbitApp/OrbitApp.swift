import SwiftUI

@main
struct OrbitApp: App {
    init() {
        // Installs or updates OrbitAgent, the background login item that
        // keeps usage fresh whether or not this window is open. Cheap and
        // idempotent, so it runs on every launch rather than only the first.
        DaemonRegistration.registerIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 620)
        // `.contentMinSize` makes the window honour the floor ContentView
        // declares on the split view itself. Declaring it out here instead
        // doesn't hold: NavigationSplitView reports its own sizing and the
        // height minimum gets dropped.
        .windowResizability(.contentMinSize)
    }
}
