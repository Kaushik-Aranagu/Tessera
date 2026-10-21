import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Calories show only on the finished workout's Day line and Home done line, behind the switch; units follow his pick.
extension DayStoryTests {
    func sixtyMinuteBench(_ title: String = "Push Day B") throws {
        try workout(title, start: Self.at(21, 18), sets: [(Self.at(21, 18, 10), 80, 8), (Self.at(21, 18, 20), 80, 8)],
                    end: Self.at(21, 19))
    }

    func line(_ calories: CaloriesOptions?) throws -> DayLine {
        let day = Self.at(21, 12)
        let all = DayStory.lines(engine: engine, on: day, calendar: Self.calendar(), now: Self.at(22, 12),
                                 calories: calories)
        return try #require(all.first)
    }

    @Test func aFinishedWorkoutsDayLineCarriesCaloriesOnlyWhenTheSwitchIsOn() throws {
        try engine.perform(CreateNote(body: "weighed 80 kg this morning", isPrivate: true), by: .user)
        try sixtyMinuteBench()
        // 6.0 x 80 kg x 1 h = 480.
        #expect(try line(CaloriesOptions(on: true)).calories == "about 480 kcal")
        // Off, or nothing passed (every other caller): none, and the words are the same either way.
        #expect(try line(CaloriesOptions(on: false)).calories == nil && line(nil).calories == nil)
        #expect(try line(CaloriesOptions(on: true)).text == line(nil).text)
        #expect(try !line(CaloriesOptions(on: true)).text.contains("kcal"))
    }

    @Test func aHealthWeightIsUsedWhenNoneWasTypedAndNothingIsStored() throws {
        try sixtyMinuteBench()
        #expect(try line(CaloriesOptions(on: true)).calories == nil)
        #expect(try line(CaloriesOptions(on: true, healthKg: 70)).calories == "about 420 kcal")
        #expect(MeProfile.read(in: store) == MeProfile() && store.object(id: MeProfile.objectID) == nil)
    }

    @Test func aPrivateWorkoutsLinesShowNoCalories() throws {
        try engine.perform(CreateNote(body: "weighed 80 kg this morning", isPrivate: true), by: .user)
        try sixtyMinuteBench("Knee rehab day")
        let shown = try line(CaloriesOptions(on: true))
        #expect(shown.calories == nil)
    }

    @Test func caloriesNeverReachAMemoryLine() throws {
        try engine.perform(CreateNote(body: "weighed 80 kg this morning", isPrivate: true), by: .user)
        try sixtyMinuteBench()
        let memory = TessMemoryStore(engine: engine, calendar: Self.calendar(), forgetLogURL: nil)
        let text = memory.recentLine(for: Self.at(21, 12), now: Self.at(22, 12)) ?? ""
        #expect(!text.contains("kcal") && !text.contains("480"))
    }

    @Test func theWorkoutsOwnTotalIsShownNotASumOfRoundedParts() throws {
        try engine.perform(CreateNote(body: "weighed 77 kg this morning", isPrivate: true), by: .user)
        let workout = try workout("Mixed", start: Self.at(21, 18), sets: [(Self.at(21, 18, 10), 80, 8)],
                                  end: Self.at(21, 18, 50))
        let curl = try #require(classes[.benchPress])
        _ = curl
        let weight = try #require(BodyWeight.lastKg(in: store))
        let minutes = 50.0
        let total = try #require(CaloriesBurned.forWorkout(workout, store: store, weightKg: weight))
        #expect(total == Int(((6.0 * weight * minutes / 60) / 10).rounded()) * 10)
        let shown = try line(CaloriesOptions(on: true))
        #expect(shown.calories == CaloriesBurned.line(total))
    }
}

@MainActor
struct HomeCaloriesTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    @Test func homeAsksForTheLineSeparatelyAndNoHomeOrClaudeFieldCarriesIt() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: classes)
        try StarterContent.installIfNeeded(store: store, classes: classes)
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateNote(body: "weighed 80 kg this morning", isPrivate: true), by: .user)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let end = Date(timeIntervalSince1970: 1_792_000_000)
        let start = end.addingTimeInterval(-3600)
        let workout = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 5, time: start), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: end), by: .user)
        let summary = try #require(TrainingLedger(store: store, classes: classes)
            .finishedWorkouts(on: end, calendar: Self.calendar).first)
        let facts = HomeFacts(engine: engine, calendar: Self.calendar)
        #expect(facts.calories(forDone: summary, options: CaloriesOptions(on: true)) != nil)
        #expect(facts.calories(forDone: summary, options: CaloriesOptions(on: false)) == nil)
        // The fact, the line and everything built for widgets or Claude carry no calories.
        let done = facts.fact(done: summary)
        let line = HomeLines.line(for: done)
        for text in [line.text, line.hero, line.context ?? "", line.detail ?? "", line.widgetLine,
                     line.widgetWords, line.widgetMeta ?? "", String(describing: done)]
        {
            #expect(!text.contains("kcal"), "\(text)")
        }
        // The Claude pack, when this day builds one (it needs a best or a gap to say), carries none either.
        if case let .success(pack) = HomeDonePack.build(done, dayLabel: "Thursday", calendar: Self.calendar,
                                                        store: store)
        {
            #expect(!ClaudeHomeDone.facts(pack, line: line).contains("kcal"))
            #expect(!pack.json.contains("kcal"))
        }
        // And no source that builds that pack or its words mentions calories at all.
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources")
        for file in ["TesseraCore/Home/HomeDonePack.swift", "TesseraTess/HomeDoneWording.swift"] {
            let text = try String(contentsOf: sources.appending(path: file), encoding: .utf8)
            #expect(!text.contains("kcal") && !text.contains("CaloriesBurned"), Comment(rawValue: file))
        }
    }
}

struct UnitsEverywhereTests {
    @Test func theChosenWeightUnitMapsToTheAppsMassUnit() {
        #expect(DisplayUnits().massUnit == nil)
        #expect(DisplayUnits(chosen: ["weight": "lb"]).massUnit == .pounds)
        #expect(DisplayUnits(chosen: ["weight": "kg"]).massUnit == .kilograms)
        #expect(DisplayUnits(chosen: ["distance": "mi"]).massUnit == nil)
    }
}
