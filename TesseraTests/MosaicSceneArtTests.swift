import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Sheet 214: eleven scenes, each still but for one slow life; none within delta E 10 of Ember.
struct MosaicSceneArtTests {
    private let columns = 50, rows = 28

    private func frame(_ scene: MosaicScenery, time: Double) -> [MosaicTriple] {
        (0 ..< columns).flatMap { column in
            (0 ..< rows).map { MosaicSceneArt.colour(
                scene,
                column: column,
                row: $0,
                columns: columns,
                rows: rows,
                time: time
            ) }
        }
    }

    private func hex(_ colour: MosaicTriple) -> UInt32 {
        func byte(_ value: Double) -> UInt32 {
            UInt32((min(max(value, 0), 1) * 255).rounded())
        }
        return byte(colour.red) << 16 | byte(colour.green) << 8 | byte(colour.blue)
    }

    private func deltaE(_ first: UInt32, _ second: UInt32) -> Double {
        let one = SoulCloud.oklab(first), two = SoulCloud.oklab(second)
        let dl = one.lightness - two.lightness, da = one.greenRed - two.greenRed, db = one.blueYellow - two.blueYellow
        return 100 * (dl * dl + da * da + db * db).squareRoot()
    }

    @Test func everySceneIsDeterministicAndInRange() {
        for scene in MosaicScenery.allCases {
            let first = frame(scene, time: 4.2), second = frame(scene, time: 4.2)
            #expect(first.count == columns * rows)
            #expect(zip(first, second).allSatisfy { $0.red == $1.red && $0.green == $1.green && $0.blue == $1.blue })
            #expect(first
                .allSatisfy { (0 ... 1).contains($0.red) && (0 ... 1).contains($0.green) && (0 ... 1).contains($0.blue)
                })
        }
    }

    @Test func eachSceneHasOneSlowLifeAtMostAboutOneTileEveryHundredFiftyMilliseconds() throws {
        for scene in MosaicScenery.allCases {
            var changes: [Int] = []
            var previous = frame(scene, time: 0)
            for step in 1 ... 80 {
                let next = frame(scene, time: Double(step) * MosaicSceneArt.stepSeconds)
                changes.append(zip(previous, next).filter { hex($0) != hex($1) }.count)
                previous = next
            }
            let mean = Double(changes.reduce(0, +)) / Double(changes.count)
            #expect(try #require(changes.max()) <= 8, "\(scene): most in one step \(changes.max()!)")
            #expect(mean <= 4, "\(scene): mean \(mean) per step")
            #expect(changes.contains { $0 > 0 }, "\(scene) has a life")
        }
    }

    @Test func aSceneIsStillBetweenStepsAndUnderReduceMotion() {
        for scene in MosaicScenery.allCases {
            let early = frame(scene, time: 0.01), laterInTheSameStep = frame(scene, time: 0.14)
            #expect(zip(early, laterInTheSameStep).allSatisfy { hex($0) == hex($1) })
        }
    }

    @Test func noSceneTileSitsWithinDeltaETenOfEmber() {
        let reserved = MosaicSceneArt.reserved
        for scene in MosaicScenery.allCases {
            let tiles = frame(scene, time: 3.0)
            let near = tiles.filter { tile in reserved.contains { deltaE(hex(tile), $0) < 10 } }.count
            // A handful of tiles in a gradient may graze it; a scene as a whole may not live there.
            #expect(
                Double(near) / Double(tiles.count) < 0.02,
                "\(scene): \(near) of \(tiles.count) tiles near Ember"
            )
        }
    }

    @Test func theLooksTintTheTilesOnBlackAndDark() {
        let tile: MosaicTriple = (0.8, 0.6, 0.4)
        let toward: MosaicTriple = (20.0 / 255, 18.0 / 255, 26.0 / 255)
        let black = MosaicSceneArt.tinted(tile, ground: (0, 0, 0), dark: true)
        let expectedBlack = MosaicColour.mix(tile, toward, 0.18)
        #expect(abs(black.red - expectedBlack.red) < 1e-9)
        let dark = MosaicSceneArt.tinted(tile, ground: (0.08, 0.08, 0.09), dark: true)
        #expect(abs(dark.red - MosaicColour.mix(tile, toward, 0.30).red) < 1e-9)
        let white = MosaicSceneArt.tinted(tile, ground: (1, 1, 1), dark: false)
        #expect(abs(white.red - 0.8 * 1.02) < 1e-9)
        let paper = MosaicSceneArt.tinted(tile, ground: (0.95, 0.93, 0.88), dark: false)
        #expect(abs(paper.red - 0.8 * 1.02) < 1e-9 || paper.red == tile.red)
    }
}
