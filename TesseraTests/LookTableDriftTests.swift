@testable import Tessera
import Testing

/// The look's tokens can't drift: the workout's are the look's own (one base, themes.md fourth addendum), and
/// Shared/LookTable.swift copies each look's base for the widget extension.
@MainActor
struct LookTableDriftTests {
    @Test func theLiveActivityPaletteMatchesEveryLook() throws {
        for look in Look.all {
            let palette = try #require(RestPalette.named(look.name), "\(look.name)")
            #expect(palette.ground == look.ground, "\(look.name) ground")
            #expect(palette.ink == look.ink, "\(look.name) ink")
            #expect(palette.signal == look.live, "\(look.name) live")
            #expect(palette.rest == look.now, "\(look.name) now")
            #expect(palette.tess == look.tess, "\(look.name) tess")
            #expect(palette.context == look.context, "\(look.name) context")
        }
        #expect(RestPalette.forState(day: nil, night: nil, dark: false) == .porcelain)
        #expect(RestPalette.forState(day: "Plein", night: "Lacquer", dark: true) == .lacquer)
    }

    /// Design 43's cut: Obsidian as built; Plein flat with earth pigments and its own training colour.
    @Test func theRecutLooksHoldDesignsValues() {
        #expect(Look.obsidian.ground == 0x000000 && Look.obsidian.context == 0xB7A6E0)
        #expect(Look.porcelain.ink == 0x121016 && Look.porcelain.context == 0x5A3DAF)
        #expect(Look.plein.field == .pigmentBloom && Look.plein.ink == 0x26201E)
        #expect(Look.plein.training != Look.plein.health)
        #expect(Look.celadon.ground == 0xE0EAE2 && Look.celadon.context == 0x3A6584)
        #expect(Look.lacquer.ground == 0x130A0D && Look.lacquer.context == 0xD9A6B8)
        #expect(Look.lacquer.fieldShade == 0x050203 && Look.lacquer.fieldSpecular == 0xFFF1E0)
    }

    @Test func theWorkoutStandsOnTheLooksOwnBase() {
        for look in Look.all {
            let workout = ThemeConcept.dressed(day: look, night: look, current: look).workout
            #expect(workout.ground == look.ground && workout.groundRaised == look.raised, "\(look.name)")
            #expect(workout.ink == look.ink && workout.signal == look.live && workout.rest == look.now, "\(look.name)")
            #expect(workout.tess == look.tess && workout.health == look.health, "\(look.name)")
        }
    }
}
