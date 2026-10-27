import Foundation
@testable import TesseraCore
import Testing

/// Sheet 201: when a moment plays and what its line says. On the phone only; masked; no amounts.
@MainActor
struct MosaicMomentSourceTests {
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

    func facts(_ now: Date = .now, events: [HandsEvent] = []) -> MosaicFacts {
        MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4), events: events)
    }

    func inputs(_ now: Date = .now, quiet: Bool = false, played: Set<String> = [],
                last: (kind: MosaicMomentKind, at: Date)? = nil, weather: MosaicWeather? = nil,
                tess: String? = nil, events: [HandsEvent] = []) -> MosaicMomentInputs
    {
        MosaicMomentInputs.make(engine: engine, facts: facts(now, events: events), quiet: quiet, last: last,
                                played: played, weather: weather, tessLine: tess, events: events)
    }

    func candidate(_ kind: MosaicMomentKind, _ key: String, at: Date = .now) -> MosaicMomentInputs.Candidate {
        MosaicMomentInputs.Candidate(kind: kind, clause: MosaicMomentSource.plain(key), at: at, key: key)
    }

    // MARK: Rules

    @Test func oneMomentInTenMinutesExceptATimerAndAFinish() {
        let now = Date.now
        let recent = (kind: MosaicMomentKind.announcement, at: now.addingTimeInterval(-300))
        var input = MosaicMomentInputs(
            now: now,
            last: recent,
            candidates: [candidate(.tess, "t"), candidate(.reminder, "r")]
        )
        #expect(MosaicMomentSource.next(input) == nil)
        input.candidates.append(candidate(.finished, "f"))
        #expect(MosaicMomentSource.next(input)?.kind == .finished)
        input.candidates = [candidate(.timer, "x")]
        #expect(MosaicMomentSource.next(input)?.kind == .timer)
        input.last = (.announcement, now.addingTimeInterval(-601))
        input.candidates = [candidate(.tess, "t")]
        #expect(MosaicMomentSource.next(input)?.kind == .tess)
    }

    @Test func quietHoursHoldEverythingButATimer() {
        let now = Date.now
        let input = MosaicMomentInputs(now: now, quiet: true, candidates: [
            candidate(.tess, "t"), candidate(.finished, "f"), candidate(.best, "b"), candidate(.weather(.snow), "w"),
        ])
        #expect(MosaicMomentSource.next(input) == nil)
        var withTimer = input
        withTimer.candidates.append(candidate(.timer, "x"))
        #expect(MosaicMomentSource.next(withTimer)?.kind == .timer)
    }

    @Test func priorityAndNeverTwice() {
        let now = Date.now
        let kinds: [MosaicMomentKind] = [.weather(.fog), .tess, .announcement, .delivery, .reminder, .best, .finished,
                                         .timer]
        var input = MosaicMomentInputs(now: now, candidates: kinds.enumerated().map { candidate($1, "k\($0)") })
        var order: [MosaicMomentKind] = []
        while let pick = MosaicMomentSource.next(input) {
            order.append(pick.kind)
            input.played.insert(pick.key)
        }
        #expect(order == [.timer, .finished, .best, .reminder, .delivery, .announcement, .tess, .weather(.fog)])
    }

    // MARK: Sources

    @Test func weatherIsInertUntilTheHostPassesIt() throws {
        #expect(MosaicMomentSource.next(inputs()) == nil)
        let pick = try #require(MosaicMomentSource.next(inputs(weather: .snow)))
        #expect(pick.kind == .weather(.snow) && pick.line == "It is snowing")
        for weather in MosaicWeather.allCases {
            #expect(!MosaicMomentSource.weatherLine(weather).isEmpty)
        }
    }

    @Test func anAnnouncementComesFifteenMinutesAheadAndIsMasked() throws {
        let now = Date.now
        _ = try engine.perform(CreateTask(title: "Tacos", startsAt: now.addingTimeInterval(14 * 60 + 30)), by: .user)
        let pick = try #require(MosaicMomentSource.next(inputs(now)))
        #expect(pick.kind == .announcement && pick.line == "Tacos in 14 min")
        // A task belongs to no app: plain. A cook, a workout or a routine takes its app word.
        #expect(pick.clause.app == nil && pick.clause.keyWord == nil)
        let cook = HandsEvent(app: .kitchen, label: "Soup", start: now.addingTimeInterval(10 * 60),
                              end: now.addingTimeInterval(40 * 60), hands: [], isFixed: true)
        let app = try #require(inputs(now, events: [cook]).candidates.first { $0.clause.text.hasPrefix("Soup") })
        #expect(app.clause.app == .kitchen && app.clause.keyWord == 0 ..< 4 && app.clause.text == "Soup in 10 min")
        let far = Date.now
        #expect(MosaicMomentSource.next(inputs(far.addingTimeInterval(-3600))) == nil)
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: now.addingTimeInterval(5 * 60)), by: .user)
        let hidden = try #require(MosaicMomentSource.next(inputs(now)))
        #expect(hidden.line == "Private task in 5 min" && hidden.clause.keyWord == nil && hidden.clause.app == nil)
    }

    @Test func aFinishedTimerSaysItsLabelOrJustTimer() throws {
        let now = Date.now
        try engine.perform(StartKitchenTimer(label: "rice", minutes: 0.01), by: .user)
        let pick = try #require(MosaicMomentSource.next(inputs(now.addingTimeInterval(2))))
        #expect(pick.kind == .timer && pick.line == "Rice is done" && pick.clause.app == .kitchen)
        // A label with no words, or a private one, reads "Timer".
        try engine.perform(StartKitchenTimer(label: "10", minutes: 0.01), by: .user)
        let lines = Set(inputs(now.addingTimeInterval(2)).candidates.filter { $0.kind == .timer }.map(\.clause.text))
        #expect(lines.contains("Timer is done") && lines.contains("Rice is done"))
    }

    @Test func aFinishPlaysOnceAndNeverHasATitle() throws {
        let task = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user).output
        try engine.perform(SetTaskDone(task: task.id), by: .user)
        let pick = try #require(MosaicMomentSource.next(inputs()))
        #expect(pick.kind == .finished && pick.line == "Done")
        #expect(MosaicMomentSource.next(inputs(played: [pick.key])) == nil)
        // An old finish has passed: it is not played late.
        #expect(MosaicMomentSource.next(inputs(Date.now.addingTimeInterval(600))) == nil)
    }

    @Test func aReminderIsDueNowAndMasked() throws {
        let now = Date.now
        _ = try engine.perform(CreateTask(title: "Call the landlord", startsAt: now.addingTimeInterval(-30)), by: .user)
        let pick = try #require(MosaicMomentSource.next(inputs(now)))
        #expect(pick.kind == .reminder && pick.line == "Call the landlord, now")
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: now.addingTimeInterval(-20)), by: .user)
        let lines = inputs(now).candidates.filter { $0.kind == .reminder }.map(\.clause.text)
        #expect(lines.contains("Private task, now") && !lines.joined().lowercased().contains("lexapro"))
        let event = HandsEvent(app: .routines, label: "Morning", start: now.addingTimeInterval(-10),
                               end: now.addingTimeInterval(1200), hands: [], isFixed: false)
        #expect(inputs(now, events: [event]).candidates.contains { $0.clause.text == "Morning, now" })
    }

    @Test func deliveryComesOnlyFromHisOwnMark() throws {
        #expect(!inputs().candidates.contains { $0.kind == .delivery })
        try engine.perform(MarkArrived(what: MarkArrived.groceries), by: .user)
        let pick = try #require(MosaicMomentSource.next(inputs()))
        #expect(pick.kind == .delivery && pick.line == "Groceries are here" && pick.clause.app == .kitchen
            && pick.tone == .accent(.kitchen))
        try engine.perform(MarkArrived(), by: .user)
        #expect(inputs().candidates.contains { $0.clause.text == "A delivery is here" })
        #expect(!MarkArrived.descriptor.isOfferedToModel)
    }

    @Test func aNewBestIsOnlyAfterABestAndPrivateOnesStayPlain() throws {
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: engine.classes)
        let bench = try #require(store.allClasses().first { $0.name == "Bench Press" })
        func session(_ title: String, weight: Double, routine: ObjectRecord? = nil) throws {
            let workout = try store.create(#require(engine.classes[.workout]), title: title)
            if let routine {
                try store.setLinks("routine", on: workout, to: [routine])
            }
            try engine.perform(StartWorkout(workout: workout.id), by: .user)
            let entry = try engine.perform(AddExercise(workout: workout.id, exercise: bench.id), by: .user).output
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: 5), by: .user)
            try engine.perform(FinishWorkout(workout: workout.id), by: .user)
        }
        try session("Push A", weight: 80)
        // The first ever lift is not a "best".
        #expect(!inputs().candidates.contains { $0.kind == .best })
        try session("Push A", weight: 85)
        let best = try #require(inputs().candidates.first { $0.kind == .best })
        #expect(best.clause.text == "A new best" && best.clause.app == .training && !best.clause.text
            .contains("record"))
        #expect(best.tone == .accent(.training))
        // Its own finish does not play first: the best is what plays.
        let recent = inputs().candidates
        let others = Set(recent.filter { $0.kind == .finished }.map(\.key))
        #expect(MosaicMomentSource.next(inputs(played: others))?.kind == .best)
        #expect(!recent.contains { $0.key.hasPrefix("finish-") && $0.at == best.at })
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        try session("Session", weight: 90, routine: secret)
        // A best from a private workout is a plain finish: no Training accent, nothing about it.
        let hidden = inputs().candidates.filter { $0.key.hasPrefix("best-") && $0.kind == .finished }
        #expect(hidden.count == 1)
        #expect(hidden.allSatisfy { $0.clause.text == "Done" && $0.clause.app == nil && $0.clause.keyWord == nil
                && $0.tone == .glaze
        })
        #expect(!inputs().candidates.map(\.clause.text).joined().lowercased().contains("knee"))
    }

    @Test func tessSpeaksOnlyWhatPassesTheWallsAndIsNeverAnAppWord() throws {
        let pick = try #require(MosaicMomentSource.next(inputs(tess: "Limes are low")))
        #expect(pick.kind == .tess && pick.line == "Limes are low" && pick.clause.app == nil
            && pick.clause.keyWord == nil)
        for walled in [
            "Your balance is 1200 dollars",
            "You weighed 82 kg",
            "Lexapro is low",
            "That was 600 calories",
        ] {
            #expect(MosaicMomentSource.next(inputs(tess: walled)) == nil, "\(walled)")
        }
    }

    @Test func aMomentCarriesThreeClausesAndItsKeysHoldNoWords() throws {
        let now = Date.now
        _ = try engine.perform(CreateTask(title: "Tacos", startsAt: now.addingTimeInterval(10 * 60)), by: .user)
        let input = inputs(now, tess: "Limes are low")
        let pick = try #require(MosaicMomentSource.next(input))
        #expect(pick.clauses.count == 3 && pick.clauses[0] == pick.clause)
        #expect(!pick.clauses[1].text.hasSuffix(".") && pick.clauses[2].text == "Free 10 min, then Tacos")
        // Keys can be kept: none of them holds a line or a label.
        let plain = inputs(now, tess: "Limes are low")
        for candidate in plain.candidates where candidate.kind == .tess {
            #expect(!candidate.key.contains("Limes") && !candidate.key.lowercased().contains("limes"))
        }
        let routine = HandsEvent(app: .routines, label: "Morning", start: now.addingTimeInterval(-10),
                                 end: now.addingTimeInterval(1200), hands: [], isFixed: false)
        for candidate in inputs(now, events: [routine]).candidates where candidate.kind == .reminder {
            #expect(!candidate.key.contains("Morning"))
        }
        #expect(MosaicMomentSource.hashed("a") != MosaicMomentSource.hashed("b"))
    }
}
