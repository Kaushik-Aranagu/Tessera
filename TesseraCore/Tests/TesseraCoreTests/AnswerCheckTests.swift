import Foundation
@testable import TesseraTess
import Testing

/// checks.md C6: every number Tess says must come from what she was given.
struct AnswerCheckTests {
    let check = AnswerCheck()

    @Test func aNumberFromTheQueryPasses() {
        let result = check.check(reply: "Your best bench at 5 is 92.5 kg, on Push Day",
                                 evidence: ["Bench at 5: 92.5 kg x 5, 3 Sep [Set] [Push Day]"])
        #expect(result.passed)
    }

    @Test func aMadeUpNumberFails() {
        let result = check.check(reply: "Your best bench at 5 is 95 kg",
                                 evidence: ["Bench at 5: 92.5 kg x 5, 3 Sep [Set]"])
        #expect(!result.passed && result.unsupported.map(\.text) == ["95 kg"])
    }

    @Test func theOtherUnitPassesWithinRounding() {
        #expect(check.check(reply: "That's about 204 lb", evidence: ["92.5 kg"]).passed)
        #expect(!check.check(reply: "That's about 215 lb", evidence: ["92.5 kg"]).passed)
        #expect(check.check(reply: "An hour and a half, 1.5 hours", evidence: ["90 min"]).passed)
    }

    @Test func thousandsAndWordsReadAsNumbers() {
        #expect(check.check(reply: "Push Day Monday: 8,420 kg in all", evidence: ["volume 8420 kg"]).passed)
        #expect(check.check(reply: "You did three workouts", evidence: ["3 workouts this week"]).passed)
        #expect(!check.check(reply: "You did four workouts", evidence: ["3 workouts this week"]).passed)
    }

    @Test func aChangeMayBeTheDifferenceOfTwoGivenNumbers() {
        let evidence = ["Bench e1RM this month 101 kg", "last month 98 kg"]
        #expect(check.check(reply: "101 kg, up 3 kg on last month", evidence: evidence).passed)
        #expect(!check.check(reply: "101 kg, up 5 kg on last month", evidence: evidence).passed)
        // Without a change word, a difference isn't support.
        #expect(!check.check(reply: "101 kg. 3 kg is the gap", evidence: evidence).passed)
        #expect(check.check(reply: "Chest got 4 more sets than last week", evidence: ["Chest 12", "Chest 8"]).passed)
    }

    @Test func timesDatesYearsAndOrdinalsAreNotChecked() {
        let reply = "On Oct 3, 2026 at 6:30 you trained at 7 am, your 2nd session that day, and on 12 September too"
        #expect(check.check(reply: reply, evidence: []).passed)
    }

    @Test func pathsAndDateStampsAreNotNumbers() {
        #expect(check.check(reply: "See /summaries/week/2026-W43 and 2026-10-23", evidence: []).passed)
    }

    @Test func hisOwnNumbersCanComeBack() {
        #expect(check.check(reply: "Logged: 100 kg for 5", evidence: [], ask: "log 100 kg for 5").passed)
    }

    @Test func moneyAndPercentKeepTheirUnits() {
        #expect(check.check(reply: "You spent $42.50", evidence: ["Groceries $42.50"]).passed)
        #expect(check.check(reply: "That's 80% of your target", evidence: ["80%"]).passed)
        #expect(!check.check(reply: "That's 85% of your target", evidence: ["80%"]).passed)
    }

    @Test func euroAmountsKeepTheirOwnUnit() {
        #expect(check.check(reply: "The trip hotel was €412", evidence: ["Hotel 412 EUR"]).passed)
        #expect(check.check(reply: "That's 412 euros", evidence: ["Hotel €412"]).passed)
        #expect(!check.check(reply: "You spent $412 on the hotel", evidence: ["Hotel €412"]).passed)
    }

    @Test func slashDatesAreNotNumbers() {
        #expect(check.check(reply: "Your last bench was on 10/23", evidence: []).passed)
        #expect(check.check(reply: "Logged 10/3 at 92.5 kg", evidence: ["92.5 kg"]).passed)
    }

    @Test func aGroupedNumberIsNeverAYear() {
        #expect(!check.check(reply: "You walked 2,000 steps", evidence: ["1,800 steps"]).passed)
        #expect(check.check(reply: "You walked 2,000 steps", evidence: ["Steps today 2,000"]).passed)
        // A plain 2000 still reads as a year.
        #expect(check.check(reply: "Since 2000", evidence: []).passed)
    }

    @Test func oneIsNeverChecked() {
        #expect(check.check(reply: "One thing left today", evidence: []).passed)
    }

    @Test func theRetryNoteNamesTheNumbers() {
        let result = check.check(reply: "You benched 95 kg", evidence: ["92.5 kg"])
        #expect(AnswerCheck.retryNote(result).contains("\"95 kg\""))
    }
}
