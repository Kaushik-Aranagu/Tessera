import Foundation
@testable import Tessera
import Testing

@Suite("Workout mode: the rest-ended face on the lock screen")
struct ModeEndedTests {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func resting(isPrivate: Bool) -> WorkoutModeState {
        let sets = (0 ..< 3).map { _ in WorkoutModeState.PlannedSet(weight: 185, reps: 5) }
        var state = WorkoutModeState(
            title: isPrivate ? "Private workout" : "Push A", unit: .pounds, startedAt: start,
            lifts: [.init(id: "b", name: "Bench press", restSeconds: 150, sets: sets)]
        )
        state.isPrivate = isPrivate
        state.logSet(at: start)
        return state
    }

    @Test("A public rest carries the face for 0:00: Rest done, you're up, the lift big, the set you're up for")
    func publicFace() throws {
        let content = ModeLiveContent.workout(resting(isPrivate: false), at: start)
        let ended = try #require(content.ended)
        #expect(ended.top == "Rest done, you\u{2019}re up")
        #expect(ended.big == "Bench")
        #expect(ended.next == "185 lb \u{00D7} 5")
        #expect(ModeLiveContent.upWord == "up")
    }

    @Test("A private rest ends as Rest done with a big Up, with no lift name and no weight")
    func privateFace() throws {
        let content = ModeLiveContent.workout(resting(isPrivate: true), at: start)
        let ended = try #require(content.ended)
        #expect(ended.top == "Rest done" && ended.big == "Up" && ended.next.isEmpty)
        let json = try String(decoding: JSONEncoder().encode(content), as: UTF8.self)
        for banned in ["Bench", "bench", "185", "lb"] {
            #expect(!json.contains(banned), "payload leaked \(banned)")
        }
        #expect(json.contains("Rest done") && json.contains("Up"))
    }

    @Test("The face flips on the end date, or when the content goes stale, with no app")
    func flips() {
        let content = ModeLiveContent.workout(resting(isPrivate: false), at: start)
        let end = start.addingTimeInterval(150)
        #expect(!content.hasEnded(at: end.addingTimeInterval(-1), isStale: false))
        #expect(content.hasEnded(at: end, isStale: false))
        #expect(content.hasEnded(at: end.addingTimeInterval(5), isStale: false))
        // Stale at the end date: the system flips it even if the date logic has not run.
        #expect(content.hasEnded(at: start, isStale: true))
    }

    @Test("Content with no ended face never reads as ended")
    func noFace() {
        var state = resting(isPrivate: false)
        state.endRest(at: start.addingTimeInterval(5))
        let content = ModeLiveContent.workout(state, at: start.addingTimeInterval(5))
        #expect(content.ended == nil)
        #expect(!content.hasEnded(at: .distantFuture, isStale: true))
    }

    @Test("The swell is the same as the pan timer's, and none under Reduce Motion")
    func swell() {
        #expect(CookFace.swell.x == 1.08 && CookFace.swell.y == 1.14 && CookFace.swell.duration == 0.52)
        #expect(!CookFace.swells(reduceMotion: true))
    }
}
