import CoreGraphics
@testable import Tessera
import Testing

struct EdgeRollTests {
    @Test func nothingChangesInside() {
        let over = EdgeRoll.overflow(childMin: 10, childMax: 60, clipMin: 0, clipMax: 100)
        #expect(over.fraction == 0)
        #expect(EdgeRoll.look(overflow: 0) == .rest)
        #expect(EdgeRoll.look(overflow: -0.2) == .rest)
    }

    @Test func overflowIsTheShareOfTheThingPastTheEdge() {
        let top = EdgeRoll.overflow(childMin: -20, childMax: 30, clipMin: 0, clipMax: 100)
        #expect(top.side == .leading)
        #expect(abs(top.fraction - 0.4) < 1e-9)
        let bottom = EdgeRoll.overflow(childMin: 80, childMax: 130, clipMin: 0, clipMax: 100)
        #expect(bottom.side == .trailing)
        #expect(abs(bottom.fraction - 0.6) < 1e-9)
        #expect(EdgeRoll.overflow(childMin: -80, childMax: -30, clipMin: 0, clipMax: 100).fraction == 1)
    }

    @Test func threeQuartersPastIsTheFullRoll() {
        let look = EdgeRoll.look(overflow: 0.75)
        #expect(abs(look.tilt - 16) < 1e-9)
        #expect(abs(look.scale - 0.96) < 1e-9)
        #expect(abs(look.blur - 1.2) < 1e-9)
        #expect(abs(look.opacity - 0.08) < 1e-9)
        #expect(EdgeRoll.look(overflow: 1) == look)
    }

    @Test func theCurveIsASmoothstepThatNeverGoesBack() {
        var last = EdgeRoll.look(overflow: 0)
        for step in 1 ... 100 {
            let look = EdgeRoll.look(overflow: CGFloat(step) / 100)
            #expect(look.tilt >= last.tilt)
            #expect(look.blur >= last.blur)
            #expect(look.scale <= last.scale)
            #expect(look.opacity <= last.opacity)
            last = look
        }
        // Gentle start: a tenth of the way to full is well under a tenth of the tilt.
        #expect(EdgeRoll.look(overflow: 0.075).tilt < 1.6)
        // Half way to full is half the tilt.
        #expect(abs(EdgeRoll.look(overflow: 0.375).tilt - 8) < 1e-9)
    }

    @Test func reduceMotionHasNoRoll() {
        let look = EdgeRoll.look(overflow: 0.75, reduceMotion: true)
        #expect(look.tilt == 0)
        #expect(look.scale == 1)
        #expect(look.blur == 0)
        // The crossfade stays.
        #expect(look.opacity < 1)
    }

    @Test func theThingCarriesItsOwnFadeThatEndsAtTheEdge() throws {
        // Fully inside: no mask at all.
        #expect(EdgeRoll.fade(childMin: 10, childMax: 60, clipMin: 0, clipMax: 100) == nil)
        // A 100 pt thing with its top 40 pt past the edge: clear at the edge (0.4), opaque 28 pt inside (0.68).
        let stops = try #require(EdgeRoll.fade(childMin: -40, childMax: 60, clipMin: 0, clipMax: 100))
        #expect(stops.first == .init(location: 0, opacity: 0))
        #expect(stops.contains(.init(location: 0.4, opacity: 0)))
        let opaque = try #require(stops.first { $0.opacity == 1 })
        #expect(abs(opaque.location - 0.68) < 1e-9)
        // Locations never run backwards.
        #expect(zip(stops, stops.dropFirst()).allSatisfy { $0.location <= $1.location })
        // Past the far edge it fades the other way.
        let bottom = try #require(EdgeRoll.fade(childMin: 50, childMax: 150, clipMin: 0, clipMax: 100))
        #expect(bottom.last == .init(location: 1, opacity: 0))
        #expect(bottom.contains(.init(location: 0.5, opacity: 0)))
        #expect(EdgeRoll.fadeDepth == 28)
    }

    @Test func theTiltFallsAwayOverTheEdgeItLeavesBy() {
        #expect(EdgeRoll.tiltSign(side: .leading, axis: .vertical) == -EdgeRoll.tiltSign(
            side: .trailing,
            axis: .vertical
        ))
        #expect(EdgeRoll.tiltSign(side: .leading, axis: .horizontal)
            == -EdgeRoll.tiltSign(side: .trailing, axis: .horizontal))
    }

    @Test func theThreePresetsHaveTheirOwnDepthLeanAndShrink() {
        let card = EdgeRoll.look(overflow: 0.75, preset: .card)
        #expect(EdgeRoll.Preset.card.depth == 28)
        #expect(abs(card.tilt - 16) < 1e-9 && abs(card.scale - 0.96) < 1e-9)
        #expect(abs(card.blur - 1.2) < 1e-9 && abs(card.opacity - 0.08) < 1e-9)

        // Rows: 18 pt, 10 degrees, 3%; the mask is the fade, so no blur and the row's own opacity is untouched.
        let row = EdgeRoll.look(overflow: 0.75, preset: .row)
        #expect(EdgeRoll.Preset.row.depth == 18)
        #expect(abs(row.tilt - 10) < 1e-9 && abs(row.scale - 0.97) < 1e-9)
        #expect(row.blur == 0 && row.opacity == 1)

        // The switcher word: a 22 pt fade only.
        let word = EdgeRoll.look(overflow: 0.75, preset: .word)
        #expect(EdgeRoll.Preset.word.depth == 22)
        #expect(word == .rest)
    }

    @Test func eachPresetsFadeUsesItsOwnDepth() throws {
        for preset in [EdgeRoll.Preset.card, .row, .word] {
            let stops = try #require(EdgeRoll.fade(childMin: -40, childMax: 60, clipMin: 0, clipMax: 100,
                                                   depth: preset.depth))
            let opaque = try #require(stops.first { $0.opacity == 1 })
            #expect(abs(opaque.location - (preset.depth + 40) / 100) < 1e-9)
        }
    }

    @Test func rowsAndWordsKeepTheirOpacityUnderReduceMotionOnlyAsACrossfade() {
        for preset in [EdgeRoll.Preset.row, .word] {
            let look = EdgeRoll.look(overflow: 0.5, preset: preset, reduceMotion: true)
            #expect(look.tilt == 0 && look.scale == 1 && look.blur == 0)
        }
    }
}
