import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The You page's derived lines (Design 108 section 3, huddle B2): the four sentences, the training totals and the
/// bests, and that a private workout never reaches a best.
@MainActor
struct MePageTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    private let kg: (Double) -> String = { "\($0.formatted(.number.precision(.fractionLength(0 ... 2)))) kg" }

    // MARK: The four sentences

    @Test func weightIsHiddenUntilTapped() {
        #expect(MeCopy.weightWord(82.4, shown: false, format: kg) == "hidden")
        #expect(MeCopy.weightWord(82.4, shown: true, format: kg) == "82.4 kg")
        #expect(MeCopy.weightTail(82.4) == ", from your last weigh-in.")
    }

    @Test func noWeighInSaysNotLogged() {
        #expect(MeCopy.weightWord(nil, shown: true, format: kg) == "not logged")
        #expect(MeCopy.weightTail(nil) == ".")
    }

    @Test func theOtherThreeAreNotSaidAndTheKeptLineNamesThePhone() {
        #expect(MeCopy.unsaidFields == ["Height", "Age", "Sex"])
        #expect(MeCopy.notSaid == "not said")
        #expect(MeCopy.keptLine.contains("stays on this phone"))
        #expect(MeCopy.keptLine.contains("never goes to Claude"))
    }

    // MARK: Training lines

    @Test func workoutTotalsReadAsASentence() throws {
        let march = try #require(calendar.date(from: DateComponents(year: 2025, month: 3, day: 9, hour: 18)))
        #expect(MeCopy.workouts(0, since: nil) == "No workouts logged yet.")
        #expect(MeCopy.workouts(1, since: march, calendar: calendar) == "1 workout, in March 2025.")
        #expect(MeCopy.workouts(1142, since: march, calendar: calendar) == "1,142 workouts since March 2025.")
    }

    @Test func setsAndRhythmLines() {
        #expect(MeCopy.sets(0) == nil)
        #expect(MeCopy.sets(1) == "1 working set.")
        #expect(MeCopy.sets(1860) == "1,860 working sets.")
        #expect(MeCopy.rhythm(nil) == nil)
        #expect(MeCopy.rhythm(1) == "Trains 1 day a week.")
        #expect(MeCopy.rhythm(4) == "Trains 4 days a week.")
    }

    // MARK: Bests

    @Test func bestsAreMostTrainedFirstThenByName() {
        let lifts = [
            MeFacts.Best(id: UUID(), name: "Squat", bestE1RM: 140, sessions: 3),
            MeFacts.Best(id: UUID(), name: "Bench Press", bestE1RM: 100, sessions: 8),
            MeFacts.Best(id: UUID(), name: "Deadlift", bestE1RM: 180, sessions: 3),
        ]
        #expect(MeCopy.ordered(lifts).map(\.name) == ["Bench Press", "Deadlift", "Squat"])
    }

    @Test func bestTrailingIsTheEstimateOrTheSessionCount() {
        let bench = MeFacts.Best(id: UUID(), name: "Bench Press", bestE1RM: 102.46, sessions: 48)
        #expect(MeCopy.bestTrailing(bench, format: kg) == "e1RM 102.5 kg")
        #expect(MeCopy.bestSpoken(bench, format: kg)
            == "Bench Press, best estimated one-rep max 102.5 kg, 48 sessions")
        let plank = MeFacts.Best(id: UUID(), name: "Plank", bestE1RM: nil, sessions: 1)
        #expect(MeCopy.bestTrailing(plank, format: kg) == "1 session")
        #expect(MeCopy.bestSpoken(plank, format: kg) == "Plank, 1 session")
    }

    @Test func theRevealWordShowsOnlyPastFive() {
        #expect(MeCopy.moreWord(total: 5, expanded: false) == nil)
        #expect(MeCopy.moreWord(total: 14, expanded: false) == "All 14")
        #expect(MeCopy.moreWord(total: 14, expanded: true) == "Fewer")
    }

    // MARK: Facts from the store

    private func workout(_ title: String, daysAgo: Double, _ sets: [(Double, Double)]) throws {
        let workout = try model.store.create(#require(model.classes[.workout]), title: title)
        let ended = AppClock.now.addingTimeInterval(-daysAgo * 86400)
        try model.store.set("startedAt", to: .date(ended.addingTimeInterval(-3600)), on: workout)
        try model.store.set("endedAt", to: .date(ended), on: workout)
        let entry = try model.store.create(#require(model.classes[.exerciseEntry]), parent: workout)
        try model.store.setClassLink("exercise", on: entry, to: #require(model.classes[.benchPress]))
        for (weight, reps) in sets {
            try model.ledger.logSet(weight: weight, reps: reps, in: entry)
        }
    }

    @Test func factsCountWorkoutsAndSetsAndKeepPrivateWorkoutsOutOfBests() throws {
        try workout("Push A", daysAgo: 10, [(80, 8), (80, 7)])
        try workout("Push B", daysAgo: 3, [(85, 5)])
        // A private routine's sets count toward the totals but never show as a best.
        try workout("Knee rehab day", daysAgo: 1, [(140, 5)])
        model.touch()

        let facts = MeFacts.read(model)
        #expect(facts.workouts == 3)
        #expect(facts.workingSets == 4)
        let bench = try #require(facts.bests.first { $0.name == "Bench Press" })
        #expect(bench.sessions == 2)
        let best = try #require(bench.bestE1RM)
        let privateE1RM = try #require(model.ledger.e1RM(weight: 140, reps: 5))
        #expect(best < privateE1RM)
        #expect(best > 90)
    }

    @Test func aFreshInstallHasNoTotalsAndNoBests() {
        let facts = MeFacts.read(model)
        #expect(facts.workouts == 0)
        #expect(facts.bests.isEmpty)
        #expect(facts.weightKg == nil)
    }
}
