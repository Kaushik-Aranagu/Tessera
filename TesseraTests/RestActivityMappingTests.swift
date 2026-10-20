import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct RestActivityMappingTests {
    private let planned = RestActivityController.PlannedSet(exercise: "Bench Press", setNumber: 3, weight: 82.5,
                                                            reps: 8)
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test func restingCarriesTheCountdown() {
        let state = RestActivityController.contentState(planned: planned, restEndsAt: now.addingTimeInterval(90),
                                                        restTotal: 180, appNow: now, realNow: now)
        #expect(state.phase == .resting)
        #expect(state.restEndsAt == now.addingTimeInterval(90))
        #expect(state.restTotal == 180)
        #expect(state.plannedSet == "82.5 × 8")
        #expect(state.setNumber == 3)
    }

    @Test func demoClockShiftIsMovedOntoRealTime() {
        let appNow = now.addingTimeInterval(3600)
        let state = RestActivityController.contentState(planned: planned, restEndsAt: appNow.addingTimeInterval(60),
                                                        restTotal: 120, appNow: appNow, realNow: now)
        #expect(state.restEndsAt == now.addingTimeInterval(60))
    }

    @Test(arguments: [nil, -5.0])
    func overOrSkippedRestIsReady(offset: TimeInterval?) {
        let state = RestActivityController.contentState(planned: planned,
                                                        restEndsAt: offset.map { now.addingTimeInterval($0) },
                                                        restTotal: 180, appNow: now, realNow: now)
        #expect(state.phase == .ready)
        // Stable, so repeated updates are no-ops.
        #expect(state == RestActivityController.contentState(planned: planned, restEndsAt: nil, restTotal: 180,
                                                             appNow: now.addingTimeInterval(7),
                                                             realNow: now.addingTimeInterval(7)))
    }

    @Test func wholeWeightsDropTheDecimal() {
        let state = RestActivityController.contentState(planned: .init(exercise: "Squat", setNumber: 1, weight: 100,
                                                                       reps: 5),
                                                        restEndsAt: nil, restTotal: 0, appNow: now, realNow: now)
        #expect(state.plannedSet == "100 × 5")
    }

    @Test func aPrivateWorkoutCarriesOnlyTheTimerAndTheMask() throws {
        let state = RestActivityController.contentState(planned: RestActivityController.maskedSet,
                                                        restEndsAt: now.addingTimeInterval(90), restTotal: 180,
                                                        appNow: now, realNow: now, isPrivate: true)
        #expect(state.isPrivate == true && !state.showsSet)
        #expect(state.restEndsAt == now.addingTimeInterval(90) && state.restTotal == 180)
        #expect(state.exercise.isEmpty && state.weight == 0 && state.reps == 0 && state.setNumber == 0)
        let json = try String(decoding: JSONEncoder().encode(state), as: UTF8.self)
        #expect(!json.contains("Bench"), "no exercise name in the payload")
    }

    @Test func anOrdinaryWorkoutShowsItsSetAndOldStatesDecode() throws {
        let state = RestActivityController.contentState(planned: planned, restEndsAt: now.addingTimeInterval(90),
                                                        restTotal: 180, appNow: now, realNow: now)
        #expect(state.isPrivate == false && state.showsSet)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        object.removeValue(forKey: "isPrivate")
        let decoded = try JSONDecoder().decode(RestActivityAttributes.ContentState.self,
                                               from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded.showsSet)
    }

    @Test func aPrivacyChangeMidSessionRestartsTheActivity() {
        #expect(RestActivityController.needsRestart(shownPrivate: false, nowPrivate: true), "turned private")
        #expect(RestActivityController.needsRestart(shownPrivate: true, nowPrivate: false), "turned public")
        #expect(!RestActivityController.needsRestart(shownPrivate: true, nowPrivate: true))
        #expect(!RestActivityController.needsRestart(shownPrivate: false, nowPrivate: false))
        #expect(!RestActivityController.needsRestart(shownPrivate: nil, nowPrivate: true), "no activity yet")
    }

    @Test func anActivityEndedByAPrivacyFlipIsNotAdoptedAgain() {
        let listed = [(id: "old", isActive: true), (id: "new", isActive: true)]
        #expect(RestActivityController.adoptable(listed, excluding: ["old"]) == "new")
        #expect(RestActivityController.adoptable(listed, excluding: []) == "old")
        #expect(RestActivityController.adoptable([(id: "old", isActive: true)], excluding: ["old"]) == nil,
                "nothing else listed: the next rest starts a fresh one")
        #expect(RestActivityController.adoptable([(id: "x", isActive: false)], excluding: []) == nil)
    }

    @Test func anActivityRequestedAfterTheEndIsNotEnded() {
        // "old" was listed when the end was queued; "fresh" was requested in the same update afterwards.
        let ended = RestActivityController.idsToEnd(listed: ["old", "fresh"], captured: ["old"])
        #expect(ended == ["old"])
        #expect(RestActivityController.idsToEnd(listed: ["fresh"], captured: ["old"]).isEmpty)
    }
}
