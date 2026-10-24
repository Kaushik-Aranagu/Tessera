import Foundation
@testable import Tessera
import Testing

/// Sheet 230: the words, the stack mark's parts, the landing's slot, the week's moves and the library's cuts.
@MainActor
struct TrainingSheet230Tests {
    // MARK: Words

    @Test func theConfirmationReadsAsTheSheetSays() {
        #expect(TrainingWords.confirmation(set: 1, reps: 5, kept: false) == "Set 1, 5 reps.")
        #expect(TrainingWords.confirmation(set: 1, reps: 5, kept: true) == "Set 1, 5 reps, kept.")
        #expect(TrainingWords.confirmation(set: 2, reps: 1, kept: false) == "Set 2, 1 rep.")
        let parts = TrainingWords.confirmationParts(set: 1, reps: 5, kept: false)
        #expect(parts.before + "5" + parts.after == "Set 1, 5 reps.")
        #expect(TrainingWords.logged(set: 2) == "Set 2, logged.")
    }

    @Test func rowsSayWhatTheyHold() {
        #expect(TrainingWords.rowInfo(done: [5, 5, 5], sets: 3, plannedReps: 5) == "5 5 5")
        #expect(TrainingWords.rowInfo(done: [], sets: 3, plannedReps: 6) == "3 by 6")
        #expect(TrainingWords.rowInfo(done: [5], sets: 3, plannedReps: 5) == "5, 2 left")
    }

    @Test func restWarmUpAndDoneWords() {
        #expect(TrainingWords.rest(90) == "Rest 1:30")
        #expect(TrainingWords.next(set: 2, of: 3, nextLift: "Dips") == "Set 2 is next")
        #expect(TrainingWords.next(set: 4, of: 3, nextLift: "Dips") == "Dips is next")
        #expect(TrainingWords.doneSummary(lifts: 4, warmedUp: true) == "warm-up and 4 lifts")
        #expect(TrainingWords.doneSummary(lifts: 1, warmedUp: false) == "1 lift")
        #expect(TrainingWords.doneBrief(lift: "Bench", held: "185", nextName: "Push A", nextDay: "Friday")
            == "Bench held at 185. Next Push A is Friday.")
    }

    @Test func theFootHoldsOneWord() {
        #expect(TrainingWords.foot(startName: "Push A") == "Start Push A")
        #expect(TrainingWords.footLog(set: 2) == "Log set 2")
        #expect(TrainingWords.footResume(name: "Push A") == "Pick up Push A")
        #expect(TrainingWords.footResume(name: "Push A", verb: "Resume") == "Resume Push A")
        for word in [TrainingWords.foot(startName: "Push A"), TrainingWords.footLog(set: 3), TrainingWords.skipRest,
                     TrainingWords.finish, TrainingWords.doneWarming]
        {
            #expect(!word.contains("."), "\(word) is a word, not a sentence")
        }
    }

    @Test func receiptsReadAsTheSheetSays() {
        #expect(TrainingWords.swappedIn(now: "Dips", after: "Bench press") == "Dips now, bench press after.")
        #expect(TrainingWords.unitReceipt(from: "185 lb", to: "85 kg") == "185 lb loads as 85 kg.")
        #expect(TrainingWords.going(lift: "Bench press", set: 2, of: 3, liftsToGo: 4)
            == "Bench press, set 2 of 3. 4 lifts to go.")
    }

    // MARK: The stack mark

    @Test func aStackIsElevenByTwentyFourAndTwelveByTwentyEightAtTheFocus() {
        #expect(StackMarkGeometry(spec: StackMarkSpec(reps: 5, lifted: 0)).size == CGSize(width: 11, height: 24))
        #expect(StackMarkGeometry(spec: StackMarkSpec(reps: 5, lifted: 0, isFocus: true)).size
            == CGSize(width: 12, height: 28))
        #expect(StackMarkGeometry.gap == 5)
        #expect(StackMarkGeometry.gripWidth == 5.2)
    }

    @Test func strokesFollowTheSheet() {
        #expect(StackMarkGeometry.Stroke.grip == 1.6)
        #expect(StackMarkGeometry.Stroke.cap == 1.4)
        #expect(StackMarkGeometry.Stroke.rod == 0.8)
        #expect(StackMarkGeometry.Stroke.floor == 1)
        #expect(StackMarkGeometry.Stroke.lifted == 1.15)
        #expect(StackMarkGeometry.Stroke.resting == 0.8)
    }

    @Test func oneLinePerRepAndTheRodNeverRunsToTheFloor() {
        for reps in [1, 3, 5, 8, 12, 20] {
            let spec = StackMarkSpec(reps: reps, lifted: 0)
            #expect(spec.plates == reps)
            let geometry = StackMarkGeometry(spec: spec)
            // Nothing lifted: the rod stops at the top resting plate, well above the floor.
            #expect(geometry.rodEnd(lift: 0) < geometry.floorY)
            #expect(geometry.rodEnd(lift: 0) == geometry.restingY(0))
            // All lifted: it stops at the last plate it carries, under the cap and above the floor.
            let all = geometry.rodEnd(lift: Double(reps))
            #expect(all > geometry.capY && all < geometry.floorY)
            // Lifted plates and resting plates never cross.
            for lifted in 0 ... reps where lifted < reps && lifted > 0 {
                #expect(geometry.liftedY(lifted - 1) < geometry.restingY(lifted))
            }
        }
    }

    @Test func platesLiftInOrder() {
        let geometry = StackMarkGeometry(spec: StackMarkSpec(reps: 5, lifted: 0))
        #expect(geometry.plateY(0, lift: 0.5) < geometry.restingY(0))
        #expect(geometry.plateY(1, lift: 0.5) == geometry.restingY(1))
        #expect(geometry.plateY(0, lift: 1) == geometry.liftedY(0))
        #expect(geometry.isLifted(0, lift: 1))
        #expect(!geometry.isLifted(1, lift: 1))
    }

    @Test func greenArrivesWithReps() {
        #expect(!StackMarkSpec(reps: 5, lifted: 0).hasAny)
        #expect(StackMarkSpec(reps: 5, lifted: 1).hasAny)
        #expect(!StackMarkSpec(reps: 5, lifted: 4).isFull)
        #expect(StackMarkSpec(reps: 5, lifted: 5).isFull)
    }

    // MARK: The landing

    @Test func todaysSlotStates() {
        #expect(TodaySlot.notStarted(name: "Push A").actionWord == "Start Push A")
        #expect(TodaySlot.inProgress(name: "Push A", whereLine: "x").actionWord == "Resume Push A")
        #expect(TodaySlot.inProgress(name: "Push A", whereLine: "x").header == "In progress")
        #expect(TodaySlot.inProgress(name: "Push A", whereLine: "x").clockWord == "Pause")
        #expect(TodaySlot.paused(name: "Push A", whereLine: "x").clockWord == "Go on")
        #expect(TodaySlot.done(name: "Push A").isStruck)
        #expect(TodaySlot.skipped(name: "Push A").isStruck)
        #expect(!TodaySlot.notStarted(name: "Push A").isStruck)
    }

    @Test func theStatLinesReadAsTheSheetSays() throws {
        let since = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let headline = TrainingHeadline(done: 3, planned: 6, weeksInARow: 5,
                                        gain: .init(lift: "Bench press", classID: nil,
                                                    kilograms: 10 / 2.2046226218, since: since))
        #expect(headline.doneLine == "3 of 6 this week")
        #expect(headline.streakLine == "5 weeks in a row on plan")
        let parts = try #require(headline.gainParts(unit: .pounds))
        #expect(parts.gain == "+10 lb")
        #expect(parts.rest == " on bench since Oct 1")
    }

    @Test func theClockStopsWhilePaused() {
        let clock = TodayClock()
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        #expect(clock.elapsed(since: start, now: start.addingTimeInterval(60)) == 60)
        clock.pause(at: start.addingTimeInterval(60))
        #expect(clock.elapsed(since: start, now: start.addingTimeInterval(600)) == 60)
        clock.resume(at: start.addingTimeInterval(120))
        #expect(clock.elapsed(since: start, now: start.addingTimeInterval(180)) == 120)
    }

    // MARK: The week

    private func week() -> [WeekDayRow] {
        let base = Date(timeIntervalSinceReferenceDate: 0)
        func day(_ offset: Int) -> Date {
            base.addingTimeInterval(Double(offset) * 86400)
        }
        return [
            WeekDayRow(id: day(0), kind: .done, name: "Push A", minutes: 50),
            WeekDayRow(id: day(1), kind: .today, name: "Pull A", minutes: 55),
            WeekDayRow(id: day(2), kind: .rest, name: nil, minutes: nil),
            WeekDayRow(id: day(3), kind: .ahead, name: "Legs", minutes: 60),
        ]
    }

    @Test func movingASessionSwapsItWithTheNextDay() {
        let moved = WeekTweaks.apply(week(), moves: [1], skips: [])
        #expect(moved[1].name == nil)
        #expect(moved[1].kind == .rest)
        #expect(moved[2].name == "Pull A")
        #expect(moved[2].kind == .ahead)
    }

    @Test func aDoneDayNeverMoves() {
        let moved = WeekTweaks.apply(week(), moves: [0], skips: [])
        #expect(moved[0].name == "Push A")
        #expect(moved[0].kind == .done)
    }

    @Test func skippingStrikesTheDay() {
        let rows = WeekTweaks.apply(week(), moves: [], skips: [3])
        #expect(rows[3].isSkipped)
        #expect(!rows[3].isMovable)
    }

    // MARK: The library

    @Test func kindsFromNames() {
        #expect(LibraryKinds.kind(ofName: "Push Day A") == "Push")
        #expect(LibraryKinds.kind(ofName: "Barbell row") == "Pull")
        #expect(LibraryKinds.kind(ofName: "Back squat") == "Legs")
        #expect(LibraryKinds.kind(ofName: "Easy run") == "Cardio")
        #expect(LibraryKinds.kind(ofName: "Hip mobility") == "Mobility")
        #expect(LibraryKinds.kind(ofName: "Full body") == "Full body")
    }

    private func item(kind: String = "Push", minutes: Int? = nil, weekday: Int? = nil) -> LibraryEntry {
        LibraryEntry(id: UUID().uuidString, what: .routines, title: "x", lines: [], kind: kind, minutes: minutes,
                     weekday: weekday)
    }

    @Test func everythingTakesAll() {
        for axis in LibraryAxis.allCases {
            #expect(LibraryFilter.matches(item(), axis: axis, category: "Everything"))
        }
    }

    @Test func cutsByKindLengthAndDay() {
        #expect(LibraryFilter.matches(item(kind: "Push"), axis: .kind, category: "Push"))
        #expect(!LibraryFilter.matches(item(kind: "Push"), axis: .kind, category: "Pull"))
        #expect(LibraryFilter.matches(item(minutes: 25), axis: .length, category: "Under 30 min"))
        #expect(LibraryFilter.matches(item(minutes: 45), axis: .length, category: "45 to 60 min"))
        #expect(LibraryFilter.matches(item(minutes: 75), axis: .length, category: "Over an hour"))
        #expect(!LibraryFilter.matches(item(), axis: .length, category: "Under 30 min"))
        // Monday is weekday 2, Sunday weekday 1.
        #expect(LibraryFilter.matches(item(weekday: 2), axis: .day, category: "Monday"))
        #expect(LibraryFilter.matches(item(weekday: 1), axis: .day, category: "Sunday"))
        #expect(!LibraryFilter.matches(item(weekday: 3), axis: .day, category: "Monday"))
    }

    @Test func theAxisRollsAndTheDialsNamesAreTheSheets() {
        #expect(LibraryAxis.kind.next == .length)
        #expect(LibraryAxis.length.next == .day)
        #expect(LibraryAxis.day.next == .kind)
        #expect(LibraryAxis.kind.categories == [
            "Everything",
            "Push",
            "Pull",
            "Legs",
            "Full body",
            "Cardio",
            "Mobility",
        ])
        #expect(LibraryWhat.allCases.map(\.rawValue) == ["Routines", "Exercises", "Programs", "Goals"])
        #expect(LibraryWhat.allCases.map(\.actionWord)
            == ["Build a routine", "Add an exercise", "Start a program", "Set a goal"])
    }

    // MARK: Units

    @Test func aUnitIsHalfTheNumberAndNeverUnderTen() {
        #expect(MeasureLine.unitSize(for: 84) == 42)
        #expect(MeasureLine.unitSize(for: 26) == 13)
        #expect(MeasureLine.unitSize(for: 17) == 10)
        #expect(MeasureLine.unitSize(for: 8) == 10)
    }

    @Test func aLineSplitsItsMeasuredNumbers() {
        #expect(MeasureLine.pieces("185 lb for 5, 5, 4") == [
            .measured(number: "185", unit: "lb"), .plain(" for 5, 5, 4"),
        ])
        #expect(MeasureLine.pieces("+10 lb on bench since Oct 1") == [
            .plain("+"), .measured(number: "10", unit: "lb"), .plain(" on bench since Oct 1"),
        ])
        #expect(MeasureLine.pieces("4 lifts, about 55 min") == [
            .plain("4 lifts, about "), .measured(number: "55", unit: "min"),
        ])
        #expect(MeasureLine.pieces("Set 2 of 3") == [.plain("Set 2 of 3")])
    }

    @Test func countsFollowTheCategories() {
        let items = [item(kind: "Push"), item(kind: "Push"), item(kind: "Pull")]
        #expect(LibraryFilter.counts(items, axis: .kind) == [3, 2, 1, 0, 0, 0, 0])
    }
}
