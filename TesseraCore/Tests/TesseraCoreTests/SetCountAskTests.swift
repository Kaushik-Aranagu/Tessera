import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/research/fixtures/set-logger.md, "Set counts" (SQ8, Product 7:53 PM PT Oct 15; edge cases 8:07 PM PT): a bare
/// "N x M" asks "N × M: N sets, or N kg?" when N is 6 or less and under half the last weight, and always on a
/// bodyweight lift. Nothing is written until he answers.
@MainActor
struct SetCountAskTests {
    enum Kit: String, Sendable {
        case db, db12, machine, machine0, cable, dip, kb, dbNone, bwNone, bw, bar
    }

    struct Row: Sendable, CustomTestStringConvertible {
        let id: String
        let phrase: String
        let kit: Kit
        let line: String
        /// After a SETS and a KG answer (nil: no ask).
        let sets: String?
        let kg: String?
        init(_ id: String, _ phrase: String, _ kit: Kit, _ line: String, sets: String? = nil, kg: String? = nil) {
            self.id = id
            self.phrase = phrase
            self.kit = kit
            self.line = line
            self.sets = sets
            self.kg = kg
        }

        var testDescription: String {
            "\(id) \(phrase)"
        }
    }

    nonisolated static let asks: [Row] = [
        .init("Q01", "2x10", .db, "2 × 10: 2 sets, or 2 kg?",
              sets: "Sets 2 and 3 logged. 24 × 10", kg: "Set 2 logged. 2 × 10"),
        .init("Q02", "4x8", .db, "4 × 8: 4 sets, or 4 kg?",
              sets: "Sets 2 to 5 logged. 24 × 8", kg: "Set 2 logged. 4 × 8"),
        .init("Q03", "6x8", .db, "6 × 8: 6 sets, or 6 kg?",
              sets: "Sets 2 to 7 logged. 24 × 8", kg: "Set 2 logged. 6 × 8"),
        .init("Q06", "5x10", .db12, "5 × 10: 5 sets, or 5 kg?",
              sets: "Sets 2 to 6 logged. 12 × 10", kg: "Set 2 logged. 4 × 10, nearest load to 5"),
        .init("Q07", "5x5", .cable, "5 × 5: 5 sets, or 5 kg?",
              sets: "Sets 2 to 6 logged. 55 × 5", kg: "Set 2 logged. 5 × 5"),
        .init("Q08", "6x10", .cable, "6 × 10: 6 sets, or 6 kg?",
              sets: "Sets 2 to 7 logged. 55 × 10", kg: "Set 2 logged. 5 × 10, nearest load to 6"),
        .init("Q09", "4x10", .machine, "4 × 10: 4 sets, or 4 kg?",
              sets: "Sets 2 to 5 logged. 40 × 10", kg: "Set 2 logged. 5 × 10, nearest load to 4"),
        .init("Q11", "2x10", .bar, "2 × 10: 2 sets, or 2 kg?",
              sets: "Sets 2 and 3 logged. 80 × 10", kg: "2 kg isn't loadable here"),
        .init("Q13", "5x5", .bw, "5 × 5: 5 sets, or +5 kg?",
              sets: "Sets 2 to 6 logged. bodyweight × 5", kg: "Set 2 logged. +5 × 5"),
        .init("Q14", "10x6", .bw, "10 × 6: 10 sets, or +10 kg?",
              sets: "Sets 2 to 11 logged. bodyweight × 6", kg: "Set 2 logged. +10 × 6"),
        .init("Q15", "3x8", .dip, "3 × 8: 3 sets, or +3 kg?",
              sets: "Sets 2 to 4 logged. +10 × 8", kg: "Set 2 logged. +2.5 × 8, nearest load to 3"),
        .init("Q16", "4x15", .kb, "4 × 15: 4 sets, or 4 kg?",
              sets: "Sets 2 to 5 logged. 16 × 15", kg: "Set 2 logged. 4 × 15"),
        .init("Q19", "5x5", .bwNone, "5 × 5: 5 sets, or +5 kg?",
              sets: "Sets 1 to 5 logged. bodyweight × 5", kg: "Set 1 logged. +5 × 5"),
        .init("Q20", "2×10", .db, "2 × 10: 2 sets, or 2 kg?",
              sets: "Sets 2 and 3 logged. 24 × 10", kg: "Set 2 logged. 2 × 10"),
        .init("Q21", "2 by 10", .db, "2 × 10: 2 sets, or 2 kg?",
              sets: "Sets 2 and 3 logged. 24 × 10", kg: "Set 2 logged. 2 × 10"),
    ]

    nonisolated static let logs: [Row] = [
        .init("Q04", "7x8", .db, "Set 2 logged. 6 × 8, nearest load to 7"),
        .init("Q05", "6x10", .db12, "Set 2 logged. 6 × 10"),
        .init("Q10", "4x10", .machine0, "Set 2 logged. 5 × 10, nearest load to 4"),
        .init("Q17", "8x15", .kb, "Set 2 logged. 8 × 15"),
        .init("Q18", "4x10", .dbNone, "Set 1 logged. 4 × 10"),
        .init("Q22", "2 for 10", .db, "Set 2 logged. 2 × 10"),
        .init("Q23", "4 kg x 10", .db, "Set 2 logged. 4 × 10"),
        .init("Q26", "5 kg x 5", .bw, "Set 2 logged. +5 × 5"),
        .init("Q27", "3 sets of 10", .db, "Sets 2 to 4 logged. 24 × 10"),
        .init("K888", "2 kilos x 10", .db, "Set 2 logged. 2 × 10"),
        .init("BY3", "26 by 8", .db, "Set 2 logged. 26 × 8"),
        .init("K889", "7x10", .db, "Set 2 logged. 6 × 10, nearest load to 7"),
    ]

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let tess: TessCaptureEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        tess = TessCaptureEngine(engine: engine)
    }

    /// A workout with the kit's exercise in focus and its one set logged (none for the "None" kits).
    func entry(_ kit: Kit) throws -> ObjectRecord {
        let workout = try store.create(#require(classes[.workout]), title: "Today")
        let (key, last): (String, (Double, Double)?) = switch kit {
        case .db: ("dbBenchPress", (24, 10))
        case .db12: ("dbBenchPress", (12, 10))
        case .machine: ("machineChestPress", (40, 10))
        case .machine0: ("machineChestPress", (0, 12))
        case .cable: ("latPulldown", (55, 10))
        case .dip: ("dip", (10, 8))
        case .kb: ("kbSwing", (16, 15))
        case .dbNone: ("dbBenchPress", nil)
        case .bwNone: ("pullUp", nil)
        case .bw: ("pullUp", (0, 8))
        case .bar: ("benchPress", (80, 8))
        }
        let exercise = try #require(key == "benchPress" ? classes[.benchPress]
            : store.classDef(id: SystemCatalog.stableID("library.\(key)")))
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: exercise.id), by: .user).output
        if let (weight, reps) = last {
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: reps), by: .user)
        }
        return entry
    }

    func context(_ entry: ObjectRecord) -> TessContext {
        TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar, entry: entry.id,
                    process: entry.parent?.id)
    }

    @Test(arguments: asks) func bareSetCountAsks(_ row: Row) async throws {
        for choice in [TessSetCountAsk.Choice.sets, .kilograms] {
            let fresh = try SetCountAskTests()
            let entry = try fresh.entry(row.kit)
            let before = entry.orderedChildren.count
            let asked = await fresh.tess.capture(row.phrase, context: fresh.context(entry))
            #expect(asked.line == row.line && asked.records.isEmpty)
            #expect(entry.orderedChildren.count == before) // the ask writes nothing
            #expect(TessVoice.violations(in: asked.line).isEmpty)
            let answered = fresh.tess.answer(choice, context: fresh.context(entry))
            #expect(answered.line == (choice == .sets ? row.sets : row.kg))
            #expect(fresh.tess.pendingAsk == nil)
        }
    }

    @Test(arguments: logs) func noAskLogs(_ row: Row) async throws {
        let entry = try entry(row.kit)
        let capture = await tess.capture(row.phrase, context: context(entry))
        #expect(capture.line == row.line && !capture.records.isEmpty)
        #expect(tess.pendingAsk == nil)
    }

    @Test func underTheBarNothingIsWritten() async throws {
        // Q12: 8 is over 6, so no ask; 8 kg is under the 20 kg bar, so no write.
        let entry = try entry(.bar)
        let capture = await tess.capture("8x3", context: context(entry))
        #expect(capture.records.isEmpty && entry.orderedChildren.count == 1)
    }

    @Test func aSaidAnswerResolvesTheAsk() async throws {
        let entry = try entry(.db)
        _ = await tess.capture("2x10", context: context(entry))
        let sets = await tess.capture("2 sets", context: context(entry))
        #expect(sets.records.count == 2 && sets.line == "Sets 2 and 3 logged. 24 × 10")
        _ = await tess.capture("4x8", context: context(entry))
        let kilos = await tess.capture("4 kilos", context: context(entry))
        #expect(kilos.records.count == 1 && kilos.line == "Set 4 logged. 4 × 8")
    }

    @Test func anotherPhraseDropsTheAsk() async throws {
        // Q28: "same" while the ask is up logs the same set; the ask is gone.
        let entry = try entry(.db)
        _ = await tess.capture("2x10", context: context(entry))
        #expect(tess.pendingAsk != nil)
        let same = await tess.capture("same", context: context(entry))
        #expect(same.line == "Set 2 logged, same again" && tess.pendingAsk == nil)
        #expect(tess.answer(.sets, context: context(entry)).records.isEmpty)
    }

    @Test func theAskIsNotAMiss() async throws {
        let entry = try entry(.db)
        let asked = await tess.capture("2x10", context: context(entry))
        #expect(asked.asking == .setCount(TessSetCountAsk(entry: entry.id, count: 2, reps: 10, bodyweight: false)))
    }

    @Test func undoTakesBackEverySetItNamed() async throws {
        let entry = try entry(.db)
        _ = await tess.capture("3x8", context: context(entry))
        let answered = tess.answer(.sets, context: context(entry))
        #expect(answered.records.count == 3 && entry.orderedChildren.count == 4)
        for record in answered.records.reversed() {
            try engine.discard(record)
        }
        #expect(entry.orderedChildren.count == 1)
    }

    @Test func anRPEOrKindStillAsksAndIsKept() async throws {
        // QA Q9: "2x10 @8" and "warmup 2x10" ask like "2x10"; the answer keeps the RPE and the kind.
        let entry = try entry(.db)
        let asked = await tess.capture("2x10 @8", context: context(entry))
        #expect(asked.line == "2 × 10: 2 sets, or 2 kg?")
        #expect(tess.answer(.kilograms, context: context(entry)).line == "Set 2 logged. 2 × 10, RPE 8")
        let warm = try SetCountAskTests()
        let warmEntry = try warm.entry(.db)
        _ = await warm.tess.capture("warmup 2x10", context: warm.context(warmEntry))
        let warmups = warm.tess.answer(.sets, context: warm.context(warmEntry))
        #expect(warmups.records.count == 2)
        #expect(warmEntry.orderedChildren.suffix(2).allSatisfy {
            warm.store.value("kind", of: $0) == .choice("warmup")
        })
        let bar = try SetCountAskTests()
        let barEntry = try bar.entry(.bar)
        let barAsk = await bar.tess.capture("3x10 @8", context: bar.context(barEntry))
        #expect(barAsk.line == "3 × 10: 3 sets, or 3 kg?" && barAsk.records.isEmpty)
    }

    // MARK: Sets with errands, commas (A169, A170, K874, QA Q7a)

    @Test func aSetAndAnErrandBothLog() async throws {
        let entry = try entry(.bar)
        let both = await tess.capture("8 and call mum at 7", context: context(entry))
        #expect(both.records.count == 2)
        #expect(both.line == "Set 2 logged. 80 × 8. Call mum, today 7 pm")
        let comma = await tess.capture("same, call mum thu", context: context(entry))
        #expect(comma.records.count == 2 && comma.line.hasPrefix("Set 3 logged, same again. Call mum"))
    }

    @Test func aBareNumberAfterASetAsksForReps() async throws {
        let entry = try entry(.bar)
        let capture = await tess.capture("bench 80 for 8, 81", context: context(entry))
        #expect(capture.records.count == 1)
        #expect(capture.line == "Set 2 logged. 80 × 8. 81 for how many reps?")
    }

    @Test func aWholeLiftThenANumberIsTwoSets() async throws {
        // QA Q7a: "bench 80x8, 6" is a set and 6 reps at 80, never "bench 80 x 8 x 6".
        let entry = try entry(.bar)
        let capture = await tess.capture("bench 80x8, 6", context: context(entry))
        #expect(capture.records.count == 2 && capture.line == "Sets 2 and 3 logged")
    }
}
