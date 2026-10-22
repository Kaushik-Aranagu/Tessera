import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The Training library (Design 124, 128, 129): place, the rows, Try today with its ten seconds.
@MainActor
struct LibraryTests {
    private func clean() {
        TriedToday.set(nil)
        TriedToday.set(nil, scope: "memory")
    }

    @Test func aWorkoutThePlaceLacksTheKitForSaysWhyAndIsNotHidden() throws {
        let push = try #require(ReadyWorkouts.workout(id: "W01"))
        #expect(TrainingPlace.gym.reason(for: push) == nil)
        #expect(TrainingPlace.home.reason(for: push) == "needs a barbell and a cable; Home has none")
        let machines = try #require(ReadyWorkouts.workout(id: "W02"))
        #expect(TrainingPlace.home.reason(for: machines) == "needs a cable and a machine; Home has none")
        let home = try #require(ReadyWorkouts.workout(id: "W03"))
        #expect(TrainingPlace.home.reason(for: home) == nil)
        // Every workout stays in the list for either place.
        #expect(ReadyWorkouts.all.count == 14)
    }

    @Test func aWorkoutLineSaysTheSetsAndRepsPlainly() throws {
        let push = try #require(ReadyWorkouts.workout(id: "W01"))
        #expect(push.setsWord(push.slots[0]) == "4 × 6–8")
        #expect(push.setsWord(push.slots[1]) == "3 × 8")
        #expect(push.subtitle == "6 exercises, about 55 min")
    }

    @Test func triedTodayNamesWhatItReplacedAndTakesTenSecondsToUndo() throws {
        let noon = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 12)))
        let tried = TriedToday(routineID: UUID(), title: "Upper", replacedTitle: "Push A", minutes: 25,
                               day: TriedToday.dayKey(noon), triedAt: noon)
        #expect(tried.line(now: noon) == "Trying Upper in 25 today. Push A on Thursday.")
        #expect(tried.undoIsOpen(now: noon.addingTimeInterval(9)))
        #expect(!tried.undoIsOpen(now: noon.addingTimeInterval(10.5)))
        let alone = TriedToday(routineID: UUID(), title: "Upper", replacedTitle: nil, minutes: 25,
                               day: TriedToday.dayKey(noon), triedAt: noon)
        #expect(alone.line(now: noon) == "Trying Upper in 25 today.")
    }

    @Test func triedTodayIsOnlyForItsOwnDay() throws {
        defer { clean() }
        let noon = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 12)))
        TriedToday.set(TriedToday(routineID: UUID(), title: "Upper", replacedTitle: nil, minutes: 25,
                                  day: TriedToday.dayKey(noon), triedAt: noon))
        #expect(TriedToday.current(now: noon) != nil)
        #expect(TriedToday.current(now: noon.addingTimeInterval(86400 * 2)) == nil)
    }

    @Test func tryTodayStandsInForTodayAndUndoPutsThePlanBack() throws {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let workout = try #require(ReadyWorkouts.workout(id: "W02"))
        #expect(model.canTryToday())
        #expect(model.tryToday(workout))
        let tried = try #require(model.triedRoutine())
        #expect(tried.title == "Machine Push")
        #expect(model.triedRoutine()?.orderedChildren.count == 6)
        model.undoTryToday()
        #expect(model.triedRoutine() == nil)
        #expect(TriedToday.current(scope: "memory") == nil)
        // Nothing of the Plan was written: its routines are the ones the demo made.
        #expect(model.plan
            .map { model.store.linkedObjects("routines", of: $0).contains { $0.title == "Machine Push" } } == false)
    }

    @Test func tryTodayDoesNothingWhileAWorkoutRuns() throws {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let workout = try #require(model.tonightWorkout())
        model.startWorkout(workout)
        #expect(!model.canTryToday())
        #expect(try !model.tryToday(#require(ReadyWorkouts.workout(id: "W02"))))
        model.endWorkout()
    }

    @Test func theLibraryHasTheBuiltInsAndTheExtrasGroupedByEquipment() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let items = LibraryItems.all(model: model)
        #expect(items.count == ExerciseLibrary.seeds.count + LibraryExtras.all.count)
        let bench = items.first { $0.name == "Bench Press" }
        #expect(bench?.classDef != nil)
        #expect(bench?.matches(.chest) == true && bench?.matches(.legs) == false)
        #expect(bench?.matches(nil) == true)
        let sections = LibraryItems.sections(items)
        #expect(sections.first?.equipment == .barbell)
        #expect(sections.flatMap(\.items).count == items.count)
    }

    private func routines(titled title: String, in model: AppModel) -> Int {
        model.objects(of: .routine).filter { $0.title == title && !$0.isDeleted }.count
    }

    @Test func aSecondTryTheSameDayTakesTheFirstOnesPlaceAndKeepsWhatItReplaced() throws {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        #expect(try model.tryToday(#require(ReadyWorkouts.workout(id: "W02"))))
        let first = try #require(model.triedToday())
        #expect(try model.tryToday(#require(ReadyWorkouts.workout(id: "W03"))))
        let second = try #require(model.triedToday())
        #expect(second.title == "Push at Home")
        #expect(second.replacedTitle == first.replacedTitle, "the line still names what the Plan had")
        #expect(routines(titled: "Machine Push", in: model) == 0, "the first try's routine is gone")
        #expect(routines(titled: "Push at Home", in: model) == 1)
    }

    @Test func savingWhatHeIsTryingKeepsThatRoutineInsteadOfMakingASecond() throws {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let workout = try #require(ReadyWorkouts.workout(id: "W02"))
        #expect(model.tryToday(workout))
        #expect(model.saveReadyWorkout(workout))
        #expect(routines(titled: "Machine Push", in: model) == 1)
        #expect(TriedToday.current(scope: "memory")?.kept == true)
        model.undoTryToday()
        #expect(routines(titled: "Machine Push", in: model) == 1, "a saved workout stays when the try is undone")
    }

    @Test func aTriedRoutineNobodySavedGoesWhenItsDayIsOver() throws {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let now = AppClock.now
        #expect(try model.tryToday(#require(ReadyWorkouts.workout(id: "W02")), now: now))
        #expect(routines(titled: "Machine Push", in: model) == 1)
        model.purgeStaleTried(now: now.addingTimeInterval(86400 * 2))
        #expect(routines(titled: "Machine Push", in: model) == 0)
        #expect(TriedToday.stored(scope: "memory") == nil)
    }

    @Test func aTriedLineNeedsItsRoutineInThisStore() {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let now = AppClock.now
        TriedToday.set(TriedToday(routineID: UUID(), title: "Upper", replacedTitle: nil, minutes: 25,
                                  day: TriedToday.dayKey(now), triedAt: now), scope: "memory")
        #expect(model.triedToday() == nil, "another store's try never shows here")
    }

    @Test func triedWorkoutsAreRemembered() throws {
        let defaults = try #require(UserDefaults(suiteName: "LibraryTests.history"))
        defaults.removePersistentDomain(forName: "LibraryTests.history")
        TriedHistory.add("W02", defaults: defaults)
        TriedHistory.add("W05", defaults: defaults)
        TriedHistory.add("W02", defaults: defaults)
        #expect(TriedHistory.ids(defaults: defaults) == ["W02", "W05"])
    }

    @Test func theTryIsKeptPerStoreSoAnotherStoreNeverOverwritesIt() throws {
        clean()
        defer { clean() }
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        #expect(model.triedScope == "memory")
        #expect(try model.tryToday(#require(ReadyWorkouts.workout(id: "W02"))))
        // A record under another store's key is left alone by this store's undo and purge.
        let other = TriedToday(routineID: UUID(), title: "Elsewhere", replacedTitle: nil, minutes: 20,
                               day: TriedToday.dayKey(AppClock.now), triedAt: AppClock.now)
        TriedToday.set(other, scope: "tessera.sqlite")
        defer { TriedToday.set(nil, scope: "tessera.sqlite") }
        model.undoTryToday()
        model.purgeStaleTried()
        #expect(TriedToday.stored(scope: "tessera.sqlite") == other)
    }

    @Test func aBodyweightFirstTimeLineStartsEasyAndALoadedOneStartsLight() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let items = LibraryItems.all(model: model)
        let pushUp = try #require(items.first { $0.name == "Push-Up" }?.classDef)
        let bench = try #require(items.first { $0.name == "Bench Press" }?.classDef)
        #expect(TrainingPage
            .firstTimeLine(pushUp, store: model.store) == "First time on push-ups. Keep the first set easy.")
        #expect(TrainingPage.firstTimeLine(bench, store: model.store) == "First time on bench press. Start light.")
    }
}
