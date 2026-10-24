import Foundation
@testable import TesseraTess
import Testing

/// Memory spec M6: questions written from the store, scored exactly, misses kept until they pass a week running.
struct MemoryEvalTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }

    func day(_ month: Int, _ day: Int, hour: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)) ?? .distantPast
    }

    var eval: MemoryEval {
        MemoryEval(calendar: calendar, now: day(10, 23))
    }

    var facts: MemoryEvalFacts {
        MemoryEvalFacts(
            sets: [.init(exercise: "Bench Press", day: day(10, 3), weight: 92.5, unit: "kg", reps: 5),
                   .init(exercise: "Bench Press", day: day(10, 3), weight: 90, unit: "kg", reps: 5),
                   .init(exercise: "Squat", day: day(10, 6), weight: 120, unit: "kg", reps: 3)],
            events: [.init(name: "Chili", verb: "cook", day: day(9, 28)),
                     .init(name: "Chili", verb: "cook", day: day(10, 2)),
                     .init(name: "Chili", verb: "cook", day: day(10, 16)),
                     .init(name: "Push Day", verb: "do", day: day(10, 1))],
            changes: [.init(question: "When do I usually train?", old: "6 am", current: "evening")],
            unknowns: ["What's my favorite cuisine?"]
        )
    }

    // MARK: Questions

    @Test func everyKindIsAskedWithItsAnswer() {
        let questions = eval.questions(from: facts, night: "2026-10-23")
        #expect(Set(questions.map(\.kind)) == Set(EvalKind.allCases))
        let bench = questions.first { $0.id.hasPrefix("find/Bench Press") }
        #expect(bench?.text == "What weight did I do for 5 on Bench Press on Oct 3?")
        // Two bench sets of 5 that day: the question asks for the heavier, so the answer is one number.
        #expect(bench?.expected == .number(92.5, unit: "kg"))
        let chili = questions.first { $0.id.hasPrefix("count/cook|Chili") }
        #expect(chili?.text == "How many times did I cook Chili in October?")
        #expect(chili?.expected == .number(2, unit: nil))
        let start = questions.first { $0.id == "when/cook|Chili" }
        #expect(start?.expected == .day(day(9, 28)))
    }

    @Test func theSameNightGivesTheSameQuestions() {
        let one = eval.questions(from: facts, night: "2026-10-23", count: 4)
        let two = eval.questions(from: facts, night: "2026-10-23", count: 4)
        #expect(one == two && one.count == 4)
        #expect(Set(one.map(\.kind)).count == 4)
    }

    @Test func keptMissesComeFirst() {
        let kept = EvalQuestion(id: "unknown/Do I like jazz?", kind: .dontKnow, text: "Do I like jazz?",
                                expected: .dontKnow)
        let questions = eval.questions(from: facts, night: "2026-10-23", count: 3, keep: [kept])
        #expect(questions.first == kept && questions.count == 3)
    }

    // MARK: Scoring

    @Test func numbersScoreInEitherUnit() {
        let question = EvalQuestion(id: "find/x", kind: .find, text: "", expected: .number(92.5, unit: "kg"))
        #expect(eval.isRight("92.5 kg for 5 on Oct 3.", for: question))
        #expect(eval.isRight("About 204 lb.", for: question))
        #expect(!eval.isRight("90 kg for 5.", for: question))
        #expect(!eval.isRight("I don't know, maybe 92.5 kg.", for: question))
    }

    @Test func daysScoreInTheUsualForms() {
        let question = EvalQuestion(id: "when/x", kind: .when, text: "", expected: .day(day(9, 28)))
        #expect(eval.isRight("You first cooked it on Sep 28.", for: question))
        #expect(eval.isRight("On 28 September.", for: question))
        #expect(!eval.isRight("On Oct 2.", for: question))
        let second = EvalQuestion(id: "when/y", kind: .when, text: "", expected: .day(day(9, 2)))
        #expect(!eval.isRight("On Sep 28.", for: second) && eval.isRight("On Sep 2.", for: second))
    }

    @Test func aChangeNeedsTheCurrentBeliefNotTheOldOne() {
        let question = EvalQuestion(id: "changed/x", kind: .changed, text: "", expected: .text("evening"))
        #expect(eval.isRight("These days you train in the evening.", for: question, old: "6 am"))
        #expect(!eval.isRight("You train at 6 am, or sometimes in the evening.", for: question, old: "6 am"))
    }

    @Test func dontKnowIsTheOnlyRightAnswerWhenNothingIsKept() {
        let question = EvalQuestion(id: "unknown/x", kind: .dontKnow, text: "", expected: .dontKnow)
        #expect(eval.isRight("I don't know yet.", for: question))
        #expect(!eval.isRight("Probably Thai food.", for: question))
    }

    // MARK: The record

    func night(_ name: String, missed: [EvalQuestion], asked: [EvalQuestion]) -> EvalNight {
        var night = EvalNight(night: name, model: "haiku")
        for question in asked {
            night.record(question, right: !missed.contains(question))
        }
        return night
    }

    @Test func aMissIsKeptUntilSevenRightNightsRunning() {
        let question = EvalQuestion(id: "find/Squat", kind: .find, text: "", expected: .number(120, unit: "kg"))
        var record = MemoryEvalRecord()
        record.add([night("n0", missed: [question], asked: [question])], questions: [question])
        #expect(record.kept == [question])
        for index in 1 ... 6 {
            record.add([night("n\(index)", missed: [], asked: [question])], questions: [question])
        }
        #expect(record.kept == [question] && record.streaks[question.id] == 6)
        record.add([night("n7", missed: [], asked: [question])], questions: [question])
        #expect(record.kept.isEmpty)
    }

    @Test func scoresAreKeptPerKindAndModel() {
        let find = EvalQuestion(id: "find/a", kind: .find, text: "", expected: .number(1, unit: nil))
        let unknown = EvalQuestion(id: "unknown/b", kind: .dontKnow, text: "", expected: .dontKnow)
        var record = MemoryEvalRecord()
        record.add([night("n0", missed: [find], asked: [find, unknown])], questions: [find, unknown])
        #expect(record.kindScores(model: "haiku") == [.find: 0, .dontKnow: 100])
        #expect(record.nights.last?.score == 50)
        #expect(record.tunerMisses(agent: "tess", model: .haiku) == [EvalMiss(agent: "tess", model: .haiku,
                                                                              section: .recall)])
    }

    @Test func theRecordRoundTrips() {
        let url = FileManager.default.temporaryDirectory.appending(path: "eval-\(UUID().uuidString).json")
        let question = EvalQuestion(id: "when/x", kind: .when, text: "When?", expected: .day(day(9, 28)))
        var record = MemoryEvalRecord()
        record.add([night("n0", missed: [question], asked: [question])], questions: [question])
        record.save(to: url)
        #expect(MemoryEvalRecord.load(from: url) == record)
        try? FileManager.default.removeItem(at: url)
    }
}
