import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/research/fixtures/set-logger.md (group K), S701 to S706: what a typed set does in a live workout. Starter
/// kit: a 20 kg bar with plates (20 to 177.5 in 2.5 kg steps), dumbbells 2 to 50 in 2 kg steps, cables in 5 kg.
@MainActor
struct SetLoggerTests {
    enum Kit: Sendable { case barbell, dumbbell, machine, bodyweight, noSets }

    struct Row: Sendable, CustomTestStringConvertible {
        let id: String
        let phrase: String
        let kit: Kit
        let expect: String
        init(_ id: String, _ phrase: String, _ kit: Kit, _ expect: String) {
            self.id = id
            self.phrase = phrase
            self.kit = kit
            self.expect = expect
        }

        var testDescription: String {
            "\(id) \(phrase)"
        }
    }

    nonisolated static let rows: [Row] = [
        .init("K775", "82.5", .barbell, "ask 82.5 for how many reps?"),
        .init("K776", "80 for 8", .barbell, "set 80x8"),
        .init("K777", "80x8", .barbell, "set 80x8"),
        .init("K778", "same", .barbell, "set 80x8 same"),
        .init("K779", "one more", .barbell, "set 80x8 same"),
        .init("K780", "8 reps", .barbell, "set 80x8 reps"),
        .init("K781", "12", .dumbbell, "set 24x12 reps"),
        .init("K782", "24", .dumbbell, "ask 24: 24 kg, or 24 reps?"),
        .init("K783", "81", .barbell, "ask 81 for how many reps?"),
        .init("K784", "55", .machine, "ask 55 for how many reps?"),
        .init("K785", "+5", .barbell, "ask +5 kg: on the next set?"),
        .init("K786", "-5", .barbell, "ask -5 kg: on the next set?"),
        .init("K787", "+2.5", .barbell, "ask +2.5 kg: on the next set?"),
        .init("K788", "drop to 70 for 10", .barbell, "set 70x10 drop"),
        .init("K789", "drop to 72 for 10", .barbell, "set 72.5x10 drop (said 72)"),
        .init("K790", "81 for 8", .barbell, "set 80x8 (said 81)"),
        .init("K791", "81.25 x 8", .barbell, "set 80x8 (said 81.25)"),
        .init("K792", "81.3 x 8", .barbell, "set 82.5x8 (said 81.3)"),
        .init("K793", "200 x 3", .barbell, "nil"),
        .init("K794", "25 x 10", .dumbbell, "set 24x10 (said 25)"),
        .init("K795", "57.5 x 10", .machine, "set 55x10 (said 57.5)"),
        .init("K797", "180 lb for 5", .barbell, "set 81.6x5 lb"),
        .init("K798", "100 for 5 at 8", .barbell, "set 100x5 @8"),
        .init("K799", "same at 9", .barbell, "set 80x8 same @9"),
        .init("K800", "8 at 9", .barbell, "set 80x8 reps @9"),
        .init("K801", "fail at 6", .barbell, "ask Fail at 6: rep 6, or 6 reps?"),
        .init("K802", "80 x 6 to failure", .barbell, "set 80x6 failure"),
        .init("K803", "warmup 60x5", .barbell, "set 60x5 warmup"),
        .init("K804", "skip", .barbell, "ask Skip set 2?"),
        .init("K805", "bodyweight 12", .barbell, "nil"),
        .init("K806", "bodyweight 12", .bodyweight, "set 0x12"),
        .init("K807", "+10 for 6", .bodyweight, "set 10x6"),
        .init("K808", "two plates", .barbell, "nil"),
        .init("K809", "bar for 10", .barbell, "set 20x10"),
        .init("K813", "same", .noSets, "nil"),
        .init("K814", "8", .noSets, "ask 8: kg, or reps?"),
        .init("B303", "80 x 8 @8", .barbell, "set 80x8 @8"),
        .init("B309", "8", .barbell, "set 80x8 reps"),
        .init("A180", "100", .barbell, "ask 100 for how many reps?"),
        .init("H625", "38", .barbell, "set 80x38 reps"),
        // QA on #205: dictation (Q1), commas (Q2), non-RPE "at" (Q3), bodyweight reps (Q4), kind with RPE (Q5),
        // below the bar (Q6).
        .init("Q1a", "Same at 9.", .barbell, "set 80x8 same @9"),
        .init("Q1b", "8 at 9.", .barbell, "set 80x8 reps @9"),
        .init("Q1c", "Fail at 6.", .barbell, "ask Fail at 6: rep 6, or 6 reps?"),
        .init("Q1d", "-5.", .barbell, "ask -5 kg: on the next set?"),
        .init("Q1e", "+5.", .barbell, "ask +5 kg: on the next set?"),
        .init("Q2a", "100 for 5, at 8", .barbell, "set 100x5 @8"),
        .init("Q2b", "8, 81", .barbell, "set 80x8 reps + ask 81 for how many reps?"),
        .init("Q3a", "same at 11", .barbell, "nil"),
        .init("Q3b", "8 at 4", .barbell, "nil"),
        .init("Q4", "2", .bodyweight, "set 0x2 reps"),
        .init("Q5", "80 x 6 to failure at 9", .barbell, "set 80x6 failure @9"),
        .init("Q6", "0 x 8", .barbell, "nil"),
        .init("Q5b", "warmup 60x5 at 8", .barbell, "set 60x5 warmup @8"),
        // Research's rerun: "3x10" on dumbbells is 3 sets of 10 (ask); "24 reps" says reps even at the last weight.
        .init("R2", "3x10", .dumbbell, "ask 3 × 10: 3 sets, or 3 kg?"),
        .init("R3", "24 reps", .dumbbell, "set 24x24 reps"),
    ]

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let grammar: TessGrammar

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        grammar = TessGrammar(store: store, classes: classes)
    }

    /// A workout with the kit's exercise in focus and its last set logged (none for `.noSets`).
    func entry(_ kit: Kit) throws -> ObjectRecord {
        let workout = try store.create(#require(classes[.workout]), title: "Today")
        let (key, last): (String, (Double, Double)?) = switch kit {
        case .barbell: ("benchPress", (80, 8))
        case .dumbbell: ("library.dbBenchPress", (24, 10))
        case .machine: ("library.latPulldown", (55, 10))
        case .bodyweight: ("library.pullUp", (0, 8))
        case .noSets: ("benchPress", nil)
        }
        let exercise = try #require(key == "benchPress" ? classes[.benchPress]
            : store.classDef(id: SystemCatalog.stableID(key)))
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: exercise.id), by: .user).output
        if let (weight, reps) = last {
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: reps), by: .user)
        }
        return entry
    }

    func kind(_ parse: TessGrammar.Parse?) -> String {
        guard let parse else { return "nil" }
        switch parse {
        case let .ask(line): return "ask \(line)"
        case let .askSetCount(ask): return "ask \(ask.line)"
        case let .sets(parts): return parts.map(kind).joined(separator: " + ")
        default: break
        }
        guard case let .set(_, weight, reps, kind, how, unit, rpe, said) = parse else { return "\(parse)" }
        var text = "set \(TessVoice.number(weight))x\(TessVoice.number(reps))"
        switch how {
        case .same: text += " same"
        case .repsOnly: text += " reps"
        case .drop: text += " drop"
        case .full: break
        }
        if kind == .failure || kind == .warmup {
            text += " \(kind.rawValue)"
        }
        if unit != .kilograms {
            text += " \(unit.symbol)"
        }
        if let rpe {
            text += " @\(TessVoice.number(rpe))"
        }
        if let said {
            text += " (said \(String(format: "%g", said)))"
        }
        return text
    }

    @Test(arguments: rows) func liveSets(_ row: Row) throws {
        let focus = try entry(row.kit)
        let context = TessContext(entry: focus.id, process: focus.parent?.id)
        #expect(kind(grammar.parse(row.phrase, context: context)) == row.expect)
    }

    @Test func aCommaListSnapsEveryPart() throws {
        let focus = try entry(.barbell)
        let parse = grammar.parse("80 x 8, 81 x 6", context: TessContext(entry: focus.id, process: focus.parent?.id))
        guard case let .sets(parts)? = parse else {
            Issue.record("80 x 8, 81 x 6")
            return
        }
        #expect(parts.map(kind) == ["set 80x8", "set 80x6 (said 81)"])
    }

    @Test func tessSaysWhenItSnapped() async throws {
        let focus = try entry(.barbell)
        let capture = await TessCaptureEngine(engine: engine)
            .capture("81 for 8", context: TessContext(entry: focus.id, process: focus.parent?.id))
        #expect(capture.line == "Set 2 logged. 80 × 8, nearest load to 81.")
        #expect(capture.records.count == 1)
    }
}
