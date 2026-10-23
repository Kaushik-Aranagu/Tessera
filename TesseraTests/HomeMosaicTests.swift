import Foundation
@testable import Tessera
import TesseraCore
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

    /// A task with a walled word reads by its label everywhere Next shows it (QA on #1292).
    @Test func aWalledTitleReadsPrivate() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        let task = try #require(try? model.engine.perform(CreateTask(title: "Lexapro refill"), by: .user).output)
        let label = ObjectPrivacy.shownLabel(of: task, in: model.store, classes: model.classes)
        #expect(label == ObjectPrivacy.taskLabel)
        let plain = try #require(try? model.engine.perform(CreateTask(title: "Call the dentist"), by: .user).output)
        #expect(ObjectPrivacy.shownLabel(of: plain, in: model.store, classes: model.classes) == nil)
    }
}
