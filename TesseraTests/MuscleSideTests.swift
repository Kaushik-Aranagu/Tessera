import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

/// Design brief 1 (sheet 107): which side of the body an exercise shows, the routine colours and the day's union.
@MainActor
struct MuscleSideTests {
    private func primaries(_ key: String) throws -> [(name: String, role: MuscleRole)] {
        let seed = try #require(ExerciseLibrary.seeds.first { $0.key == key })
        return seed.primary.map { (name: $0.name, role: MuscleRole.primary) }
    }

    @Test func theSideRuleFollowsDesignsTable() throws {
        // Front: more primaries on the front, or a tie.
        for key in ["benchPress", "inclineBenchPress", "dip", "dbLateralRaise", "barbellCurl", "backSquat",
                    "legPress"]
        {
            #expect(try !MuscleSide.showsBack(primaries(key)), "\(key) is a front figure")
        }
        // Back: more primaries on the back.
        for key in ["barbellRow", "latPulldown", "seatedCableRow", "facePull", "pullUp", "deadlift",
                    "romanianDeadlift", "lyingLegCurl"]
        {
            #expect(try MuscleSide.showsBack(primaries(key)), "\(key) is a back figure")
        }
    }

    /// Design's table lists pushdown as a front figure, but Triceps has a region only on the back, so the rule as
    /// written gives the back. Held here as the rule's answer until Design says which one moves.
    @Test func pushdownFollowsTheRuleNotTheTable() throws {
        #expect(try MuscleSide.showsBack(primaries("ropePushdown")))
    }

    @Test func calvesAndForearmsAreNotCountedOnTheBack() {
        #expect(!MuscleSide.showsBack([(name: "Calves", role: .primary)]))
        #expect(!MuscleSide.showsBack([(name: "Forearms", role: .primary), (name: "Biceps", role: .primary)]))
        // Secondary muscles never decide the side.
        #expect(!MuscleSide.showsBack([(name: "Chest", role: .primary), (name: "Lats", role: .secondary)]))
        #expect(!MuscleSide.showsBack([]))
    }

    /// `Color ==` is unreliable for resolved colours; compare what is drawn.
    private func rgb(_ color: Color) -> [Int] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue].map { Int(($0 * 255).rounded()) }
    }

    @Test func routinesWearTheirKindsColourAndOthersTheTrainingColour() {
        #expect(rgb(MuscleTint.colour(kind: .push)) == rgb(Theme.Colors.live))
        #expect(rgb(MuscleTint.colour(kind: .pull)) == rgb(Theme.Colors.tess))
        #expect(rgb(MuscleTint.colour(kind: .legs)) == rgb(Theme.Colors.now))
        #expect(rgb(MuscleTint.colour(kind: nil)) == rgb(Theme.Colors.training))
        // The three routine colours are three different colours.
        #expect(Set([rgb(Theme.Colors.live), rgb(Theme.Colors.tess), rgb(Theme.Colors.now)]).count == 3)
    }

    @Test func aRoutineWithNoKindFallsBackToWhatItsMusclesSay() throws {
        func day(_ keys: [String]) throws -> [(name: String, role: MuscleRole)] {
            try MuscleReading.union(keys.map(primaries))
        }
        #expect(try MuscleTint.kind(ofPrimaries: day(["benchPress", "ropePushdown", "dbLateralRaise"])) == .push)
        #expect(try MuscleTint.kind(ofPrimaries: day(["barbellRow", "dbCurl"])) == .pull)
        #expect(try MuscleTint.kind(ofPrimaries: day(["backSquat", "lyingLegCurl"])) == .legs)
        // Mixed: no kind, so the Training colour.
        #expect(try MuscleTint.kind(ofPrimaries: day(["benchPress", "barbellRow"])) == nil)
        #expect(MuscleTint.kind(ofPrimaries: []) == nil)
        // The routine's own kind wins over its muscles.
        #expect(try rgb(MuscleTint.colour(kind: .pull, muscles: day(["benchPress"]))) == rgb(Theme.Colors.tess))
        #expect(try rgb(MuscleTint.colour(kind: nil, muscles: day(["benchPress"]))) == rgb(Theme.Colors.live))
    }

    @Test func theDaysUnionIsPrimaryWhereverItIsPrimary() {
        let day = MuscleReading.union([
            [(name: "Chest", role: .primary), (name: "Triceps", role: .secondary)],
            [(name: "Triceps", role: .primary), (name: "Front Delts", role: .secondary)],
        ])
        #expect(day.first { $0.name == "Triceps" }?.role == .primary)
        #expect(day.first { $0.name == "Chest" }?.role == .primary)
        #expect(day.first { $0.name == "Front Delts" }?.role == .secondary)
        #expect(day.count == 3)
    }

    @Test func pushADaySaysWhatItWorks() throws {
        // Push A's five exercises, read from the seeded library.
        let keys = ["benchPress", "overheadPress", "inclineDbPress", "dbLateralRaise", "ropePushdown"]
        let day = try MuscleReading.union(keys.map(primaries))
        let words = MuscleWords.works(day.filter { $0.role == .primary }.map(\.name))
        #expect(words == "Works chest, shoulders and triceps")
    }

    @Test func theSpokenWordsNameThePrimaryMusclesOnly() {
        let muscles: MuscleReading.Muscles = [(name: "Chest", role: .primary), (name: "Triceps", role: .secondary)]
        #expect(MuscleReading.spoken(muscles) == "works chest")
        #expect(MuscleReading.spoken([]).isEmpty)
    }

    /// Product: a private routine shows no lit muscles anywhere (the lit figure says what "Works ..." would).
    @Test func aPrivateRoutineLightsNothing() throws {
        let day = try MuscleReading.union(["benchPress", "ropePushdown"].map(primaries))
        for back in [false, true] {
            #expect(!MuscleFigureMap.roles(day, back: back).isEmpty)
            #expect(MuscleFigureMap.roles(MuscleReading.lit(day, isPrivate: true), back: back).isEmpty)
        }
        #expect(MuscleReading.lit(day, isPrivate: false).count == day.count)
    }

    @Test func theExercisePageIsPlainWhenOpenedFromAPrivateWorkout() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let routine = try #require(model.todaysRoutine())
        let exercise = try #require(model.classDef(.exercise))
        // A plain routine: the page lights as usual, whether it came from the routine or from nowhere.
        model.path = [.object(routine.id), .classDef(exercise.id)]
        #expect(!MuscleReading.openedFromPrivate(model))
        model.path = [.classDef(exercise.id)]
        #expect(!MuscleReading.openedFromPrivate(model))
        // The same routine renamed to something private: opened from it, the page is the plain outline.
        try model.engine.perform(RenameObject(object: routine.id, title: "Knee rehab day"), by: .user)
        model.path = [.object(routine.id), .classDef(exercise.id)]
        #expect(MuscleReading.openedFromPrivate(model))
        // Opened from a page that is not the private one: lit as usual.
        model.path = [.classDef(exercise.id)]
        #expect(!MuscleReading.openedFromPrivate(model))
        // From the live private workout.
        model.startRoutine(routine)
        model.isWorkoutPresented = true
        #expect(MuscleReading.openedFromPrivate(model))
        model.endWorkout()
    }
}
