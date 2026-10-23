import Foundation
@testable import Tessera
import Testing

@MainActor
struct HomeMosaicTests {
    @Test func switchesDefaultOff() {
        for id in [HomeMosaic.choiceID, HomeMosaic.appsListID] {
            let choice = ReviewChoices.all.first { $0.id == id }
            #expect(choice?.defaultValue == "Off")
            #expect(choice?.readiness == .live)
        }
        #expect(!HomeMosaic.isOn)
        #expect(!HomeMosaic.appsListIsOn)
    }

    @Test func sentenceKeepsTheFirstThreeClauses() {
        #expect(HomeMosaic.firstThree([1, 2, 3, 4, 5]) == [1, 2, 3])
        #expect(HomeMosaic.firstThree([1, 2]) == [1, 2])
        #expect(HomeMosaic.firstThree([Int]()).isEmpty)
    }

    @Test func oneRowIsOpenAtATime() {
        let first = UUID(), second = UUID()
        var rows = OneOpenRow()
        rows.tap(first)
        #expect(rows.isOpen(first))
        rows.tap(second)
        #expect(!rows.isOpen(first) && rows.isOpen(second))
        rows.tap(second)
        #expect(rows.open == nil)
        rows.tap(first)
        rows.close()
        #expect(rows.open == nil)
    }
}
