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
        .init("K775", "82.5", .barbell, "nil"),
        .init("K776", "80 for 8", .barbell, "set 80x8"),
        .init("K777", "80x8", .barbell, "set 80x8"),
        .init("K778", "same", .barbell, "set 80x8"),
        .init("K779", "one more", .barbell, "set 80x8"),
        .init("K780", "8 reps", .barbell, "set 80x8"),
        .init("K781", "12", .dumbbell, "set 24x12"),
        .init("K782", "24", .dumbbell, "nil"),
        .init("K783", "81", .barbell, "nil"),
        .init("K784", "55", .machine, "nil"),
        .init("K785", "+5", .barbell, "nil"),
        .init("K786", "-5", .barbell, "nil"),
        .init("K787", "+2.5", .barbell, "nil"),
        .init("K788", "drop to 70 for 10", .barbell, "set 70x10 drop"),
        .init("K789", "drop to 72 for 10", .barbell, "set 72.5x10 drop"),
        .init("K790", "81 for 8", .barbell, "set 80x8"),
        .init("K791", "81.25 x 8", .barbell, "set 80x8"),
        .init("K792", "81.3 x 8", .barbell, "set 82.5x8"),
        .init("K793", "200 x 3", .barbell, "nil"),
        .init("K794", "25 x 10", .dumbbell, "set 24x10"),
        .init("K795", "57.5 x 10", .machine, "set 55x10"),
        .init("K797", "180 lb for 5", .barbell, "set 81.6x5"),
        .init("K798", "100 for 5 at 8", .barbell, "set 100x5 @8"),
        .init("K799", "same at 9", .barbell, "set 80x8 @9"),
        .init("K800", "8 at 9", .barbell, "set 80x8 @9"),
        .init("K801", "fail at 6", .barbell, "nil"),
        .init("K802", "80 x 6 to failure", .barbell, "set 80x6 failure"),
        .init("K803", "warmup 60x5", .barbell, "set 60x5 warmup"),
        .init("K804", "skip", .barbell, "nil"),
        .init("K805", "bodyweight 12", .barbell, "nil"),
        .init("K806", "bodyweight 12", .bodyweight, "set 0x12"),
        .init("K807", "+10 for 6", .bodyweight, "set 10x6"),
        .init("K808", "two plates", .barbell, "nil"),
        .init("K809", "bar for 10", .barbell, "set 20x10"),
        .init("K813", "same", .noSets, "nil"),
        .init("K814", "8", .noSets, "nil"),
        .init("B303", "80 x 8 @8", .barbell, "set 80x8 @8"),
        .init("B309", "8", .barbell, "set 80x8"),
        .init("A180", "100", .barbell, "nil"),
        .init("H625", "38", .barbell, "set 80x38"),
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
        guard case let .set(_, weight, reps, kind, how, _, rpe, _) = parse else { return "\(parse)" }
        var text = "set \(TessVoice.number(weight))x\(TessVoice.number(reps))"
        if how == .drop {
            text += " drop"
        } else if kind == .failure || kind == .warmup {
            text += " \(kind.rawValue)"
        }
        if let rpe {
            text += " @\(TessVoice.number(rpe))"
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
        #expect(parts.map(kind) == ["set 80x8", "set 80x6"])
    }

    @Test func tessSaysWhenItSnapped() async throws {
        let focus = try entry(.barbell)
        let capture = await TessCaptureEngine(engine: engine)
            .capture("81 for 8", context: TessContext(entry: focus.id, process: focus.parent?.id))
        #expect(capture.line.hasSuffix("81 isn't loadable."))
        #expect(capture.records.count == 1)
    }
}
