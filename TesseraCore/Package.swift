// swift-tools-version: 6.2
import PackageDescription

/// The Tessera kernel: classes, objects, links, computed values and persistence.
/// No UI. The app imports it as `TesseraCore`; tests run on the Mac with `swift test`.
let package = Package(
    name: "TesseraCore",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "TesseraCore", targets: ["TesseraCore"]),
    ],
    targets: [
        .target(
            name: "TesseraCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TesseraCoreTests",
            dependencies: ["TesseraCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
