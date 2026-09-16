// swift-tools-version: 5.9
import PackageDescription

// OrbitKit holds every part of Orbit that does not need SwiftUI, WidgetKit
// or AppIntents. Splitting it into three modules makes the layering the
// compiler's job rather than a convention documented in comments:
//
//   OrbitCore          provider-agnostic usage model + repository contract
//   OrbitProviders     adapters that produce a UsageSnapshot (Claude Code, mock)
//   OrbitPresentation  snapshot + selection -> fully resolved visual state
//
// OrbitPresentation cannot see OrbitProviders, so no provider-specific
// knowledge can reach the dial even by accident.
let package = Package(
    name: "OrbitKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "OrbitCore", targets: ["OrbitCore"]),
        .library(name: "OrbitProviders", targets: ["OrbitProviders"]),
        .library(name: "OrbitPresentation", targets: ["OrbitPresentation"]),
    ],
    targets: [
        .target(name: "OrbitCore"),
        .target(name: "OrbitProviders", dependencies: ["OrbitCore"]),
        .target(name: "OrbitPresentation", dependencies: ["OrbitCore"]),

        .testTarget(name: "OrbitCoreTests", dependencies: ["OrbitCore"]),
        .testTarget(name: "OrbitProvidersTests", dependencies: ["OrbitProviders"]),
        .testTarget(name: "OrbitPresentationTests", dependencies: ["OrbitPresentation", "OrbitProviders"]),
    ]
)
