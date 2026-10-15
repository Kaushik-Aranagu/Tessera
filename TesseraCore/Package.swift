// swift-tools-version: 6.2
import PackageDescription

/// The Tessera kernel: classes, objects, links, computed values and persistence.
/// No UI. The app imports it as `TesseraCore`; tests run on the Mac with `swift test`.
///
/// - `TesseraCore`: the engine.
/// - `TesseraTess`: Tess's engine side (capture: grammar, then the on-device model), behind `TessCapturing`.
/// - `TesseraIntents`: App Intents and Shortcuts over the same typed actions.
let package = Package(
    name: "TesseraCore",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "TesseraCore", targets: ["TesseraCore"]),
        .library(name: "TesseraTess", targets: ["TesseraTess"]),
        .library(name: "TesseraIntents", targets: ["TesseraIntents"]),
    ],
    targets: [
        .target(
            name: "TesseraCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "TesseraTess",
            dependencies: ["TesseraCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "TesseraIntents",
            dependencies: ["TesseraCore", "TesseraTess"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TesseraCoreTests",
            dependencies: ["TesseraCore", "TesseraTess", "TesseraIntents"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
