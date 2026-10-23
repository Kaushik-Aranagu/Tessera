import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Designs 161 and 155: the Pantry levels and the shop run, pure pieces.
@MainActor
struct PantryShopV2Tests {
    @Test func bothSwitchesDefaultOffAndAreLive() throws {
        for id in ["pantryLevelsV2", "shopV2"] {
            let choice = try #require(ReviewChoices.all.first { $0.id == id })
            #expect(choice.defaultValue == "Off")
            #expect(choice.readiness == .live)
            #expect(choice.values == ["Off", "On"])
        }
        let kept = try ReviewChoices(
            defaults: #require(UserDefaults(suiteName: "PantryShopV2Tests.\(UUID())")),
            writes: false
        )
        #expect(kept.value(of: "pantryLevelsV2") == "Off")
        #expect(kept.value(of: "shopV2") == "Off")
    }

    @Test func theTwoSwitchesSitOnTheirOwnPage() throws {
        let page = try #require(ReviewChoices.facetPages().first { $0.word == "Kitchen v2" })
        #expect(page.rows.map(\.id) == ["pantryLevelsV2", "shopV2"])
    }

    @Test func gotAndLeftReadAsOneSentence() {
        #expect(ShopV2Copy.gotLeft(got: 12, left: 2) == "12 got, 2 left for next time.")
        #expect(ShopV2Copy.gotLeft(got: 5, left: 0) == "5 got, nothing left.")
        #expect(ShopV2Copy.gotLeft(got: 0, left: 3) == "Nothing got, 3 left for next time.")
        #expect(ShopV2Copy.gotLeft(got: 0, left: 0) == "Nothing in the basket.")
    }

    @Test func theAboutTotalIsWholeDollars() {
        #expect(ShopV2Copy.about(0) == nil)
        #expect(ShopV2Copy.about(13.6) == "about $14")
        #expect(ShopV2Copy.about(4.2 + 3.1) == "about $7")
    }

    @Test func aTypedPriceParses() {
        #expect(ShopV2Copy.price("3.50") == 3.5)
        #expect(ShopV2Copy.price("$4") == 4)
        #expect(ShopV2Copy.price(" 2,75 ") == 2.75)
        #expect(ShopV2Copy.price("") == nil)
        #expect(ShopV2Copy.price("milk") == nil)
        #expect(ShopV2Copy.price("-3") == nil)
    }

    @Test func pricesStayInDefaultsAndClear() throws {
        let defaults = try #require(UserDefaults(suiteName: "PantryShopV2Tests.\(UUID())"))
        var prices = ShopPrices(defaults: defaults)
        #expect(prices.total == 0)
        prices.set(3.5, for: UUID(), defaults: defaults)
        prices.set(4, for: UUID(), defaults: defaults)
        #expect(ShopPrices(defaults: defaults).total == 7.5)
        prices.clear(defaults: defaults)
        #expect(ShopPrices(defaults: defaults).total == 0)
    }

    @Test func aLevelFollowsRuleA() {
        #expect(KitchenFront.level([.have, .low, .out, .unknown]) == 0.5)
        #expect(KitchenFront.level([.unknown]) == nil)
    }
}
