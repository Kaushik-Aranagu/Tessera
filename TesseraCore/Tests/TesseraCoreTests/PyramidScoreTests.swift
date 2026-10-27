import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The P1b score's own parts, with no call: questions with exact answers at three depths, exact scoring, and
/// contexts that keep the walls.
@MainActor
struct PyramidScoreTests {
    let world = EvalWorld.make()

    var pyramid: MemoryPyramid {
        MemoryPyramid(leaves: world.pyramidLeaves(), calendar: EvalWorld.calendar)
    }

    @Test func everyQuestionHasOneExactAnswerOnAReadableNode() throws {
        let pyramid = pyramid
        let questions = PyramidScore.questions(world)
        let depths = Set(questions.map { $0.depth }), ids = Set(questions.map { $0.id })
        #expect(depths == [.detail, .trend, .pattern])
        #expect(ids.count == questions.count)
        #expect(questions.count >= 20, "\(questions.count)")
        for question in questions {
            let node = try #require(pyramid.nodes[question.path], "\(question.id)")
            #expect(!pyramid.zoom(question.path, policy: .strict).isError, "\(question.id)")
            // A month's workout count is the pyramid's own exact total.
            if question.id.hasSuffix("-workouts"), case let .number(value) = question.expected {
                #expect(node.stats["workouts"] == value, "\(question.id)")
            }
        }
    }

    @Test func scoringIsExact() throws {
        func question(_ expected: PyramidQuestion.Expected) -> PyramidQuestion {
            PyramidQuestion(id: "q", depth: .trend, path: "/time", ask: "?", expected: expected)
        }
        let oct2 = EvalWorld.at(2026, 10, 2, 18)
        #expect(PyramidScore.score(question(.day(oct2)), answer: "Oct 2"))
        #expect(PyramidScore.score(question(.day(oct2)), answer: "It was October 2, a Friday."))
        #expect(!PyramidScore.score(question(.day(oct2)), answer: "Oct 23"))
        #expect(PyramidScore.score(question(.number(14)), answer: "14 workouts"))
        #expect(!PyramidScore.score(question(.number(14)), answer: "140"))
        #expect(PyramidScore.score(question(.text("Push A")), answer: "push a, mostly"))
        #expect(PyramidScore.score(question(.month("March")), answer: "March"))
        #expect(!PyramidScore.score(question(.month("March")), answer: "unknown"))
    }

    @Test func strictContextsHoldNoWalledLine() {
        let pyramid = pyramid
        let walled = world.pyramidLeaves().filter { $0.taint == .deviceOnly }.map(\.text)
        for question in PyramidScore.questions(world) {
            for arm in PyramidScore.Arm.allCases {
                let fragments = PyramidScore.context(question, arm: arm, pyramid: pyramid, gists: PyramidGists(),
                                                     policy: .strict)
                #expect(!fragments.isEmpty && fragments.allSatisfy { $0.taint == .claudeSafe }, "\(question.id)")
                let text = fragments.map(\.text).joined(separator: "\n")
                #expect(!walled.contains { text.contains($0) }, "\(question.id) \(arm)")
                #expect(!text.contains("dollars spent") && !text.contains("hours of sleep"), "\(question.id) \(arm)")
            }
        }
    }

    @Test func aZoomIsCheaperThanTheLeavesAboveADay() {
        let pyramid = pyramid
        for question in PyramidScore.questions(world) where question.depth != .detail {
            let flat = PyramidScore.context(question, arm: .flat, pyramid: pyramid, gists: PyramidGists(),
                                            policy: .strict).map(\.text).joined(separator: "\n")
            let zoom = PyramidScore.context(question, arm: .zoom, pyramid: pyramid, gists: PyramidGists(),
                                            policy: .strict).map(\.text).joined(separator: "\n")
            #expect(zoom.count < flat.count, "\(question.id): zoom \(zoom.count), flat \(flat.count)")
        }
    }

    @Test func anAnswerReadsFromItsTool() async throws {
        let question = try #require(PyramidScore.questions(world).first)
        let input = Data(#"{"answer":"14"}"#.utf8)
        let brain = ScriptedBrain(.haiku, rounds: [[.toolUse(id: "t1", name: PyramidScore.toolName, input: input)]])
        let rig = try DoorRig(brains: [.haiku: brain], policy: .strict)
        let job = PyramidScore.job(question, arm: .zoom, pyramid: pyramid, gists: PyramidGists(), policy: .strict)
        #expect(job.estimateNano > 0)
        let events = await rig.events(job)
        let answer = events.compactMap { event -> String? in
            if case let .toolUse(_, _, data) = event { PyramidScore.answer(from: data) } else { nil }
        }.first
        #expect(answer == "14")
        #expect(Door.words(try #require(brain.requestsSeen.first)).contains(question.ask))
    }
}
