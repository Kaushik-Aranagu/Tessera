import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// "Tess names training days": the Review row and its switch read (Core's #1160).
@MainActor
struct DayNamingTests {
    @Test func theRowIsLiveOnByDefaultAndOnWorkout() throws {
        let row = try #require(ReviewChoices.all.first { $0.id == DayNames.reviewKey })
        #expect(row.name == "Tess names training days")
        #expect(row.defaultValue == "On" && row.values == ["On", "Off"])
        #expect(row.readiness == .live && row.needsClaude)
        let workout = try #require(ReviewChoices.drawnPages().first { $0.word == "Workout" })
        #expect(workout.rows.contains { $0.id == DayNames.reviewKey })
    }

    @Test func onlyOffStopsIt() {
        #expect(DayNamingSwitch.isOn("On"))
        #expect(DayNamingSwitch.isOn(nil))
        #expect(!DayNamingSwitch.isOn("Off"))
    }

    @Test func aPlaceholderRoutineGetsARuleNameAndHisNameStopsIt() async throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        // A name of his own: never touched.
        routine.title = "Bench day"
        _ = await model.nameTrainingDays()
        #expect(routine.title == "Bench day")
        // The starter's stock title ("Push A") is not a name he chose: Tess names it once.
        routine.title = "Push A"
        let named = await model.nameTrainingDays()
        // Push B is stock too and asks for the same plain name; whichever goes first has it, the other gets another.
        #expect(named.contains(routine.title) && routine.title != "Push A" && DayNames.isUsable(routine.title),
                "\(routine.title) \(named)")
        // Named once; asked again only when its exercises change.
        #expect(await model.nameTrainingDays().isEmpty)
        // He renames it: Tess stops for good.
        routine.title = "Chest and shoulders"
        #expect(await model.nameTrainingDays().isEmpty && routine.title == "Chest and shoulders")
    }

    /// QA on #1170: the app's namer reads the phone's model, so a phone that has it never asks Claude; with no
    /// on-device closure yet it takes the rule name.
    @Test func aPhoneWithItsOwnModelNeverAsksClaude() async throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        #expect(model.dayNamer.onDeviceAvailable() == DayNamingSwitch.onDeviceModelReady())
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        routine.title = "New routine"
        let namer = model.dayNamer
        var claudeAsked = false
        namer.allowed = { claudeAsked = true
            return true
        }
        namer.onDeviceAvailable = { true }
        // The phone's model gives nothing usable this time: the rule name stands and Claude is still never asked.
        namer.onDevice = { _, _ in nil }
        let suggestion = try #require(await namer.suggest(for: routine, engine: model.engine))
        #expect(suggestion.source == .rules && suggestion.name == "Heavy chest")
        #expect(!claudeAsked, "Claude's gate was read on a phone with its own model")
    }

    /// QA on #1170: a pass cancelled while its call was out applies nothing.
    @Test func aCancelledPassAppliesNothing() async throws {
        #expect(DayNamingSwitch.mayApply(cancelled: false))
        #expect(!DayNamingSwitch.mayApply(cancelled: true))
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        routine.title = "New routine"
        let pass = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            return await model.nameTrainingDays()
        }
        #expect(await pass.value.isEmpty)
        #expect(routine.title == "New routine")
    }

    /// The on-device reply is tidied to the name, and anything Core's checks refuse falls back (nil).
    @Test func theOnDeviceReplyIsCheckedLikeClaudes() {
        #expect(DayNamingPrompt.cleaned("Heavy pull.\n") == "Heavy pull")
        #expect(DayNamingPrompt.cleaned("\"Back and biceps\"") == "Back and biceps")
        #expect(DayNamingPrompt.cleaned("The ultimate monster pump day!") == nil)
        #expect(DayNamingPrompt.cleaned("") == nil)
    }

    /// Only exercise names, muscle words and names to avoid go to the model.
    @Test func theFactsCarryOnlyThePack() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        let pack = try #require(DayNames.pack(of: routine, store: model.store))
        let prompt = DayNamingPrompt.prompt(pack, avoid: ["Push day"])
        let lines = prompt.split(separator: "\n").map(String.init)
        #expect(lines.map { $0.prefix { $0 != ":" } } == ["Exercises", "Muscles", "Avoid"])
        #expect(lines[0] == "Exercises: " + pack.exercises.joined(separator: ", "))
        #expect(lines[2] == "Avoid: Push day")
        #expect(!prompt.contains("{"), "plain lines, never JSON")
    }

    @Test func theAppPlugsTheOnDeviceNamer() {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        #expect(model.dayNamer.onDevice != nil)
    }

    /// Product on #1174: the instructions lead with specific names; the plain split comes last, as a fallback.
    @Test func specificNamesComeBeforeThePlainSplit() throws {
        let words = DayNamingPrompt.instructions
        let specific = try #require(words.range(of: "Heavy chest"))
        let plain = try #require(words.range(of: "fall back to a plain split"))
        #expect(specific.lowerBound < plain.lowerBound)
        #expect(words.contains("1 to 3 words, 22 characters or fewer"))
    }

    /// Builder A's run on release 30: a session not yet started takes its routine's new name; one started or
    /// finished keeps its own.
    @Test func onlyAnUnstartedSessionFollowsItsRoutine() {
        #expect(DayNamingSwitch.followsRoutine(isDeleted: false, started: false, ended: false))
        #expect(!DayNamingSwitch.followsRoutine(isDeleted: false, started: true, ended: false))
        #expect(!DayNamingSwitch.followsRoutine(isDeleted: false, started: true, ended: true))
        #expect(!DayNamingSwitch.followsRoutine(isDeleted: true, started: false, ended: false))
    }

    /// The model offers three names; only a specific one that fits the day is taken. Plain splits, unusable names
    /// and a sample name copied onto the wrong day are refused.
    @Test func aSpecificCandidateBeatsAPlainSplit() {
        let back = ["back", "biceps"], legs = ["quads", "glutes", "hamstrings"]
        #expect(DayNamingPrompt.pick(["Upper body", "Heavy pull", "Back and biceps"], muscles: back) == "Heavy pull")
        #expect(DayNamingPrompt.pick(["Push Pull Leg day", "Leg day", "Long legs"], muscles: legs) == "Long legs")
        #expect(DayNamingPrompt.pick(["Heavy chest", "Back and biceps", "Long legs"], muscles: legs) == "Long legs")
        #expect(DayNamingPrompt.pick(["Heavy chest", "Leg day"], muscles: legs) == nil)
        // An exercise's own name is refused; so is a muscle-plus-day split.
        #expect(DayNamingPrompt.pick(["Overhead press", "Press day"], muscles: ["shoulders"],
                                     exercises: ["Overhead Press", "Lateral Raise"]) == "Press day")
        #expect(DayNamingPrompt.pick(["Back day", "Chest day", "Arms day"], muscles: back) == nil)
        // Three plain splits: nothing, so the rule name stands.
        #expect(DayNamingPrompt.pick(["Leg day", "Upper body", "Push"], muscles: legs) == nil)
        #expect(DayNamingPrompt.pick(["Chest and arms"], muscles: ["chest", "triceps"]) == "Chest and arms")
        #expect(DayNamingPrompt.pick(["The ultimate monster pump day!"], muscles: legs) == nil)
    }

    /// Days with a session waiting are named first, so tonight's row reads its new name soonest.
    @Test func tonightsDayIsNamedFirst() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routines = model.store.linkedObjects("routines", of: plan)
        let last = try #require(routines.last)
        let ordered = DayNamingSwitch.tonightFirst(routines, waiting: [last.id])
        #expect(ordered.first?.id == last.id && ordered.count == routines.count)
    }

    /// QA on #1179: drive the follow step itself. A session waiting on a renamed day takes the new name; a started
    /// one keeps its own.
    @Test func aWaitingSessionFollowsItsDay() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        let workoutClass = try #require(model.classes[.workout])
        let waiting = model.store.create(workoutClass, title: "Push A")
        try model.store.setLinks("routine", on: waiting, to: [routine])
        let started = model.store.create(workoutClass, title: "Push A")
        try model.store.setLinks("routine", on: started, to: [routine])
        try model.store.set("startedAt", to: .date(.now), on: started)
        routine.title = "Heavy chest"
        #expect(model.followRoutineTitles() == 1)
        #expect(waiting.title == "Heavy chest" && started.title == "Push A")
        #expect(model.followRoutineTitles() == 0)
    }

    /// QA on #1181: only today's session counts as waiting; a future day or an old one never started does not.
    @Test func onlyTodaysSessionCountsAsWaiting() {
        let day = TesseraDay()
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        #expect(DayNamingSwitch.isToday(now.addingTimeInterval(3600), day: day, now: now))
        #expect(!DayNamingSwitch.isToday(now.addingTimeInterval(3 * 86400), day: day, now: now))
        #expect(!DayNamingSwitch.isToday(now.addingTimeInterval(-9 * 86400), day: day, now: now))
        #expect(!DayNamingSwitch.isToday(nil, day: day, now: now))
    }

    /// Core's #1178: a rule name is marked as the rules', so a better name may replace it later; the model's is not.
    @Test func theNameCarriesItsSource() {
        #expect(DayNamingSwitch.source(of: .rules) == DayNames.byRules)
        #expect(DayNamingSwitch.source(of: .onDevice) == DayNames.byModel)
        #expect(DayNamingSwitch.source(of: .claude) == DayNames.byModel)
    }

    /// QA on #1179: a session whose title he is editing is never followed.
    @Test func aSessionBeingRetitledIsLeftAlone() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                             classes: model.classes)
        try StarterContent.installIfNeeded(store: model.store, classes: model.classes)
        let plan = try #require(model.store.object(id: StarterContent.planID))
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        let workoutClass = try #require(model.classes[.workout])
        let waiting = model.store.create(workoutClass, title: "Push A")
        try model.store.setLinks("routine", on: waiting, to: [routine])
        routine.title = "Heavy chest"
        DayNamingSwitch.retitling.insert(waiting.id)
        defer { DayNamingSwitch.retitling.remove(waiting.id) }
        #expect(model.followRoutineTitles() == 0 && waiting.title == "Push A")
        DayNamingSwitch.retitling.remove(waiting.id)
        #expect(model.followRoutineTitles() == 1 && waiting.title == "Heavy chest")
    }
}
