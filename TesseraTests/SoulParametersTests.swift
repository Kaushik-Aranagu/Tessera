import Foundation
@testable import Tessera
import TesseraCore
import Testing

struct SoulParametersTests {
    static let modes: [TessSoul.Mode] = [
        .idle, .listening, .thinking, .done, .needsYou, .handOff(target: CGPoint(x: 80, y: -40)), .resting,
    ]

    @Test(arguments: modes)
    func everyModeHasAFullRow(mode: TessSoul.Mode) {
        let row = SoulParameters.table(mode)
        #expect(row.mains.count == 3)
        #expect(row.satellites.count == 3)
        for track in row.mains + row.satellites {
            #expect(track.period > 0)
            #expect(track.keys.first?.time == 0)
            #expect(track.keys.last?.time == 1)
            #expect(track.keys.map(\.time) == track.keys.map(\.time).sorted())
        }
    }

    @Test func onlyDoneAndHandOffAreOneShots() {
        #expect(TessSoul.Mode.done.isOneShot)
        #expect(SoulParameters.table(.done).oneShot == 1.8)
        #expect(SoulParameters.table(.done).ring != nil)
        #expect(TessSoul.Mode.handOff(target: .zero).isOneShot)
        for mode in Self.modes where mode != .done {
            if case .handOff = mode {
                continue
            }
            #expect(!mode.isOneShot)
        }
    }

    @Test func idleIsSmallerAndSlowWithNoDrip() {
        let idle = SoulParameters.table(.idle)
        #expect(idle.look.scale < SoulParameters.table(.needsYou).look.scale)
        #expect(idle.drip == nil)
        #expect(idle.isSlow)
        #expect(SoulParameters.table(.needsYou).drip != nil)
    }

    @Test func doneHoldsItsLastFrameOnceFinished() {
        let late = SoulFrame.sample(.done, time: 100, elapsed: 5)
        let later = SoulFrame.sample(.done, time: 200, elapsed: 9)
        #expect(late.dabs == later.dabs)
        #expect(late.ring.opacity == 0)
    }

    @Test(arguments: modes)
    func blendingReturnsTheEndpoints(mode: TessSoul.Mode) {
        let start = SoulFrame.sample(.idle, time: 12.3, elapsed: 0.7)
        let end = SoulFrame.sample(mode, time: 12.3, elapsed: 0.7)
        #expect(SoulFrame.mix(start, end, 0) == start)
        #expect(SoulFrame.mix(start, end, 1) == end)
        #expect(SoulBlend.weight(0) == 0)
        #expect(SoulBlend.weight(SoulBlend.duration) == 1)
    }

    @Test func aModeChangeBlendsInsteadOfSnapping() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        var layers = SoulBlend.push(.idle, onto: [], at: start)
        let switchAt = start.addingTimeInterval(5)
        layers = SoulBlend.push(.thinking, onto: layers, at: switchAt)
        let atSwitch = try #require(SoulBlend.frame(layers, at: switchAt, loops: false))
        let idleThen = SoulFrame.sample(.idle, time: switchAt.timeIntervalSinceReferenceDate, elapsed: 5)
        #expect(atSwitch == idleThen)
        let after = switchAt.addingTimeInterval(SoulBlend.duration)
        let settled = try #require(SoulBlend.frame(layers, at: after, loops: false))
        #expect(settled == SoulFrame.sample(.thinking, time: after.timeIntervalSinceReferenceDate,
                                            elapsed: SoulBlend.duration))
        // Once settled, the idle layer is dropped on the next change.
        layers = SoulBlend.push(.done, onto: layers, at: after.addingTimeInterval(1))
        #expect(layers.map(\.mode) == [.thinking, .done])
    }
}
