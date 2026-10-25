import CoreGraphics
import Testing
@testable import Tessera

@Suite struct WordWallLayoutTests {
    private func advance(_ text: String) -> CGFloat { CGFloat(text.count) * 0.68 }

    private func words(_ names: [String]) -> [WallWord] {
        names.enumerated().map { WallWord(id: "w\($0.offset)", text: $0.element, weight: 1 - Double($0.offset) * 0.03) }
    }

    @Test func bricksStayInsideAndReachBothEdges() {
        let size = CGSize(width: 354, height: 220)
        let names = ["Plumber", "Ideas", "Trip", "Bar felt heavy", "Rent", "Pasta", "Gift", "Call mom", "Sleep",
                     "Books", "Tax", "Garden", "Dentist", "Paint"]
        let bricks = WordWallLayout.pack(words: words(names), size: size, advance: advance)
        #expect(!bricks.isEmpty)
        for brick in bricks {
            #expect(brick.frame.minX >= -0.01 && brick.frame.maxX <= size.width + 0.5)
            #expect(brick.frame.minY >= -0.01 && brick.frame.maxY <= size.height + 0.5)
            #expect(brick.fontSize >= WordWallLayout.minimumSize)
        }
        let rows = Dictionary(grouping: bricks) { $0.frame.minY }
        for row in rows.values {
            #expect(abs((row.map(\.frame.maxX).max() ?? 0) - size.width) < 0.5)
            #expect(abs((row.map(\.frame.minX).min() ?? 1)) < 0.5)
        }
    }

    @Test func noTwoBricksOverlap() {
        let bricks = WordWallLayout.pack(words: words(["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"]),
                                         size: CGSize(width: 354, height: 220), advance: advance)
        for (i, a) in bricks.enumerated() {
            for b in bricks[(i + 1)...] {
                #expect(!a.frame.insetBy(dx: 0.1, dy: 0.1).intersects(b.frame.insetBy(dx: 0.1, dy: 0.1)))
            }
        }
    }

    @Test func neighbouringColoursDiffer() {
        let bricks = WordWallLayout.pack(words: words(["A1", "B22", "C333", "D4444", "E55555", "F6", "G77"]),
                                         size: CGSize(width: 354, height: 220), advance: advance)
        for pair in zip(bricks, bricks.dropFirst()) {
            #expect(pair.0.colorIndex != pair.1.colorIndex)
        }
    }

    @Test func fewWordsStillFillTheWall() {
        let bricks = WordWallLayout.pack(words: words(["Rent"]), size: CGSize(width: 354, height: 220), advance: advance)
        #expect(bricks.count == 1)
        #expect(bricks[0].fontSize == WordWallLayout.maximumSize)
    }

    @Test func emptyWallIsEmpty() {
        #expect(WordWallLayout.pack(words: [], size: CGSize(width: 354, height: 220), advance: advance).isEmpty)
    }
}
