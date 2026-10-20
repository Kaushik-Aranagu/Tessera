import Foundation
@testable import Tessera
import Testing

/// Batch 0: the review switches. Each defaults to today's behavior, keeps his pick on this iPhone only, cycles
/// through its values, and "Everything as before" puts them all back.
@MainActor
struct ReviewChoicesTests {
    private func fresh() throws -> (ReviewChoices, UserDefaults) {
        let name = "review-choices-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        return (ReviewChoices(defaults: defaults, writes: true), defaults)
    }

    private func choice(_ id: String) throws -> ReviewChoices.Choice {
        try #require(ReviewChoices.all.first { $0.id == id })
    }

    @Test func everySwitchStartsAtTodaysBehavior() throws {
        let (choices, _) = try fresh()
        for choice in ReviewChoices.all {
            #expect(choice.values.contains(choice.defaultValue), "\(choice.id)")
            #expect(choice.values.allSatisfy { choice.says[$0] != nil }, "\(choice.id) says every value")
            #expect(choices.value(of: choice) == choice.defaultValue)
        }
        #expect(!choices.anyTrying())
        #expect(Set(ReviewChoices.all.map(\.id)).count == ReviewChoices.all.count)
    }

    @Test func aPickIsKeptAndEverythingAsBeforeResets() throws {
        let (choices, defaults) = try fresh()
        var pageTurn = try choice("pageTurn")
        pageTurn.readiness = .live
        #expect(choices.value(of: pageTurn) == "Today")
        choices.step(pageTurn)
        #expect(choices.value(of: pageTurn) == "Slide")
        #expect(defaults.string(forKey: "review.pageTurn") == "Slide")
        #expect(ReviewChoices(defaults: defaults, writes: true).value(of: pageTurn) == "Slide")
        choices.step(pageTurn, forward: false)
        choices.step(pageTurn, forward: false)
        #expect(choices.value(of: pageTurn) == "Rotate")
        #expect(choices.beforeAfter(pageTurn, before: "Today")
            == "Before: Pages change as they do now. Now: Pages rotate on their edge.")
        choices.resetAll([pageTurn])
        #expect(choices.value(of: pageTurn) == "Today")
        #expect(defaults.string(forKey: "review.pageTurn") == nil)
    }

    /// A switch whose feature hasn't landed shows today's value and can't be flipped.
    @Test func aWaitingSwitchDoesNotFlip() throws {
        let (choices, _) = try fresh()
        let calendar = try choice("calendar")
        #expect(calendar.readiness == .later)
        choices.step(calendar)
        #expect(choices.value(of: calendar) == "Off")
    }

    /// QA on #1096: setting a waiting switch straight to its new value leaves it at today's and writes nothing.
    @Test func setOnAWaitingSwitchWritesNothing() throws {
        let (choices, defaults) = try fresh()
        let calendar = try choice("calendar")
        choices.set(calendar, to: "On")
        #expect(choices.value(of: calendar) == "Off")
        #expect(defaults.string(forKey: "review.calendar") == nil)
        // A value kept on the phone from before reads as the default while the switch waits.
        defaults.set("On", forKey: "review.calendar")
        #expect(ReviewChoices(defaults: defaults, writes: true).value(of: calendar) == "Off")
    }

    /// Under -demo nothing is written: a pick lasts until the app quits.
    @Test func demoWritesNothing() throws {
        let name = "review-choices-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        let choices = ReviewChoices(defaults: defaults, writes: false)
        var nudge = try choice("finishNudge")
        nudge.readiness = .live
        choices.step(nudge)
        #expect(choices.value(of: nudge) == "On")
        #expect(defaults.string(forKey: "review.finishNudge") == nil)
    }

    /// Product's Oct 19 rows: the eight Kitchen v2 switches, the class inspector and calories burned, each Off by
    /// default with a line for every value, and none of them flips before its feature lands.
    @Test func theAddedRowsWaitAtOff() throws {
        let (choices, defaults) = try fresh()
        let ids = ["weekStrip", "repeatItems", "cookDouble", "parallelSteps", "cookNotes", "fixRecipe", "usuallyLine",
                   "aisleOrder", "classInspector", "caloriesBurned"]
        for id in ids {
            let row = try choice(id)
            #expect(row.values == ["Off", "On"] && row.defaultValue == "Off", "\(id)")
            #expect(row.says["Off"] != nil && row.says["On"] != nil, "\(id)")
            #expect(!row.needsClaude, "\(id)")
            #expect(row.readiness != .live, "\(id)")
            choices.step(row)
            #expect(choices.value(of: row) == "Off", "\(id)")
            #expect(defaults.string(forKey: "review.\(id)") == nil, "\(id)")
        }
        #expect(Set(ReviewChoices.all.map(\.id)).count == ReviewChoices.all.count)
    }

    @Test func pagesHoldSixOrFewer() {
        let pages = ReviewChoices.pages()
        #expect(pages.allSatisfy { $0.count <= 6 })
        #expect(pages.flatMap(\.self).count == ReviewChoices.all.count)
    }

    /// The three training switches are live and drive Builder A's readers through the same keys.
    @Test func theTrainingSwitchesReachTheirFeatures() throws {
        let (choices, defaults) = try fresh()
        for id in ["restTimer", "swapExercise", "finishNudge"] {
            #expect(try choice(id).readiness == .live, "\(id)")
        }
        #expect(Choice.restTimerIsOn(defaults: defaults) && !Choice.swapIsOneTap(defaults: defaults))
        try choices.step(choice("restTimer"))
        try choices.step(choice("swapExercise"))
        try choices.step(choice("finishNudge"))
        #expect(!Choice.restTimerIsOn(defaults: defaults))
        #expect(Choice.swapIsOneTap(defaults: defaults))
        #expect(Choice.finishNudgeIsOn(defaults: defaults))
    }
}
