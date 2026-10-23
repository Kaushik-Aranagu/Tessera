import Foundation
@testable import TesseraCore
import Testing

/// Sheet 213: the ranked things for Home's one-thing space. Strings and an accent; masked; no card.
@MainActor
struct OneThingsTests {
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

    func things(_ now: Date, plan: ObjectRecord? = nil, routines: HomeSentence.RoutinesPart? = nil,
                birthdays: [OneThingBirthday] = [], weather: OneThingWeather? = nil,
                unit: MassUnit = .kilograms) -> [OneThing]
    {
        OneThings.ranked(engine: engine, facts: facts(now), plan: plan, routines: routines, birthdays: birthdays,
                         weather: weather, unit: unit, calendar: calendar)
    }

    func trainingPlan(lift: String = "Bench Press") throws -> ObjectRecord {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: engine.classes)
        let exercise = try #require(store.allClasses().first { $0.name == lift })
        try engine.perform(AddSlot(routine: routine.id, exercise: exercise.id), by: .user)
        for week in 1 ... 3 {
            let workout = try store.create(#require(engine.classes[.workout]), title: "Push A")
            try store.setLinks("routine", on: workout, to: [routine])
            try store.set("endedAt", to: .date(at(19, day: 22 - week)), on: workout)
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: exercise)
            let ledger = TrainingLedger(store: store, classes: engine.classes)
            let first = try ledger.logSet(weight: 80, reps: 5, in: entry)
            let last = try ledger.logSet(weight: 80, reps: 5, in: entry)
            try store.set("loggedAt", to: .date(at(18, 15, day: 22 - week)), on: first)
            try store.set("loggedAt", to: .date(at(19, day: 22 - week)), on: last)
        }
        return plan
    }

    // MARK: Kinds

    @Test func trainingReadsTimeToStartTheLiftAndHisBest() throws {
        let plan = try trainingPlan()
        let thing = try #require(things(at(16, 5), plan: plan, unit: .pounds).first { $0.kind == .training })
        #expect(thing.big == "2:10" && thing.mid == "Push A, bench press first" && thing.midKeyword == "Push A")
        #expect(thing.small == "Bench best 176.4 lb, yesterday" && thing.accent == .app(.training))
        #expect(thing.done == nil && !thing.isPrivate && !thing.small.lowercased().contains("record"))
    }

    @Test func groceriesCountWhatIsToGetAndSayWhatTheyAreFor() throws {
        try engine.perform(AddGroceries(lines: ["milk", "eggs", "rice", "butter", "salt"]), by: .user)
        let plain = try #require(things(at(12)).first { $0.kind == .groceries })
        #expect(plain.big == "5" && plain.mid.hasPrefix("to get: ") && plain.midKeyword == "to get")
        #expect(plain.mid.split(separator: ",").count == 4 && plain.small == "From the groceries list")
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Fry it."), by: .user
        ).output
        let dish = try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(18)), by: .user).output
        try store.setLinks("about", on: dish, to: [recipe])
        let forTacos = try #require(things(at(12)).first { $0.kind == .groceries })
        #expect(forTacos.small == "For tacos tonight" && forTacos.accent == .app(.kitchen))
    }

    @Test func aTaskIsStruckThroughAndItsUndoLineIsMasked() throws {
        let made = try engine.perform(CreateTask(title: "Pack the charger", startsAt: at(15)), by: .user).output
        let thing = try #require(things(at(12)).first { $0.kind == .task })
        #expect(thing.big == "Pack the charger" && thing.mid == "Today at 3 pm" && thing
            .small == "Hold to strike it through")
        #expect(thing.done == .task(made.id) && thing.accent == .ink && thing.undoLine == "Pack the charger, done.")
        // Doing it through the engine is the one op, and one Undo.
        let result = try engine.perform(SetTaskDone(task: made.id), by: .user)
        #expect(engine.store.value("isDone", of: made) == .bool(true))
        engine.undo(result.record)
        #expect(engine.store.value("isDone", of: made) != .bool(true))
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: at(13)), by: .user)
        let hidden = try #require(things(at(12)).first { $0.kind == .task })
        #expect(hidden.big == "Private" && hidden.isPrivate && hidden.undoLine == "Private, done.")
    }

    @Test func aListReadsDoneOfTotalAndWhatIsNext() throws {
        let list = try store.create(#require(engine.classes[.list]), title: "Packing")
        for item in ["socks", "charger", "passport"] {
            _ = try engine.perform(
                AddListItem(list: list.id, text: item),
                by: .user
            )
        }
        let first = try #require(ListContents(store: store, classes: engine.classes).open(in: list).first)
        try engine.perform(CheckListItem(item: first.object.id), by: .user)
        let thing = try #require(things(at(12)).first { $0.kind == .list })
        #expect(thing.big == "1 of 3" && thing.mid == "Packing" && thing.midKeyword == "Packing")
        #expect(thing.small.hasPrefix("Next up: ") && thing.accent == .app(.lists))
        let secret = try store.create(#require(engine.classes[.list]), title: "Lexapro refills")
        _ = try engine.perform(AddListItem(list: secret.id, text: "pharmacy"), by: .user)
        let lead = things(at(12)).filter { $0.kind == .list }
        #expect(lead
            .allSatisfy { !$0.mid.lowercased().contains("lexapro") && !$0.small.lowercased().contains("pharmacy") })
    }

    @Test func aBirthdayIsLocalAndReadsTheDayAndTheAge() throws {
        let mom = OneThingBirthday(name: "Mom", month: 10, day: 25, year: 1966)
        let thing = try #require(things(at(12), birthdays: [mom]).first { $0.kind == .birthday })
        #expect(thing.big == "Sunday" && thing.mid == "Mom turns 60" && thing.midKeyword == "Mom")
        #expect(thing.small == "Three days." && thing.accent == .birthday)
        let today = OneThingBirthday(name: "Sam", month: 10, day: 22, note: "A call at lunch")
        let now = try #require(things(at(12), birthdays: [today]).first { $0.kind == .birthday })
        #expect(now.big == "Today" && now.mid == "Sam's birthday" && now.small == "A call at lunch")
        // Far away, or a name that is private: no thing.
        #expect(things(at(12), birthdays: [.init(name: "Far", month: 3, day: 3)]).allSatisfy { $0.kind != .birthday })
        #expect(things(at(12), birthdays: [.init(name: "Lexapro Lee", month: 10, day: 23)])
            .allSatisfy { $0.kind != .birthday })
    }

    @Test func weatherIsASampleUntilItIsReal() throws {
        let sample = OneThingWeather(degrees: 64, summary: "Clear until 4, then rain")
        let thing = try #require(things(at(12), weather: sample).first { $0.kind == .weather })
        #expect(thing.big == "64°" && thing.mid == "Clear until 4, then rain" && thing.accent == .sky)
        #expect(thing.small.hasPrefix("Sunset at ") && thing.small.hasSuffix("A sample until Apple weather"))
        let real = OneThingWeather(degrees: 64, summary: "Clear", isSample: false)
        #expect(try #require(things(at(12), weather: real).first).small.contains("sample") == false)
        #expect(things(at(12)).allSatisfy { $0.kind != .weather })
    }

    @Test func aRoutineReadsItsNextStart() throws {
        let runs = (1 ... 8).map { day in RoutineRun(start: at(20, day: 22 - day), end: at(20, 20, day: 22 - day)) }
        let facts = RoutinesLanding.facts(items: [.init(name: "Stretch", count: 4, runs: runs)], running: nil,
                                          now: at(12), calendar: calendar)
        let thing = try #require(things(at(12), routines: .init(facts: facts, nextUsualStart: at(20)))
            .first { $0.kind == .routine })
        #expect(thing.big == "8 pm" && thing.mid == "Stretch" && thing.accent == .app(.routines))
    }

    @Test func theShortWhyOfOneVeryLongWordIsNeverEmpty() throws {
        let task = try engine.perform(CreateTask(title: "x"), by: .user).output
        let pick = Pick(item: NowItem(id: task.id, kind: .task, object: task, title: "x", startsAt: nil, endsAt: nil,
                                      nextStep: nil),
                        score: 1, why: "Averyveryveryveryveryveryverylongword", isAsk: false)
        #expect(pick.shortWhy == String("Averyveryveryveryveryveryverylongword".prefix(30)) && pick.shortWhy
            .count == 30)
        #expect(!pick.shortWhy.contains("…"))
    }

    @Test func aPrivateTrainingThingShowsNoCountdown() throws {
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "Rehab", routines: [secret.id]), by: .user).output
        let hidden = try #require(things(at(9), plan: plan).first { $0.kind == .training })
        #expect(hidden.big == "Today" && hidden.isPrivate)
    }

    @Test func aRoutinesNameAndTimeComeFromTheSameRoutine() throws {
        /// Many runs of Journal at 9 pm make it the first line; Stretch at 8 pm is the next one to start.
        func routineWithRuns(_ title: String, hour: Int, runs count: Int) throws {
            let routine = try engine.perform(CreateRoutine(title: title), by: .user).output
            for day in 1 ... count {
                let workout = try store.create(#require(engine.classes[.workout]), title: title)
                try store.setLinks("routine", on: workout, to: [routine])
                try store.set("startedAt", to: .date(at(hour, day: 22 - day)), on: workout)
                try store.set("endedAt", to: .date(at(hour, 20, day: 22 - day)), on: workout)
            }
        }
        try routineWithRuns("Journal", hour: 21, runs: 12)
        try routineWithRuns("Stretch", hour: 20, runs: 8)
        let part = HomeSentence.RoutinesPart.make(engine: engine, now: at(12), calendar: calendar)
        #expect(part.nextRoutine == "Stretch" && part.nextUsualStart == at(20))
        let thing = try #require(things(at(12), routines: part).first { $0.kind == .routine })
        #expect(thing.mid == "Stretch" && thing.big == "8 pm")
        let line = AppSummaryLines.lines(engine: engine, plan: nil, routines: part, now: at(12), calendar: calendar)
            .first { $0.app == .routines }
        #expect(line?.text == "Stretch at 8 pm")
    }

    @Test func birthdayAndWeatherHaveRealTargetsAndBirthdayIdsAreStable() throws {
        let mom = OneThingBirthday(name: "Mom", month: 10, day: 25, year: 1966)
        let first = try #require(things(at(12), birthdays: [mom]).first { $0.kind == .birthday })
        let again = try #require(things(at(12), birthdays: [mom]).first { $0.kind == .birthday })
        #expect(first.target == .today && first.id == again.id && first.id == "birthday-10-25-0")
        #expect(!first.id.contains("Mom"))
        let weather = try #require(things(at(12), weather: OneThingWeather(degrees: 64, summary: "Clear"))
            .first { $0.kind == .weather })
        #expect(weather.target == .weather)
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        #expect(try #require(things(at(12)).first { $0.kind == .groceries }).target == .room(.kitchen))
    }

    // MARK: Order and walls

    @Test func theMostUrgentComesFirstAtMostSevenAndWeatherLast() throws {
        let plan = try trainingPlan()
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        _ = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(14)), by: .user)
        let list = try store.create(#require(engine.classes[.list]), title: "Packing")
        _ = try engine.perform(AddListItem(list: list.id, text: "socks"), by: .user)
        let ranked = things(at(13), plan: plan, birthdays: [.init(name: "Mom", month: 10, day: 22)],
                            weather: OneThingWeather(degrees: 64, summary: "Clear"))
        #expect(ranked.first?.kind == .birthday)
        #expect(ranked.last?.kind == .weather)
        #expect(ranked.count <= 7 && Set(ranked.map(\.id)).count == ranked.count)
        #expect(OneThings.ranked(engine: engine, facts: facts(at(13)), plan: plan, calendar: calendar, limit: 2)
            .count == 2)
    }

    @Test func privateThingsReadTheirLabelAndNoCalendarMoneyBodyOrAppTargetHasThem() throws {
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "Rehab", routines: [secret.id]), by: .user).output
        let hidden = try #require(things(at(9), plan: plan).first { $0.kind == .training })
        #expect(hidden.mid == "Private" && hidden.isPrivate && hidden.midKeyword == nil)
        #expect(!(hidden.big + hidden.mid + hidden.small).lowercased().contains("knee"))
        // A calendar event is never a source.
        let event = try store.create(#require(engine.classes[.event]), title: "Dentist")
        try store.set("start", to: .date(at(14)), on: event)
        #expect(things(at(12)).allSatisfy { !($0.big + $0.mid + $0.small).contains("Dentist") })
        // The types stay out of every writer: widgets, Watch, Shared, intents, Tess, the app outside Home.
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        var checked = 0
        for (path, allowed) in [("../Widgets", ""), ("../Watch", ""), ("../Shared", ""), ("Sources/TesseraIntents", ""),
                                ("Sources/TesseraTess", ""), ("../App", ""), ("../DesignSystem", ""),
                                ("../Features", "/Features/Home/")]
        {
            var inThisFolder = 0
            defer { #expect(inThisFolder > 0, "no Swift files found in \(path)") }
            guard let walker = FileManager.default.enumerator(at: package.appending(path: path),
                                                              includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in walker where url.pathExtension == "swift"
                && (allowed.isEmpty || !url.path.contains(allowed))
            {
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
                checked += 1
                inThisFolder += 1
                for word in ["OneThing", "OneThingBirthday", "OneThingWeather", "OneThings"] {
                    let pattern = try Regex("\\b\(word)\\b")
                    #expect(text.firstMatch(of: pattern) == nil, "\(word) in \(url.path)")
                }
            }
        }
        #expect(checked > 100)
    }
}
