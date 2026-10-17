import Foundation
@testable import Tessera
import Testing

/// Design's v9 walk lows (board 0q): the routine detail line and the Done hero.
@MainActor
struct V9WalkLowsTests {
    @Test func rollingPlanHasNoDayPrefix() {
        #expect(RoutineRow.detail(slots: 5, about: "about 40 min", fixedDays: nil) == "5 exercises, about 40 min")
    }

    @Test func fixedDaysWithNoneRead_NoDays() {
        #expect(RoutineRow
            .detail(slots: 5, about: "about 40 min", fixedDays: []) == "No days. 5 exercises, about 40 min")
    }

    @Test func fixedDaysListDaysThenPeriod() {
        #expect(RoutineRow.detail(slots: 5, about: "about 40 min", fixedDays: [2, 5])
            == "Mon, Thu. 5 exercises, about 40 min")
        #expect(RoutineRow.detail(slots: 1, about: "about 8 min", fixedDays: [3]) == "Tue. 1 exercise, about 8 min")
    }

    @Test func fixedEmptyRoutineKeepsTheWords() {
        #expect(RoutineRow.detail(slots: 0, about: "", fixedDays: []) == "No days. No exercises yet")
    }

    @Test func heroKeepsTheNameTogether() {
        let text = WorkoutFinishView.heroText(title: "Push Day A")
        #expect(text == "Push\u{00A0}Day\u{00A0}A, done")
        #expect(text.split(separator: " ").count == 2)
    }

    @Test func aLongNameGluesOnlyItsLastTwoWords() {
        // Design on the v9 walk: only a short name (16 characters or fewer) is one unit; a long one wraps.
        let long = WorkoutFinishView.heroText(title: "Upper Body Hypertrophy A")
        #expect(long == "Upper Body Hypertrophy\u{00A0}A, done")
        let sixteen = WorkoutFinishView.heroText(title: "Pull Day Heavy A")
        #expect(sixteen == "Pull\u{00A0}Day\u{00A0}Heavy\u{00A0}A, done")
        #expect(WorkoutFinishView.heroText(title: "Extraordinarilylongname") == "Extraordinarilylongname, done")
    }

    @Test func anEmptyTitleReadsWorkoutDone() {
        #expect(WorkoutFinishView.heroText(title: "") == "Workout, done")
        #expect(WorkoutFinishView.heroText(title: "  ") == "Workout, done")
    }
}
