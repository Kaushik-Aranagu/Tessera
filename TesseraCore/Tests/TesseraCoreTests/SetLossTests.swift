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
        ("KEEP3", "bench 80x8 heavy", "nil"),
    ])
    func idle(_ id: String, _ phrase: String, _ expected: String) {
        #expect(read(grammar.parse(phrase, context: context)) == expected, "\(id)")
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
        // QA R2 on #262: number words and an errand together.
        #expect(read(grammar.parse("bench eighty for eight, call mum at seven", context: live))
            == "set 80x8 + task Call mum @")
    }
}
