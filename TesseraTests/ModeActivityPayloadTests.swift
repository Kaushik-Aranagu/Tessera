import Foundation
@testable import Tessera
import Testing

@MainActor
@Suite("Workout mode: the real activity payload")
struct ModeActivityPayloadTests {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func resting(isPrivate: Bool) -> WorkoutModeState {
        let sets = (0 ..< 3).map { _ in WorkoutModeState.PlannedSet(weight: 185, reps: 5) }
        var state = WorkoutModeState(
            title: isPrivate ? "Private workout" : "Push A", unit: .pounds, startedAt: start,
            lifts: [.init(id: "b", name: "Bench press", restSeconds: 150, sets: sets,
                          history: .init(bestEstimate: 100))]
        )
        state.isPrivate = isPrivate
        state.logSet(at: start)
        // The set beats the best, so a new-best line exists in the app; it must still never reach the activity.
        #expect(state.restNewBest != nil)
        return state
    }

    /// The attributes and the content state, as the activity would carry them.
    func payload(isPrivate: Bool) throws -> String {
        var state = RestActivityController.contentState(
            planned: isPrivate ? RestActivityController.maskedSet
                : .init(exercise: "Bench press", setNumber: 2, weight: 84, reps: 5),
            restEndsAt: start.addingTimeInterval(150), restTotal: 150, appNow: start, realNow: start,
            followsLook: false, isPrivate: isPrivate
        )
        state.mode = ModeLiveContent.workout(resting(isPrivate: isPrivate), at: start)
        let attributes = RestActivityAttributes(workoutTitle: isPrivate ? "Private workout" : "Push A")
        let encoder = JSONEncoder()
        return try String(decoding: encoder.encode(state), as: UTF8.self)
            + String(decoding: encoder.encode(attributes), as: UTF8.self)
    }

    @Test("A private workout's attributes and content state hold no lift, weight, rep or set count")
    func privateHoldsNothing() throws {
        let json = try payload(isPrivate: true)
        for banned in ["Bench", "bench", "185", "84", "Push", "\"setNumber\":2", "new best", "est."] {
            #expect(!json.contains(banned), "payload leaked \(banned)")
        }
        #expect(json.contains("Private workout"))
    }

    @Test("A public workout carries the mode's lines")
    func publicCarries() throws {
        #expect(try payload(isPrivate: false).contains("Rest, then bench"))
    }
}
