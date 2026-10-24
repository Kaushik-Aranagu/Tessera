import Foundation
@testable import Tessera
import Testing

struct ThingSignArtTests {
    @Test func everySignDrawsInsideItsEighteenByEighteenTiles() {
        for kind in ThingSignKind.allCases {
            for time in stride(from: 0.0, to: 3.0, by: 0.37) {
                let cells = ThingSignArt.cells(kind, elapsed: time)
                #expect(!cells.isEmpty, "\(kind) at \(time)")
                #expect(cells.allSatisfy { (0 ..< 18).contains($0.column) && (0 ..< 18).contains($0.row) })
                #expect(Set(cells.map { [$0.column, $0.row] }).count == cells.count)
            }
        }
    }

    @Test func theBarbellLiftsAndTheSunTurns() throws {
        let rest = ThingSignArt.cells(.training, elapsed: 0)
        let lifted = ThingSignArt.cells(.training, elapsed: 0.7)
        #expect(rest != lifted)
        #expect(try #require(lifted.map(\.row).min()) < rest.map(\.row).min()!)
        #expect(ThingSignArt.cells(.weather, elapsed: 0) != ThingSignArt.cells(.weather, elapsed: 0.5))
    }

    @Test func theSuitcaseFillsToTheDoneShare() {
        func full(_ share: Double) -> Int {
            ThingSignArt.cells(.list, elapsed: 0, share: share).filter { $0.strength == 1 }.count
        }
        #expect(full(0) == 0 && full(0.5) == 60 && full(1) == 120)
    }

    @Test func stillSignsDoNotMoveUnderReduceMotion() {
        for kind in ThingSignKind.allCases {
            #expect(ThingSignArt.cells(kind, elapsed: 0.4, still: true) == ThingSignArt.cells(
                kind,
                elapsed: 2.9,
                still: true
            ))
        }
    }

    @Test func strengthStepsInWholeEighths() {
        #expect(ThingSignArt.stepped(0.7) == 0.75 && ThingSignArt.stepped(1.4) == 1 && ThingSignArt.stepped(-1) == 0)
    }
}
