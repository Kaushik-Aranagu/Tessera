import Foundation
@testable import Tessera
import Testing

@MainActor
struct FeatureFlagStoreTests {
    private func fresh() -> UserDefaults {
        let name = "flags.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func aFreshPhoneShipsEveryApprovedFeatureOnAndTheMosaicHomeWins() {
        let defaults = fresh()
        #expect(FeatureFlagStore.isOn("homeMosaic", defaults: defaults) == true)
        #expect(FeatureFlagStore.isOn("tasksApp", defaults: defaults) == true)
        #expect(FeatureFlagStore.isOn("homeV2", defaults: defaults) == false)
        // The apps list view is not drawn yet, so it stays Off until it is.
        #expect(FeatureFlagStore.isOn("homeAppsList", defaults: defaults) == false)
        #expect(FeatureFlagStore.isOn("calendar", defaults: defaults) == nil)
    }

    @Test func anOffHeAsksForStaysOffAndComesBack() {
        let defaults = fresh()
        FeatureFlagStore.set("twinsV2", on: false, defaults: defaults)
        #expect(FeatureFlagStore.isOn("twinsV2", defaults: defaults) == false)
        #expect(FeatureFlagStore.isOn("homeMosaic", defaults: defaults) == true)
        FeatureFlagStore.set("twinsV2", on: true, defaults: defaults)
        #expect(FeatureFlagStore.isOn("twinsV2", defaults: defaults) == true)
        // Turning the last Off back On leaves homeV2 as shipped only on a phone that never stored anything.
        #expect(FeatureFlagStore.off(defaults: defaults).contains("homeV2"))
    }

    @Test func aSwitchHeHadTurnedOffByHandStaysOffAfterTheFirstLaunch() {
        let defaults = fresh()
        defaults.set("Off", forKey: "review.restTimer")
        FeatureFlagStore.migrateOnce(defaults: defaults)
        #expect(FeatureFlagStore.isOn("restTimer", defaults: defaults) == false)
        #expect(FeatureFlagStore.isOn("homeMosaic", defaults: defaults) == true)
        FeatureFlagStore.set("restTimer", on: true, defaults: defaults)
        FeatureFlagStore.migrateOnce(defaults: defaults)
        #expect(FeatureFlagStore.isOn("restTimer", defaults: defaults) == true)
    }

    @Test func theReviewChoicesFacadeReadsAndWritesTheSameStore() throws {
        let defaults = fresh()
        let choices = ReviewChoices(defaults: defaults, writes: true, usesFlags: true)
        let mosaic = try #require(ReviewChoices.all.first { $0.id == "homeMosaic" })
        #expect(choices.value(of: mosaic) == "On")
        choices.set(mosaic, to: "Off")
        #expect(FeatureFlagStore.isOn("homeMosaic", defaults: defaults) == false)
        #expect(choices.isTrying(mosaic))
        choices.resetAll([mosaic])
        #expect(choices.value(of: mosaic) == "On")
    }
}
