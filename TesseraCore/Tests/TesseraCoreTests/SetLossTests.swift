import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research's re-trace after #254 (docs/research/fixtures/grammar-regression.md): phrases that lost or invented a set.
@MainActor
struct SetLossTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let grammar: TessGrammar
    /// Thursday 15 October 2026, 18:10 in Los Angeles.
    let context = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        grammar = TessGrammar(store: store, classes: classes)
    }

    /// "lift Bench Press 80x8", "set 80x8", "task Call mum", "groceries milk", "ask …", "nil".
    func read(_ parse: TessGrammar.Parse?) -> String {
        switch parse {
        case nil: "nil"
        case let .lift(exercise, sets, reps, weight, _)?:
            "lift \(exercise.name) \(sets > 1 ? "\(sets)x" : "")\(TessVoice.number(weight))x\(TessVoice.number(reps))"
        case let .set(_, weight, reps, _, _, _, _, _)?: "set \(TessVoice.number(weight))x\(TessVoice.number(reps))"
        case let .task(title, startsAt)?: "task \(title)\(startsAt == nil ? "" : " @")"
        case let .groceries(lines)?: "groceries \(lines.joined(separator: ", "))"
        case let .sets(parts)?: parts.map { read($0) }.joined(separator: " + ")
        case let .askDatedLift(ask)?: "ask \(ask.line)"
        case let .ask(line)?: "ask \(line)"
        case let .askSetCount(ask)?: "ask \(ask.line)"
        case let .spend(amount, note, on)?: "spend \(amount.typed)\(note.isEmpty ? "" : " - \(note)")\(on == nil ? "" : " @")"
        case let parse?: "\(parse)"
        }
    }

    @Test(arguments: [
        ("A059", "buy milk and bench 80x8", "groceries milk + lift Bench Press 80x8"),
        ("A162", "bench 80x8, call mum thu", "lift Bench Press 80x8 + task Call mum @"),
        ("A163", "bench 80x8 and call mum thu", "lift Bench Press 80x8 + task Call mum @"),
        ("A167", "bench 3x5 at 80 then call mum at 7", "lift Bench Press 3x80x5 + task Call mum @"),
        ("A181", "pull ups 3x8", "lift Pull-Up 3x0x8"),
        ("A182", "curls 15x12", "lift Dumbbell Curl 15x12"),
        ("A183", "bench 80x8 today", "lift Bench Press 80x8"),
        ("A184", "bench 80x8 at 7", "nil"),
        ("A027", "squat 100x5 tue", "ask Squat 100 × 5 for Tuesday?"),
        ("KEEP1", "ohp 3x8 at 45", "lift Overhead Press 3x45x8"),
        ("A164", "squat 100x5 and buy milk", "lift Back Squat 100x5 + groceries milk"),
        ("QA274", "bench 3x5 at 7", "ask Bench 3 × 5 at what weight?"),
        // QA F1, G1, W1 on #282 and Research's K901+ notes.
        ("F1a", "bench 3 sets of 8", "ask Bench 3 × 8 at what weight?"),
        ("F1b", "bench 3x8", "ask Bench 3 × 8 at what weight?"),
        ("F1c", "dips 3 sets of 10", "lift Dip 3x0x10"),
        ("F1d", "bench 3 sets of 8 at 80", "lift Bench Press 3x80x8"),
        ("G1", "spent $40 on groceries", "nil-or-not-groceries"),
        ("W1a", "Tess's birthday fri", "task Tess's birthday @"),
        ("W1b", "Tess dinner fri", "task Tess dinner @"),
        ("R1a", "add eggs for groceries", "groceries eggs"),
        ("R1b", "buy milk for groceries", "groceries milk"),
        ("R1c", "get milk for groceries", "groceries milk"),
        // QA F2 on #287: machines and cables stride from 0, dumbbells start at 2: a bare N x M is never N kg.
        ("F2a", "lat pulldown 3x8", "ask Lat Pulldown 3 × 8 at what weight?"),
        ("F2b", "leg press 3x8", "ask Leg Press 3 × 8 at what weight?"),
        ("F2c", "curls 3x8", "ask Dumbbell Curl 3 × 8 at what weight?"),
        ("F2d", "lat pulldown 3x8 at 7", "ask Lat Pulldown 3 × 8 at what weight?"),
        ("F2e", "lat pulldown 55x8", "lift Lat Pulldown 55x8"),
        ("F2f", "curls 14x10", "lift Dumbbell Curl 14x10"),
        // QA F3 on #289: any loaded kit, N up to 10, never N kg.
        ("F3a", "leg press 5x5", "ask Leg Press 5 × 5 at what weight?"),
        ("F3b", "lat pulldown 6x8", "ask Lat Pulldown 6 × 8 at what weight?"),
        ("F3c", "lat pulldown 10x10", "ask Lat Pulldown 10 × 10 at what weight?"),
        ("F3d", "curls 8x10", "ask Dumbbell Curl 8 × 10 at what weight?"),
        ("F3e", "curls 3x10 at 5", "ask Dumbbell Curl 3 × 10 at what weight?"),
        ("F3f", "leg press 5 kg x 5", "lift Leg Press 5x5"),
        ("F3g", "kettlebell swing 3x15", "ask Kettlebell Swing 3 × 15 at what weight?"),
        ("F5", "bench 3 sets of 8 at 7", "ask Bench 3 × 8 at what weight?"),
        ("F4a", "cable row 5x10", "ask Seated Cable Row 5 × 10 at what weight?"),
        ("F6", "bench 3 sets of 8 @ 7", "ask Bench 3 × 8 at what weight?"),
        // Normal sets that must still log (merge check on #289).
        ("KEEP4", "curls 12x10 at 12", "lift Dumbbell Curl 12x12x10"),
        ("KEEP5", "bench 3x8 at 80", "lift Bench Press 3x80x8"),
        // Research's US shop check: money is never groceries or a task (now a spend, on the phone); a unit price is a
        // price, not a spend.
        ("US1", "spent $1,250 on rent", "spend $1,250 - rent"),
        ("US2", "spent $23.47 at trader joe's sat", "spend $23.47 - trader joe's @"),
        ("US3", "chicken $1.29/lb, rice", "groceries chicken $1.29/lb, rice"),
        // Research's 113 re-trace and Design's Speak review.
        ("R113b", "Bench 80 kg, 8 reps only.", "lift Bench Press 80x8"),
        ("R113c", "Bench 3 sets of 8 at 80.", "lift Bench Press 3x80x8"),
        ("SPK1", "oat milk and eggs for groceries", "groceries oat milk, eggs"),
        ("SPK2", "eggs on the shopping list", "groceries eggs"),
        ("SPK3", "Okay Tess, bench 80 for 8", "lift Bench Press 80x8"),
        ("KEEP3", "bench 80x8 heavy", "nil"),
    ])
    func idle(_ id: String, _ phrase: String, _ expected: String) {
        let got = read(grammar.parse(phrase, context: context))
        switch expected {
        case "nil-or-not-groceries": #expect(!got.hasPrefix("groceries"), "\(id): \(got)")
        case "not-stripped": #expect(got.lowercased().contains("tess"), "\(id): \(got)")
        default: #expect(got == expected, "\(id)")
        }
    }

    @Test func aLiftAndADatedErrandInAWorkout() throws {
        // A171: Bench in focus; the set and the Friday task both stay.
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        var live = context
        live.entry = entry.id
        live.process = workout.id
        #expect(read(grammar.parse("bench 80x8 dentist fri", context: live)) == "set 80x8 + task Dentist @")
        #expect(read(grammar.parse("80 x 6 to failure at 9", context: live)) == "set 80x6")
        // QA L3 on #287: "Tess 80 for 8" with no comma.
        #expect(read(grammar.parse("Tess 80 for 8", context: live)) == "set 80x8")
        // R113a: a wake word and a dictated full stop, during a workout: the set, never Groceries.
        #expect(read(grammar.parse("Okay Tess, 80 for 8.", context: live)) == "set 80x8")
        #expect(read(grammar.parse("80 for 8, milk", context: live)) != "groceries 80 for 8, milk")
        // QA R2 on #262: number words and an errand together.
        #expect(read(grammar.parse("bench eighty for eight, call mum at seven", context: live))
            == "set 80x8 + task Call mum @")
    }

    @Test func theMissLineOffersAnExampleOnlyWhereItFits() async throws {
        let tess = TessCaptureEngine(engine: engine)
        #expect(await tess.capture("what is a plate?", context: context)
            .line == "what is a plate?, kept to sort later.")
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        var live = context
        live.entry = entry.id
        #expect(await tess.capture("what is a plate?", context: live)
            .line == "Didn't catch that. Try \u{201C}80 × 8\u{201D}.")
    }

    @Test func spokenUnitsNeedANumberBesideThem() {
        // QA on #262: Swift's `where` guarded only the last pattern of each case.
        #expect(TessSpoken.numbers("pounds of flour") == "pounds of flour")
        #expect(TessSpoken.numbers("times square") == "times square")
        #expect(TessSpoken.numbers("kilos") == "kilos")
        #expect(TessSpoken.numbers("eighty kilos times eight") == "80 kg x 8")
        #expect(TessSpoken.numbers("bench 80 kg, 8 reps only") == "bench 80 kg, 8 reps")
    }

    @Test func receiptsForTheNewShapes() async {
        let tess = TessCaptureEngine(engine: engine)
        // A181: no "at 0" on a bodyweight lift.
        #expect(await tess.capture("pull ups 3x8", context: context).line == "Pull-Up 3 × 8. Added to today.")
        // A027: the dated ask and its LOG line say "Squat".
        #expect(await tess.capture("squat 100x5 tue", context: context).line == "Squat 100 × 5 for Tuesday?")
        #expect(tess.answer(TessDatedLiftAsk.Choice.log, context: context).line == "Squat 100 × 5 logged for Tuesday.")
    }

    @Test func aHundredCommaFiveInAWorkoutIsNeverGroceries() throws {
        // K885.
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        var live = context
        live.entry = entry.id
        #expect(!read(grammar.parse("a hundred, five", context: live)).hasPrefix("groceries"))
    }

    @Test func aNamedBodyweightLiftInFocusAsks() throws {
        // Product 9:40 PM PT: "pull ups 10x8" with Pull-Up in focus asks; with no workout it stays sets (A181).
        let workout = try store.create(#require(classes[.workout]), title: "Pull")
        let pullUp = try #require(store.classDef(id: SystemCatalog.stableID("library.pullUp")))
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: pullUp.id), by: .user).output
        var live = context
        live.entry = entry.id
        #expect(read(grammar.parse("pull ups 10x8", context: live)) == "ask 10 × 8: 10 sets, or +10 kg?")
        #expect(read(grammar.parse("pull ups 3x8", context: context)) == "lift Pull-Up 3x0x8")
    }

    @Test func whileShoppingSetsAndForGroceriesAreRead() throws {
        // Research on #282: shopping running, a workout suspended.
        var shopping = context
        shopping.process = Groceries.listID
        _ = try engine.perform(StartShop(), by: .user)
        #expect(!read(grammar.parse("80 for 8", context: shopping)).hasPrefix("groceries"))
        #expect(read(grammar.parse("milk for groceries", context: shopping)) == "groceries milk")
        #expect(read(grammar.parse("oat milk", context: shopping)) == "groceries oat milk")
    }

    @Test func aBodyweightLiftWithOneNumberInFocusIsReps() throws {
        // Research on #282: "pull-ups 8" with Pull-Up in focus logs 8 reps at bodyweight, as "Eight." does.
        let workout = try store.create(#require(classes[.workout]), title: "Pull")
        let pullUp = try #require(store.classDef(id: SystemCatalog.stableID("library.pullUp")))
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: pullUp.id), by: .user).output
        var live = context
        live.entry = entry.id
        #expect(read(grammar.parse("pull ups 8", context: live)) == "set 0x8")
        // QA F1, F3 in focus: "bench 3x8" with 80 kg last gets the set-count ask.
        let bench = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: bench.id, weight: 80, reps: 8), by: .user)
        live.entry = bench.id
        #expect(read(grammar.parse("bench 3x8", context: live)) == "ask 3 × 8: 3 sets, or 3 kg?")
    }

    @Test func aLastWeightInFocusLetsTheSetCountAskDecide() throws {
        // QA F3: Leg Press at 100 kg in focus, "leg press 5x5" asks "5 sets, or 5 kg?".
        let workout = try store.create(#require(classes[.workout]), title: "Legs")
        let press = try #require(store.classDef(id: SystemCatalog.stableID("library.legPress")))
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: press.id), by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 100, reps: 10), by: .user)
        var live = context
        live.entry = entry.id
        #expect(read(grammar.parse("leg press 5x5", context: live)) == "ask 5 × 5: 5 sets, or 5 kg?")
        // QA F4: up to 10 in focus, under half the last weight, asks; it never logs 8 kg under the bar.
        let bench = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: bench.id, weight: 80, reps: 8), by: .user)
        live.entry = bench.id
        #expect(read(grammar.parse("bench 8x8", context: live)) == "ask 8 × 8: 8 sets, or 8 kg?")
        let pulldown = try #require(store.classDef(id: SystemCatalog.stableID("library.latPulldown")))
        let cable = try engine.perform(AddExercise(workout: workout.id, exercise: pulldown.id), by: .user).output
        try engine.perform(LogSet(entry: cable.id, weight: 55, reps: 10), by: .user)
        live.entry = cable.id
        #expect(read(grammar.parse("lat pulldown 10x10", context: live)) == "ask 10 × 10: 10 sets, or 10 kg?")
        // At or over half the last weight in focus: at what weight, never N kg.
        let legs = try engine.perform(AddExercise(workout: workout.id, exercise: press.id), by: .user).output
        try engine.perform(LogSet(entry: legs.id, weight: 100, reps: 10), by: .user)
        live.entry = legs.id
        #expect(read(grammar.parse("leg press 8x10", context: live)) == "ask 8 × 10: 8 sets, or 8 kg?")
        let curl = try #require(store.classDef(id: SystemCatalog.stableID("library.dbCurl")))
        let curls = try engine.perform(AddExercise(workout: workout.id, exercise: curl.id), by: .user).output
        try engine.perform(LogSet(entry: curls.id, weight: 12, reps: 10), by: .user)
        live.entry = curls.id
        #expect(read(grammar.parse("curls 8x10", context: live)) == "ask Dumbbell Curl 8 × 10 at what weight?")
    }

    @Test func anExerciseWithNoEquipmentNeverLogsNKilos() throws {
        // QA on #289: no equipment strides 2.5 from 0; the rule doesn't read loads, so it asks.
        let root = try #require(classes[.strengthExercise])
        let sled = ClassDef(name: "Sled Push", parent: root, symbolName: "figure", colorRole: "training", traits: [],
                            systemKey: nil)
        store.context.insert(sled)
        #expect(read(grammar.parse("sled push 3x8", context: context)) == "ask Sled Push 3 × 8 at what weight?")
    }
}
