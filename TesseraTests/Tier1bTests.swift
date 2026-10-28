import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Tier 1b (164 undoLogV2, 169 backupsV2, 179 walledPageV2): each behind its own Review switch, default Off.
@MainActor
struct Tier1bTests {
    @Test func theThreeSwitchesAreLiveAndDefaultOff() throws {
        for id in [Tier1b.walledID, Tier1b.backupsID, Tier1b.undoID] {
            let choice = try #require(ReviewChoices.all.first { $0.id == id })
            #expect(choice.defaultValue == "Off")
            #expect(choice.readiness == .live)
            #expect(choice.values == ["Off", "On"])
        }
    }

    @Test func offLeavesTheAppAsItWas() throws {
        let choices = try ReviewChoices(
            defaults: #require(UserDefaults(suiteName: "tier1b-\(UUID().uuidString)")),
            writes: false
        )
        #expect(choices.value(of: Tier1b.walledID) == "Off")
        #expect(choices.value(of: Tier1b.backupsID) == "Off")
        #expect(choices.value(of: Tier1b.undoID) == "Off")
    }

    @Test func theFacetNamesThemWithinSix() throws {
        let facet = try #require(ReviewChoices.facets.first { $0.word == "Safe keeping" })
        #expect(facet.ids == [Tier1b.walledID, Tier1b.backupsID, Tier1b.undoID])
        #expect(ReviewChoices.facets.allSatisfy { $0.ids.count <= 6 })
    }

    @Test func undoSaysCoresLineAndReversedForMoney() {
        #expect(UndoWords.said(.putBack(line: "Put back"), money: false) == "Put back")
        #expect(UndoWords.said(.putBack(line: "Put back"), money: true) == "Reversed")
        #expect(UndoWords.said(.blocked(line: "Can't put that back"), money: true) == "Can't put that back")
        #expect(UndoWords.said(.gone, money: false) == nil)
    }

    @Test func backupPreviewHoldsTenMinutes() {
        #expect(BackupPreview.undoWindow == .seconds(600))
        #expect(UndoLog.window == 600)
    }

    @Test func notIncludedIsSaidOnlyForTheFolderCopy() {
        #expect(BackupWords.notIncluded(leavingOutPrivate: true).contains("private"))
        #expect(!BackupWords.notIncluded(leavingOutPrivate: false).contains("private"))
    }
}
