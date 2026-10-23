import Foundation
@testable import TesseraCore
import Testing

/// Together round 15, 189 unitsV2: three rows, the other choice one tap away, a sample line, stored values untouched.
@MainActor
struct UnitsPageTests {
    @Test func theDefaultRowsReadKgKmGrams() {
        let rows = UnitsPage.rows(DisplayUnits())
        #expect(rows.map(\.text) == ["Weight, kg", "Distance, km", "Food, grams"])
        #expect(rows.map(\.other) == ["lb", "mi", "oz"])
        #expect(rows[0].sample == "Bench 82.5 kg is 181.9 lb.")
        #expect(rows[1].sample == "A run of 5 km is 3.11 mi.")
        #expect(rows[2].sample == "Rice 500 g is 17⅝ oz.")
    }

    @Test func pickingTheOtherChoiceChangesTheRowAndNothingStored() throws {
        var units = DisplayUnits()
        #expect(UnitsPage.choose("lb", for: .weight, in: &units))
        #expect(UnitsPage.choose("oz", for: .kitchenMass, in: &units))
        let rows = UnitsPage.rows(units)
        #expect(rows.map(\.text) == ["Weight, lb", "Distance, km", "Food, ounces"])
        #expect(rows[0].other == "kg")
        // A stored 82.5 kg set is still 82.5 kg; only its shown number reads through Measure.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let set = try store.create(#require(classes[.set]))
        try store.set("weight", to: .mass(82.5), on: set)
        #expect(store.value("weight", of: set) == .mass(82.5))
        #expect(units.weight(kilograms: 82.5)?.formatted == "181.9 lb")
        #expect(store.value("weight", of: set) == .mass(82.5))
        #expect(DisplayUnits(encoded: units.encoded) == units)
    }

    @Test func aUnitThePageDoesNotOfferIsRefusedAndMoneyAndTemperatureHaveNoRow() {
        var units = DisplayUnits()
        #expect(!UnitsPage.choose("mi", for: .weight, in: &units))
        #expect(!UnitsPage.choose("kg", for: .kitchenMass, in: &units))
        #expect(!UnitsPage.choose("USD", for: .money, in: &units))
        #expect(!UnitsPage.choose("°F", for: .temperature, in: &units))
        #expect(units == DisplayUnits())
        #expect(!UnitsPage.kinds.contains(.money) && !UnitsPage.kinds.contains(.temperature))
    }

    @Test func anOldPickTheRowCannotShowFallsBackToTheFirstChoice() {
        var units = DisplayUnits()
        units.choose("kg", for: .kitchenMass)
        #expect(UnitsPage.rows(units)[2].text == "Food, grams")
    }
}
