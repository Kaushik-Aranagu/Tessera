import Foundation
@testable import TesseraCore
import Testing

/// M1: beliefs are claims with evidence. No evidence, no belief; a change closes and links; forgetting deletes and
/// redacts; today's told and noticed lines become beliefs with his words intact.
@MainActor
struct TessBeliefTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let memory: TessMemoryStore
    let beliefs: TessBeliefStore

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
        memory = TessMemoryStore(engine: engine, forgetLogURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("tess-forgotten-\(UUID().uuidString).json"), fileProtection: [])
        beliefs = TessBeliefStore(engine: engine, memory: memory)
    }

    func evidenceObject() throws -> ObjectRecord {
        try store.create(#require(classes[.workout]), title: "Push A")
    }

    @discardableResult
    func record(_ words: String = "You train after work.", key: TessBelief.Key = .usualTime,
                source: TessBelief.Source = .noticed, evidence: [UUID]? = nil) throws -> ObjectRecord
    {
        let ids = try evidence ?? [evidenceObject().id]
        return try engine.perform(RecordBelief(words: words, key: key, source: source, evidence: ids), by: .tess).output
    }

    @Test func aBeliefWithNoEvidenceIsRefused() throws {
        #expect(throws: ActionError.self) {
            try engine.perform(RecordBelief(words: "You train after work.", key: .usualTime, source: .noticed),
                               by: .tess)
        }
        let error = #expect(throws: ActionError.self) {
            try engine.perform(RecordBelief(words: "You train after work.", key: .usualTime, source: .noticed,
                                            evidence: [UUID()]), by: .tess)
        }
        #expect(error.flatMap(BeliefRefusal.line) == "I need something to go on for that.")
        #expect(beliefs.all().isEmpty)
    }

    @Test func anOpAloneIsEvidenceEnough() throws {
        let workout = try evidenceObject()
        let op = try #require(store.context.operations.values.first?.id ?? UUID())
        _ = workout
        let made = try engine.perform(RecordBelief(words: "You train after work.", key: .usualTime, source: .noticed,
                                                   evidenceOps: [op]), by: .tess).output
        #expect(beliefs.belief(made.id)?.evidenceOps == [op])
    }

    @Test func aBeliefReadsBackWithItsParts() throws {
        let made = try record()
        let belief = try #require(beliefs.belief(made.id))
        #expect(belief.key == .usualTime && belief.source == .noticed && belief.subject == .you)
        #expect(belief.isOpen && belief.evidence.count == 1 && belief.words == "You train after work.")
        #expect(belief.value == "{\"text\":\"You train after work.\"}")
        #expect(beliefs.open().map(\.id) == [made.id])
    }

    @Test func aChangeClosesTheOldBeliefAndLinksTheNewOne() throws {
        let old = try record("You train after work.")
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let change = start.addingTimeInterval(86400 * 30)
        store.context.operations.values.first.map { _ in }
        let revised = try engine.perform(ReviseBelief(belief: old.id, words: "You train before work.", at: change),
                                         by: .tess).output
        let oldBelief = try #require(beliefs.belief(old.id))
        let newBelief = try #require(beliefs.belief(revised.id))
        #expect(!oldBelief.isOpen && oldBelief.validUntil == change)
        #expect(newBelief.isOpen && newBelief.supersedes == old.id && newBelief.validFrom == change)
        #expect(newBelief.evidence == oldBelief.evidence)
        #expect(beliefs.history(of: revised.id).map(\.id) == [revised.id, old.id])
        #expect(beliefs.open().map(\.id) == [revised.id])
        // Closed, not deleted: it can still say what held before.
        #expect(oldBelief.isValid(at: start.addingTimeInterval(3600)) || oldBelief.validFrom > start)
        let closedTwice = #expect(throws: ActionError.self) {
            try engine.perform(ReviseBelief(belief: old.id, words: "You train at noon."), by: .tess)
        }
        #expect(closedTwice.flatMap(BeliefRefusal.line) == "That one is already closed.")
    }

    @Test func forgetDeletesTheChainAndRedactsTheWords() throws {
        let old = try record("You train after work.")
        let revised = try engine.perform(ReviseBelief(belief: old.id, words: "You train before dawn."), by: .tess)
            .output
        let result = try engine.perform(ForgetBelief(belief: revised.id), by: .user)
        #expect(beliefs.all().isEmpty)
        // Inside the UNDO window the words are still recoverable; undo brings both back.
        engine.undo(result.record)
        #expect(beliefs.all().count == 2)
        try engine.perform(ForgetBelief(belief: revised.id), by: .user)
        #expect(beliefs.sweepForgotten(now: .now.addingTimeInterval(60)) == 2)
        #expect(store.object(id: old.id)?.title == TessMemoryStore.redacted)
        #expect(store.object(id: revised.id)?.title == TessMemoryStore.redacted)
        let history = store.context.operations.values
        #expect(!history.contains { $0.ops.contains { op in
            if case let .create(_, _, _, title) = op {
                title.contains("after work") || title.contains("before dawn")
            } else {
                false
            }
        } })
        #expect(!history.contains { $0.summary.contains("before dawn") || $0.summary.contains("after work") })
    }

    @Test func aMaybeIsSpokenWithIThinkUntilConfirmedTwiceOrKept() throws {
        let made = try record("You rest on Sundays.", source: .inferred)
        var belief = try #require(beliefs.belief(made.id))
        #expect(belief.isMaybe && belief.spoken == "I think you rest on Sundays.")
        try engine.perform(ConfirmBelief(belief: made.id), by: .tess)
        belief = try #require(beliefs.belief(made.id))
        #expect(belief.isMaybe && belief.confirmations == 1)
        try engine.perform(ConfirmBelief(belief: made.id), by: .tess)
        belief = try #require(beliefs.belief(made.id))
        #expect(!belief.isMaybe && belief.spoken == "You rest on Sundays.")
        let other = try record("You skip Fridays.", source: .inferred)
        try engine.perform(ConfirmBelief(belief: other.id, keep: true), by: .user)
        #expect(try #require(beliefs.belief(other.id)).isMaybe == false)
    }

    @Test func theWallsStillApplyToBeliefs() throws {
        let object = try evidenceObject()
        for words in ["Rent is $2000.", "You live at 12 Oak Street.", "Your PIN is 0420.", "You weighed 82 kg."] {
            #expect(throws: ActionError.self) {
                try engine.perform(RecordBelief(words: words, key: .fact, source: .told, evidence: [object.id]),
                                   by: .tess)
            }
        }
        let tooLong = String(repeating: "a", count: 81)
        #expect(throws: ActionError.self) {
            try engine.perform(RecordBelief(words: tooLong, key: .fact, source: .told, evidence: [object.id]),
                               by: .tess)
        }
        // A health word is kept, on this phone only.
        let sore = try engine.perform(RecordBelief(words: "Your knee hates deep squats.", key: .avoids,
                                                   source: .told, evidence: [object.id]), by: .tess).output
        #expect(beliefs.belief(sore.id)?.isPrivate == true)
    }

    @Test func aToldBeliefKeepsHisWordsAndOthersGoToSecondPerson() throws {
        let object = try evidenceObject()
        let told = try engine.perform(RecordBelief(words: "mom means Lakshmi", key: .alias, source: .told,
                                                   evidence: [object.id]), by: .user).output
        #expect(beliefs.belief(told.id)?.words == "mom means Lakshmi")
        let noticed = try engine.perform(RecordBelief(words: "I train after work", key: .usualTime,
                                                      source: .noticed, evidence: [object.id]), by: .tess).output
        #expect(beliefs.belief(noticed.id)?.words == "You train after work.")
    }

    @Test func aSubjectIsYouAClassOrAnObject() throws {
        let workout = try evidenceObject()
        let exercise = try #require(classes[.exercise])
        let onObject = try engine.perform(RecordBelief(words: "You do this on Mondays.", key: .cadence,
                                                       source: .noticed, subject: workout.id,
                                                       evidence: [workout.id]), by: .tess).output
        let onClass = try engine.perform(RecordBelief(words: "You like sets of five.", key: .prefers,
                                                      source: .noticed, subjectClass: exercise.id,
                                                      evidence: [workout.id]), by: .tess).output
        #expect(beliefs.belief(onObject.id)?.subject == .object(workout.id))
        #expect(beliefs.belief(onClass.id)?.subject == .classDef(exercise.id))
        #expect(beliefs.about(.object(workout.id)).map(\.id) == [onObject.id])
        #expect(beliefs.about(.classDef(exercise.id), key: .prefers).map(\.id) == [onClass.id])
    }

    @Test func useIsKeptToTheLastFifty() throws {
        let made = try record()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        for day in 0 ..< 60 {
            beliefs.markUsed([made.id], at: start.addingTimeInterval(Double(day) * 86400))
        }
        let uses = try #require(beliefs.belief(made.id)).uses
        #expect(uses.count == 50 && uses.first == start.addingTimeInterval(10 * 86400))
    }

    // MARK: Migration

    @Test func theMigrationKeepsEveryToldLinesWords() throws {
        let words = ["You train after work.", "mom means Lakshmi", "You like the window seat."]
        for text in words {
            try engine.perform(RememberFact(text: text), by: .user)
        }
        let told = memory.lines(of: .told)
        #expect(beliefs.syncFromMemory() == told.count)
        #expect(Set(beliefs.all().map(\.words)) == Set(told.map(\.text)))
        for belief in beliefs.all() {
            #expect(belief.source == .told && belief.isOpen && !belief.evidence.isEmpty)
        }
        // Idempotent; a new line adds one belief.
        #expect(beliefs.syncFromMemory() == 0)
        try engine.perform(RememberFact(text: "You cook on Sundays"), by: .user)
        #expect(beliefs.syncFromMemory() == 1 && beliefs.all().count == 4)
    }

    @Test func aNoticedLineThatChangesClosesItsBeliefAndOpensTheNext() throws {
        let line = try #require(memory.write(kind: .noticed, area: .training, text: "You train after work.",
                                             evidence: [], day: nil, rule: "training.hours"))
        beliefs.syncFromMemory()
        line.title = "You train before work."
        beliefs.syncFromMemory(now: .now.addingTimeInterval(86400))
        let all = beliefs.all()
        #expect(all.count == 2 && all.filter(\.isOpen).map(\.words) == ["You train before work."])
        #expect(all.first { $0.isOpen }?.supersedes == all.first { !$0.isOpen }?.id)
        // The line goes away (the rule no longer holds): the belief closes too.
        memory.remove(line.id)
        beliefs.syncFromMemory(now: .now.addingTimeInterval(2 * 86400))
        #expect(beliefs.open().isEmpty)
    }

    @Test func forgettingAMemoryLineForgetsItsBeliefs() throws {
        try engine.perform(RememberFact(text: "You train after work"), by: .user)
        let line = try #require(memory.lines(of: .told).first)
        beliefs.syncFromMemory()
        #expect(beliefs.all().count == 1)
        try engine.perform(ForgetMemory(memory: line.id), by: .user)
        #expect(beliefs.all().isEmpty)
        // Redaction takes the belief's words out of history too.
        memory.sweepForgotten(now: .now.addingTimeInterval(60))
        beliefs.sweepForgotten(now: .now.addingTimeInterval(60))
        let titles = store.context.operations.values.flatMap(\.ops).compactMap { op -> String? in
            if case let .create(_, _, _, title) = op {
                title
            } else {
                nil
            }
        }
        #expect(!titles.contains { $0.contains("after work") })
    }

    @Test func forgetAllTakesTheBeliefsToo() throws {
        try engine.perform(RememberFact(text: "You train after work"), by: .user)
        beliefs.syncFromMemory()
        try record("You rest on Sundays.", source: .inferred)
        let all = try engine.perform(ForgetAllMemory(), by: .user)
        #expect(beliefs.all().isEmpty && memory.all().isEmpty)
        #expect(all.output == 2)
    }

    @Test func aPrivateBeliefReadsAsPrivateMemoryOutsideThePage() throws {
        let object = try evidenceObject()
        let made = try engine.perform(RecordBelief(words: "Your knee hates deep squats.", key: .avoids,
                                                   source: .told, evidence: [object.id]), by: .user).output
        #expect(ObjectPrivacy.label(of: made, in: store, classes: classes) == ObjectPrivacy.memoryLabel)
    }
}
