import Foundation
@testable import TesseraCore
import Testing

/// Sheet 200: Tess picks the mood on the phone. First match wins, a mood holds ten minutes, no title leaks.
@MainActor
struct MosaicMoodPickerTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func facts(_ now: Date) -> MosaicFacts {
        MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4))
    }

    func mood(_ now: Date, _ tweak: (inout MosaicMoodInputs) -> Void = { _ in }) -> MosaicMood {
        var input = MosaicMoodInputs(facts: facts(now))
        tweak(&input)
        return MosaicMoodPicker.pick(input).mood
    }

    @Test func eachMoodIsPickedByItsOwnRule() {
        // Sunrise about 7:25, sunset about 6:23 pm on Oct 22 at 37.8 N.
        #expect(mood(at(7, 40)) == .morning)
        #expect(mood(at(8, 40)) == .day)
        #expect(mood(at(13)) == .day)
        #expect(mood(at(18, 5)) == .golden)
        #expect(mood(at(18, 50)) == .golden)
        #expect(mood(at(19)) == .day)
        #expect(mood(at(22, 30)) == .night)
        #expect(mood(at(2)) == .night)
        #expect(mood(at(13)) { $0.isRestDay = true } == .rest)
        #expect(mood(at(13)) { $0.daysAway = 4 } == .back)
        #expect(mood(at(13)) { $0.raining = true } == .rain)
        #expect(mood(at(13)) { $0.running = true } == .running)
        #expect(mood(at(13)) { $0.dueToday = 3; $0.doneToday = 3 } == .done)
    }

    @Test func theFirstMatchInTheListWins() {
        // Running beats everything; done beats back, rest, night (before 10 pm), golden and morning.
        #expect(mood(at(18, 5)) { $0.running = true; $0.dueToday = 1; $0.doneToday = 1 } == .running)
        #expect(mood(at(18, 5)) { $0.dueToday = 1; $0.doneToday = 1; $0.daysAway = 5; $0.isRestDay = true } == .done)
        #expect(mood(at(18, 5)) { $0.daysAway = 5; $0.isRestDay = true } == .back)
        #expect(mood(at(18, 5)) { $0.isRestDay = true } == .rest)
        #expect(mood(at(22, 15)) { $0.dueToday = 1; $0.doneToday = 1 } == .night)
        #expect(mood(at(7, 40)) { $0.raining = true } == .morning)
        #expect(mood(at(13)) { $0.dueToday = 3; $0.doneToday = 2 } == .day)
    }

    @Test func welcomeBackShowsOnceAndNeedsThreeDays() {
        #expect(mood(at(13)) { $0.daysAway = 2 } == .day)
        #expect(mood(at(13)) { $0.daysAway = 3 } == .back)
        #expect(mood(at(13)) { $0.daysAway = 3; $0.backShown = true } == .day)
    }

    @Test func aMoodHoldsTenMinutesExceptRunningAndDone() {
        let start = at(13)
        var input = MosaicMoodInputs(facts: facts(at(13, 4)), isRestDay: true, previous: (.day, start))
        // Rest wants in, but day has only held 4 minutes.
        #expect(MosaicMoodPicker.pick(input).mood == .day)
        #expect(MosaicMoodPicker.pick(input).since == start)
        input = MosaicMoodInputs(facts: facts(at(13, 11)), isRestDay: true, previous: (.day, start))
        let changed = MosaicMoodPicker.pick(input)
        #expect(changed.mood == .rest && changed.since == at(13, 11) && changed.transition == .dissolve)
        // Running and done never wait, in or out.
        input = MosaicMoodInputs(facts: facts(at(13, 4)), running: true, previous: (.day, start))
        #expect(MosaicMoodPicker.pick(input).mood == .running)
        input = MosaicMoodInputs(facts: facts(at(13, 4)), previous: (.running, start))
        #expect(MosaicMoodPicker.pick(input).mood == .day)
        // The same mood keeps its own start.
        input = MosaicMoodInputs(facts: facts(at(13, 30)), previous: (.day, start))
        #expect(MosaicMoodPicker.pick(input).since == start)
    }

    @Test func eachMoodHasItsOwnChangeover() {
        let table: [MosaicMood: MosaicTransition] = [
            .morning: .fall, .day: .wave, .golden: .wipe, .running: .wave, .rest: .dissolve, .back: .gather,
            .done: .wave, .rain: .fall, .night: .dissolve,
        ]
        for mood in MosaicMood.allCases {
            #expect(MosaicTransition.standard(for: mood) == table[mood])
        }
    }

    @Test func theLinesAreThreeAndMasked() throws {
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let workout = try store.create(#require(engine.classes[.workout]), title: "Session")
        try store.setLinks("routine", on: workout, to: [secret])
        try engine.perform(StartProcess(subject: workout.id, ownerApp: "Workouts", nextStep: "Knee rehab, set 1"),
                           by: .user)
        let input = MosaicMoodInputs.make(engine: engine, facts: facts(at(13)))
        #expect(input.running && input.runningLabel == "Private workout")
        let pick = MosaicMoodPicker.pick(input)
        #expect(pick.mood == .running && pick.lines.count == 3)
        #expect(pick.lines[1] == "Private workout is running.")
        #expect(!pick.lines.joined().lowercased().contains("knee"))
    }

    @Test func theInputsReadDueTodayAndDaysAwayFromThePhone() throws {
        let now = at(13)
        let task = try engine.perform(CreateTask(title: "Mail forms", due: now), by: .user).output
        let hidden = try engine.perform(CreateTask(title: "Lexapro refill", due: now), by: .user).output
        try engine.perform(SetTaskDone(task: task.id), by: .user)
        var input = MosaicMoodInputs.make(engine: engine, facts: facts(now))
        #expect(input.dueToday == 2 && input.doneToday == 1)
        #expect(MosaicMoodPicker.pick(input).mood != .done)
        try engine.perform(SetTaskDone(task: hidden.id), by: .user)
        input = MosaicMoodInputs.make(engine: engine, facts: facts(now))
        let pick = MosaicMoodPicker.pick(input)
        #expect(pick.mood == .done && pick.lines[1] == "Everything due today is done.")
        #expect(!pick.lines.joined().lowercased().contains("lexapro"))
    }

    @Test func theFallbackIsTheAppsOwnPrivateLabelNeverANewPhrase() throws {
        func label(for key: SystemCatalog.Key, title: String, owner: String) throws -> String {
            let subject = try store.create(#require(engine.classes[key]), title: title)
            try engine.perform(StartProcess(subject: subject.id, ownerApp: owner, nextStep: "Step"), by: .user)
            let running = try #require(ProcessTable(engine: engine).running())
            let text = MosaicMoodInputs.privateLabel(of: running, store: store)
            try engine.perform(EndProcess(process: running.id, reason: .done), by: .user)
            return text
        }
        #expect(try label(for: .workout, title: "Session", owner: "Workouts") == "Private workout")
        #expect(try label(for: .recipe, title: "Soup", owner: "Kitchen") == "Private recipe")
        #expect(try label(for: .routine, title: "Morning", owner: "Routines") == RoutinesLanding.privateRoutine)
        #expect(try label(for: .list, title: "Trip", owner: "Lists") == ListContents.privateListLabel)
    }

    @Test func theLinesAreDaySentenceClausesWithAppWordsOnlyForPlainThings() {
        let cook = HandsEvent(app: .kitchen, label: "Tacos", start: at(14, 23), end: at(15), hands: [], isFixed: true)
        let facts = MosaicFacts.make(engine: engine, now: at(14), calendar: calendar, place: (37.8, -122.4),
                                     events: [cook])
        let pick = MosaicMoodPicker.pick(MosaicMoodInputs(facts: facts))
        #expect(pick.mood == .day && pick.lines[1] == "Free 23 min, then Tacos.")
        #expect(pick.clauses[0].keyWord == nil && pick.clauses[0].app == nil)
        #expect(pick.clauses[1].app == .kitchen && pick.clauses[1].keyWord == 18 ..< 23)
        // A masked running thing is plain; Tess's words never carry an app word.
        let plain = MosaicMoodPicker.pick(MosaicMoodInputs(
            facts: facts,
            running: true,
            runningLabel: "Private workout"
        ))
        #expect(plain.clauses[1].text == "Private workout is running." && plain.clauses[1].keyWord == nil)
        let shown = MosaicMoodPicker.pick(MosaicMoodInputs(facts: facts, running: true, runningLabel: "Push A",
                                                           runningApp: .training))
        #expect(shown.clauses[1].app == .training && shown.clauses[1].keyWord == 0 ..< 6)
    }
}
