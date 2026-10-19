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
        choices.step(pageTurn)
        #expect(choices.value(of: pageTurn) == "Turn")
        #expect(defaults.string(forKey: "review.pageTurn") == "Turn")
        #expect(ReviewChoices(defaults: defaults, writes: true).value(of: pageTurn) == "Turn")
        choices.step(pageTurn, forward: false)
        choices.step(pageTurn, forward: false)
        #expect(choices.value(of: pageTurn) == "Rotate")
        #expect(choices.beforeAfter(pageTurn, before: "Slide")
            == "Before: Pages slide across, as now. Now: Pages rotate on their edge.")
        choices.resetAll([pageTurn])
        #expect(choices.value(of: pageTurn) == "Slide")
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

    @Test func pagesHoldSixOrFewer() {
        let pages = ReviewChoices.pages()
        #expect(pages.allSatisfy { $0.count <= 6 })
        #expect(pages.flatMap(\.self).count == ReviewChoices.all.count)
    }
}
