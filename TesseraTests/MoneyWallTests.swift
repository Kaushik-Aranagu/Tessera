import Foundation
import Testing

/// The money wall (Kaushik, Oct 25): amounts show inside the Purse room only. Home, the doorway into a room, system
/// widgets, Live Activities and the shared surfaces never read a money amount. The test reads the source files, so a
/// later change that pulls an amount type into one of those places fails here.
@Suite struct MoneyWallTests {
    private static let root: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()

    private static let forbidden = ["MoneyAmount", "MoneyTrend", "PurseSeries", "PurseBook", "PurseChart",
                                    "MoneyLandingFacts", "PurseIndexView", ".currency"]

    private func swiftFiles(under folder: String) -> [URL] {
        let base = Self.root.appendingPathComponent(folder)
        guard let walker = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else { return [] }
        return walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }

    @Test(arguments: ["Features/Home", "Features/Surfaces", "Shared"])
    func noMoneyAmountOutsideThePurse(folder: String) throws {
        let files = swiftFiles(under: folder)
        #expect(!files.isEmpty, "\(folder) has source files to scan")
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for token in Self.forbidden {
                #expect(!text.contains(token), "\(file.lastPathComponent) reads money (\(token)) outside the Purse")
            }
        }
    }

    @Test func theDoorwayNeverReadsMoney() throws {
        let text = try String(contentsOf: Self.root.appendingPathComponent("Features/Home/Doorway.swift"), encoding: .utf8)
        for token in Self.forbidden {
            #expect(!text.contains(token))
        }
    }
}
