import Foundation
@testable import Tessera
import Testing

/// The Lock Screen rest card: Cobalt sky unless the Review switch `review.lockScreenLook` says "Follows the look".
@MainActor
struct LockScreenLookTests {
    private let planned = RestActivityController.PlannedSet(exercise: "Bench", setNumber: 3, weight: 82.5, reps: 8)
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func defaults(_ value: String?) -> UserDefaults {
        let suite = UserDefaults(suiteName: "LockScreenLookTests.\(UUID().uuidString)")!
        if let value {
            suite.set(value, forKey: "review.lockScreenLook")
        }
        return suite
    }

    @Test func theSwitchDefaultsToCobaltSky() {
        #expect(!Choice.lockScreenFollowsLook(defaults: defaults(nil)))
        #expect(!Choice.lockScreenFollowsLook(defaults: defaults("Cobalt sky")))
        #expect(!Choice.lockScreenFollowsLook(defaults: defaults("nonsense")))
        #expect(Choice.lockScreenFollowsLook(defaults: defaults("Follows the look")))
    }

    @Test func offWritesNoLookNamesAndOnWritesThePair() {
        let off = RestActivityController.contentState(planned: planned, restEndsAt: nil, restTotal: 0, appNow: now,
                                                      realNow: now, followsLook: false)
        #expect(off.lookDay == nil && off.lookNight == nil)
        let on = RestActivityController.contentState(planned: planned, restEndsAt: nil, restTotal: 0, appNow: now,
                                                     realNow: now, followsLook: true)
        #expect(on.lookDay == ThemeStore.shared.pair.day.name)
        #expect(on.lookNight == ThemeStore.shared.pair.night.name)
    }

    @Test func noNamesIsCobaltSkyInEveryAppearance() {
        #expect(RestPalette.lockScreen(day: nil, night: nil, dark: false) == .cobaltSky)
        #expect(RestPalette.lockScreen(day: nil, night: nil, dark: true) == .cobaltSky)
    }

    @Test func namesFollowTheDayAndNightLook() {
        #expect(RestPalette.lockScreen(day: "Plein", night: "Lacquer", dark: false) == .plein)
        #expect(RestPalette.lockScreen(day: "Plein", night: "Lacquer", dark: true) == .lacquer)
        #expect(RestPalette.lockScreen(day: "Celadon", night: "Celadon", dark: true) == .celadon)
        // An unknown name falls back to the look pair's defaults, never to a blank card.
        #expect(RestPalette.lockScreen(day: "Gone", night: "Gone", dark: false) == .porcelain)
    }

    /// Done key, closing face and keys draw in ink over the ground: readable (4.5:1) in every look and in Cobalt sky.
    @Test(arguments: ["Porcelain", "Obsidian", "Plein", "Lacquer", "Celadon"])
    func inkIsReadableOnEveryLooksGround(name: String) throws {
        let palette = try #require(RestPalette.named(name))
        #expect(Self.contrast(palette.ink, palette.ground) >= 4.5, "\(name) ink on ground")
        #expect(Self.contrast(palette.signal, palette.ground) >= 3, "\(name) tick on ground")
    }

    @Test func cobaltSkyInkIsReadable() {
        let sky = RestPalette.cobaltSky
        #expect(Self.contrast(sky.ink, sky.ground) >= 4.5)
    }

    private static func luminance(_ hex: UInt32) -> Double {
        func channel(_ shift: UInt32) -> Double {
            let value = Double((hex >> shift) & 0xFF) / 255
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }

    private static func contrast(_ first: UInt32, _ second: UInt32) -> Double {
        let (high, low) = (max(luminance(first), luminance(second)), min(luminance(first), luminance(second)))
        return (high + 0.05) / (low + 0.05)
    }
}
