@testable import Tessera
import Testing

/// Sheet 85's Habits words, and the walls on every one of them.
@MainActor
struct HabitsCopyTests {
    @Test func zeroReadsAsTheTargetNeverAShortfall() {
        #expect(HabitsCopy.count(done: 0, target: 5) == "5 a week")
        #expect(HabitsCopy.count(done: 1, target: 5) == "1 of 5")
        #expect(HabitsCopy.count(done: 7, target: 5) == "7 of 5", "going past the number keeps counting")
    }

    @Test func tessLines() {
        #expect(HabitsCopy.added("Read", target: 5) == "Read added, 5 times a week")
        #expect(HabitsCopy.added("Stretch", target: 1) == "Stretch added, 1 time a week")
        #expect(HabitsCopy.checkIn("Read", done: 3, target: 5) == "Read, 3 of 5 this week")
        #expect(HabitsCopy.alreadyIn("Read") == "Read is already in for today")
        #expect(HabitsCopy.checkIn("Read", done: 0, target: 5) == "Read, 5 a week")
        #expect(HabitsCopy.doneForWeek(["Read", "Stretch"]) == "Read and Stretch are done for the week")
        #expect(HabitsCopy.doneForWeek(["Read"]) == "Read is done for the week")
        #expect(HabitsCopy.doneForWeek(["A", "B", "C", "D"]) == "A, B and 2 more are done for the week")
        #expect(HabitsCopy.doneForWeek([]) == nil)
    }

    @Test func contextAndRules() {
        #expect(HabitsCopy.context(weekday: "Thursday", daysLeft: 3) == "Thursday, 3 days to go")
        #expect(HabitsCopy.context(weekday: "Monday", daysLeft: 6) == "Monday, a new week")
        #expect(HabitsCopy.context(weekday: "Saturday", daysLeft: 1) == "Saturday, 1 day to go")
        #expect(HabitsCopy.context(weekday: "Sunday", daysLeft: 0) == "Sunday, the last day")
        #expect(HabitsCopy.rule(target: 5, source: "by hand") == "5 a week, by hand")
        #expect(HabitsCopy.weekLines.contains("A day starts 4 am"))
    }

    @Test func voiceOverRows() {
        #expect(HabitsCopy
            .voiceOver("Read", done: 3, target: 5, markedToday: true) == "Read, 3 of 5 this week, marked today")
        #expect(HabitsCopy.voiceOver("Meditate", done: 0, target: 4, markedToday: false)
            == "Meditate, 4 a week, nothing marked yet")
    }

    /// The walls: no line carries a streak, a miss, a percentage or a "0 of".
    @Test func noLineCarriesAWalledWord() {
        var lines = [HabitsCopy.empty, HabitsCopy.emptySide] + HabitsCopy.weekLines
        for done in 0 ... 7 {
            lines.append(HabitsCopy.count(done: done, target: 5))
            lines.append(HabitsCopy.voiceOver("Read", done: done, target: 5, markedToday: done > 0))
            lines.append(HabitsCopy.checkIn("Read", done: done, target: 5))
        }
        for daysLeft in 0 ... 6 {
            lines.append(HabitsCopy.context(weekday: "Wednesday", daysLeft: daysLeft))
        }
        for line in lines {
            for word in HabitsCopy.walled {
                #expect(!line.lowercased().contains(word), "\(line) says \(word)")
            }
        }
    }
}
