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

    @Test func theWorkoutStandsOnTheLooksOwnBase() {
        for look in Look.all {
            let workout = ThemeConcept.dressed(day: look, night: look, current: look).workout
            #expect(workout.ground == look.ground && workout.groundRaised == look.raised, "\(look.name)")
            #expect(workout.ink == look.ink && workout.signal == look.live && workout.rest == look.now, "\(look.name)")
            #expect(workout.tess == look.tess && workout.health == look.health, "\(look.name)")
        }
    }
}
