import Foundation
@testable import Tessera
import Testing

/// docs/research/theme-schedule.md fixtures that live in the store: day is Light and night is Dark, whatever set
/// it; pins; the demo pin; the workout holding its look.
struct ThemeStoreTests {
    private func fresh(dark: Bool = false) -> (ThemeStore, UserDefaults) {
        let suite = "looks-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (ThemeStore(defaults: defaults, systemIsDark: dark), defaults)
    }

    @Test func aDarkLaunchDrawsTheNightLookFromTheFirstFrame() {
        let (store, _) = fresh(dark: true)
        #expect(store.current == .obsidian)
        let (light, _) = fresh(dark: false)
        #expect(light.current == .porcelain)
    }

    @Test func theAppearanceAloneSwapsDayAndNight() {
        let (store, _) = fresh()
        store.systemIsDark = true
        #expect(store.current == .obsidian)
        store.systemIsDark = false
        #expect(store.current == .porcelain)
    }

    @Test func unpinningPutsTheLookBackInItsOwnSlot() {
        let (store, defaults) = fresh()
        store.cycleNight() // Lacquer by night
        store.togglePin(.celadon)
        #expect(store.current == .celadon)
        store.togglePin(.celadon)
        #expect(store.pinned == nil)
        #expect(store.day == .celadon)
        #expect(store.night == .lacquer)
        #expect(defaults.string(forKey: "look.day") == "Celadon")
    }

    @Test func theDemoPinIsNeverSaved() {
        let (store, defaults) = fresh()
        store.pin(.obsidian)
        #expect(store.current == .obsidian)
        store.cycleDay() // a tap during a recording
        #expect(defaults.string(forKey: "look.pinned") == nil)
        #expect(defaults.string(forKey: "look.day") == nil) // demo taps stay in memory (QA W4)
    }

    @Test func stepsGoBothWays() {
        let (store, _) = fresh()
        store.cycleDay()
        #expect(store.day == .plein)
        store.cycleDayBack()
        #expect(store.day == .porcelain)
        store.togglePin(.obsidian)
        store.cyclePinned()
        #expect(store.pinned == .plein)
        store.cyclePinned(forward: false)
        #expect(store.pinned == .obsidian)
    }

    @Test func theWorkoutKeepsItsLookUntilItCloses() {
        let (store, _) = fresh()
        store.holdWorkoutLook()
        store.systemIsDark = true
        #expect(store.concept.workout.ground == Look.porcelain.workout.ground)
        store.releaseWorkoutLook()
        #expect(store.concept.workout.ground == Look.obsidian.workout.ground)
    }

    @Test func demoTapsStayInMemory() {
        let (store, defaults) = fresh()
        store.pin(.porcelain)
        store.cyclePinned()
        #expect(store.current == .obsidian)
        store.togglePin(.obsidian)
        #expect(store.pin == nil)
        #expect(defaults.string(forKey: "look.pinned") == nil)
        #expect(defaults.string(forKey: "look.day") == nil)
    }

    /// QA W2: the held look drives the workout field, shadows and glass edge, not the look on screen.
    @Test func theHeldLookIsTheWorkoutsLook() {
        let (store, _) = fresh()
        store.cycleDay() // Plein by day
        store.holdWorkoutLook()
        store.systemIsDark = true
        #expect(store.current == .obsidian)
        #expect(store.workoutLook == .plein)
    }

    /// QA W8: while the workout is open, paint tokens resolve against its forced-dark pages.
    @Test func paintResolvesAgainstTheWorkoutsPages() {
        let (store, _) = fresh()
        #expect(store.paintLook == .porcelain)
        store.holdWorkoutLook()
        #expect(store.paintLook == .obsidian)
        store.releaseWorkoutLook()
        #expect(store.paintLook == .porcelain)
    }

    @Test func aRestoredLookIsAdoptedOnlyIfNoneWasChosen() {
        let (store, _) = fresh()
        store.adoptRestored(day: "Celadon", night: "Lacquer", pinned: nil)
        #expect(store.day == .celadon && store.night == .lacquer)
        store.adoptRestored(day: "Plein", night: "Obsidian", pinned: nil)
        #expect(store.day == .celadon)
    }
}
