@testable import Tessera
import Testing

/// QA W9: Shared/LookTable.swift copies each look's workout set for the widget extension; it can't drift.
struct LookTableDriftTests {
    @Test func theLiveActivityPaletteMatchesEveryLook() throws {
        for look in Look.all {
            let palette = try #require(RestPalette.named(look.name), "\(look.name)")
            let kit = look.workout
            #expect(palette.ground == kit.ground, "\(look.name) ground")
            #expect(palette.ink == kit.ink, "\(look.name) ink")
            #expect(palette.signal == kit.signal, "\(look.name) signal")
            #expect(palette.rest == kit.rest, "\(look.name) rest")
            #expect(palette.tess == kit.tess, "\(look.name) tess")
            #expect(palette.context == look.context, "\(look.name) context")
        }
        #expect(RestPalette.forState(day: nil, night: nil, dark: false) == .porcelain)
        #expect(RestPalette.forState(day: "Plein", night: "Lacquer", dark: true) == .lacquer)
    }
}
