// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StorageSpike",
    platforms: [.macOS("27.0")],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Bench",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "SQLiteDataProbe",
            dependencies: [.product(name: "SQLiteData", package: "sqlite-data")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
