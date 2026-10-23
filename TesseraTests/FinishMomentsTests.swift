import Foundation
@testable import Tessera
import Testing

struct FinishMomentsTests {
    @Test func packingListsSayAllPacked() {
        #expect(FinishMoments.listLine(name: "Packing") == "All packed.")
        #expect(FinishMoments.listLine(name: "Weekend PACK list") == "All packed.")
        #expect(FinishMoments.listLine(name: "Films") == "All done.")
    }

    @Test func tasksClauseNeedsSomethingDone() {
        #expect(FinishMoments.tasksClause(done: 0) == nil)
        #expect(FinishMoments.tasksClause(done: 1) == "1 done today.")
        #expect(FinishMoments.tasksClause(done: 4) == "4 done today.")
    }

    @Test func pickOneAndEmptyListsHaveNoMoment() {
        #expect(FinishMoments.listIsFinished(left: 0, total: 5, isPickOne: false))
        #expect(!FinishMoments.listIsFinished(left: 0, total: 5, isPickOne: true))
        #expect(!FinishMoments.listIsFinished(left: 0, total: 0, isPickOne: false))
        #expect(!FinishMoments.listIsFinished(left: 1, total: 5, isPickOne: false))
    }

    @Test func switchDefaultsOff() throws {
        let defaults = try #require(UserDefaults(suiteName: "FinishMomentsTests.\(UUID().uuidString)"))
        #expect(!FinishMoments.isOn(defaults: defaults))
        defaults.set("On", forKey: "review.finishMoments")
        #expect(FinishMoments.isOn(defaults: defaults))
        let choice = ReviewChoices.all.first { $0.id == FinishMoments.switchID }
        #expect(choice?.defaultValue == "Off")
        #expect(choice?.readiness == .live)
    }
}
