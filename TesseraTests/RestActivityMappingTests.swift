import Foundation
@testable import Tessera
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
}
