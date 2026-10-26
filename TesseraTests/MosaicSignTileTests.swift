import CoreGraphics
@testable import Tessera
import Testing

/// Sheet 283 (his 4:57 PM note): Bridge's widget sign is laid exactly like the keystone mosaic, 20 x 20 cells of 4 pt,
/// each tile 3.6 pt on a light page and 3.2 pt on black, with the page showing between them as grout. Never one merged
/// block.
struct MosaicSignTileTests {
    @Test func theSignIsTwentyCellsOfFourPoints() {
        #expect(ThingSignArt.side == 20)
        #expect(MosaicScreenGrid.step == 4)
        #expect(CGFloat(ThingSignArt.side) * MosaicScreenGrid.step == 80)
    }

    @Test func tilesLeaveGroutOnLightAndDarkPages() {
        #expect(MosaicScreenGrid.lightSide == 3.6)
        #expect(MosaicScreenGrid.side == 3.2)
        let grid = MosaicScreenGrid(size: CGSize(width: 80, height: 80), coreTop: 0)
        for side in [MosaicScreenGrid.lightSide, MosaicScreenGrid.side] {
            let tile = grid.rect(column: 3, row: 5, side: side)
            let next = grid.rect(column: 4, row: 5, side: side)
            let below = grid.rect(column: 3, row: 6, side: side)
            #expect(tile.width == side && tile.height == side)
            // The page shows between neighbours, across and down: the tiles never touch or merge.
            #expect(next.minX - tile.maxX > 0.3)
            #expect(below.minY - tile.maxY > 0.3)
            // Each tile sits centred in its own 4 pt cell.
            #expect(abs(tile.midX - (3.5 * MosaicScreenGrid.step)) < 0.001)
        }
    }

    @Test func everySignKindStaysInsideItsTwentyCells() {
        for kind in ThingSignKind.allCases {
            let cells = ThingSignArt.cells(kind, elapsed: 0, still: true)
            #expect(!cells.isEmpty, "\(kind)")
            #expect(cells
                .allSatisfy {
                    (0 ..< ThingSignArt.side).contains($0.column) && (0 ..< ThingSignArt.side).contains($0.row)
                })
        }
    }
}
