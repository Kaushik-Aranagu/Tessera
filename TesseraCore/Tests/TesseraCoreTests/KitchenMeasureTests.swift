import Foundation
@testable import TesseraCore
import Testing

/// Kitchen units in Measure: mass and volume, the bridge from a parsed line, and how cooks read the numbers.
struct KitchenMeasureTests {
    func volume(_ value: Double, _ unit: String) -> Measure {
        Measure(value, unit, kind: .kitchenVolume)
    }

    func mass(_ value: Double, _ unit: String) -> Measure {
        Measure(value, unit, kind: .kitchenMass)
    }

    @Test func eachKitchenConversionIsRight() throws {
        let cupMl = try #require(volume(1, "cup").converted(to: "ml")?.value)
        #expect(abs(cupMl - 236.588) < 0.001)
        #expect(try abs(#require(volume(1, "tbsp").converted(to: "tsp")?.value) - 3) < 1e-9)
        #expect(try abs(#require(volume(1, "cup").converted(to: "tbsp")?.value) - 16) < 1e-9)
        #expect(try abs(#require(volume(1, "fl oz").converted(to: "tbsp")?.value) - 2) < 1e-9)
        #expect(try abs(#require(volume(1, "l").converted(to: "ml")?.value) - 1000) < 1e-9)
        #expect(try abs(#require(mass(1, "kg").converted(to: "g")?.value) - 1000) < 1e-9)
        #expect(try abs(#require(mass(1, "lb").converted(to: "g")?.value) - 453.592) < 0.001)
        #expect(try abs(#require(mass(16, "oz").converted(to: "lb")?.value) - 1) < 1e-9)
        // "kg" is in two kinds; the measure's own kind decides.
        #expect(try abs(#require(mass(1, "kg").converted(to: "oz")?.value) - 35.274) < 0.001)
        #expect(try abs(#require(Measure(1, "kg").converted(to: "lb")?.value) - 2.2046) < 0.0001)
    }

    @Test func everyPairInAKindRoundTrips() throws {
        for kind in [MeasureKind.kitchenMass, .kitchenVolume] {
            for from in kind.units {
                for to in kind.units {
                    let there = try #require(UnitConverter.convert(37.5, from: from, to: to, kind: kind))
                    let back = try #require(UnitConverter.convert(there, from: to, to: from, kind: kind))
                    #expect(abs(back - 37.5) < 1e-9, "\(from) \(to)")
                }
            }
        }
    }

    @Test func volumeNeverBecomesMassAndTheOtherWayRound() {
        #expect(volume(1, "cup").converted(to: "g") == nil)
        #expect(mass(100, "g").converted(to: "ml") == nil)
        #expect(volume(1, "cup").converted(to: "kg") == nil)
        #expect(UnitConverter.convert(1, from: "cup", to: "g") == nil)
        #expect(volume(1, "cup").converted(to: "lb") == nil)
    }

    @Test(arguments: [
        (0.25, "cup", "¼ cup"), (1.5, "cup", "1½ cups"), (0.333_333, "cup", "⅓ cup"), (1.0, "cup", "1 cup"),
        (2.0, "cup", "2 cups"), (2.0, "tbsp", "2 tbsp"), (0.5, "tsp", "½ tsp"), (0.75, "tsp", "¾ tsp"),
        (0.666_667, "cup", "⅔ cup"), (1.25, "tbsp", "1¼ tbsp"), (0.999, "cup", "1 cup"), (0.43, "cup", "⅜ cup"),
        (1.99, "tsp", "2 tsp"), (0.125, "tsp", "⅛ tsp"), (3.0, "fl oz", "3 fl oz"),
    ])
    func spoonsAndCupsReadAsFractions(_ value: Double, _ unit: String, _ shown: String) {
        #expect(volume(value, unit).formatted == shown, "\(value) \(unit)")
    }

    @Test(arguments: [
        (250.0, "g", "250 g"), (453.59, "g", "454 g"), (0.4, "g", "0.4 g"), (1.5, "kg", "1.5 kg"), (8.0, "oz", "8 oz"),
        (1.25, "lb", "1¼ lb"), (1.5, "lb", "1½ lb"), (0.25, "kg", "0.25 kg"), (0.003, "kg", "0.003 kg"),
        (0.375, "oz", "⅜ oz"), (0.4, "oz", "0.4 oz"),
    ])
    func massReadsInWholeGramsAndSensibleDecimals(_ value: Double, _ unit: String, _ shown: String) {
        #expect(mass(value, unit).formatted == shown)
    }

    @Test func anAmountUnderAHalfOfAHundredthOfAGramSaysLessThanOne() {
        #expect(mass(0.03, "g").formatted == "less than 1 g" && volume(0.04, "ml").formatted == "less than 1 ml")
        #expect(mass(0.05, "g").formatted == "0.1 g" && mass(0.4, "g").formatted == "0.4 g")
        #expect(mass(0, "g").formatted == "0 g")
        #expect(mass(1, "kg").converted(to: "g")?.aboutFormatted == "about 1000 g")
        #expect(mass(0.04, "g").converted(to: "g")?.aboutFormatted == "less than 1 g")
        #expect(Measure(0.03, "kg").converted(to: "lb") != nil)
    }

    @Test func aConvertedAmountSaysSoSoTheViewCanPutAboutBeforeIt() throws {
        let converted = try #require(volume(250, "ml").converted(to: "cup"))
        #expect(converted.isConverted && converted.aboutFormatted == "about 1 cup")
        let same = try #require(volume(250, "ml").converted(to: "ml"))
        #expect(!same.isConverted && same.aboutFormatted == "250 ml")
        #expect(!volume(1, "cup").isConverted && volume(1, "cup").aboutFormatted == "1 cup")
        let flour = try #require(IngredientLine.parse("1 1/2 cups flour")?.reading?.measure)
        #expect(!flour.isConverted)
        // Only the cups snap that wide; a tablespoon stays within a hair.
        #expect(volume(1.05, "tbsp").formatted == "1.05 tbsp" && volume(1.05, "cup").formatted == "1 cup")
    }

    @Test func pintsAndQuartsAreOnTheVolumeWheel() throws {
        #expect(MeasureKind.kitchenVolume.units.suffix(2) == ["pt", "qt"])
        #expect(try abs(#require(volume(1, "pt").converted(to: "cup")?.value) - 2) < 0.001)
        #expect(try abs(#require(volume(1, "qt").converted(to: "pt")?.value) - 2) < 1e-9)
        #expect(volume(0.5, "pt").formatted == "½ pt" && volume(2, "qt").formatted == "2 qt")
    }

    @Test func millilitresAreWholeAndLitresHaveTwoDecimals() {
        #expect(volume(236.588, "ml").formatted == "237 ml" && volume(4.93, "ml").formatted == "5 ml")
        #expect(volume(1.5, "l").formatted == "1.5 l" && volume(0.25, "l").formatted == "0.25 l")
    }

    @Test func convertedAmountsReadTheWayACookSaysThem() {
        #expect(volume(1, "cup").converted(to: "ml")?.formatted == "237 ml")
        #expect(volume(1, "tbsp").converted(to: "tsp")?.formatted == "3 tsp")
        #expect(volume(2, "cup").converted(to: "fl oz")?.formatted == "16 fl oz")
        #expect(volume(250, "ml").converted(to: "cup")?.formatted == "1 cup")
        #expect(volume(237, "ml").converted(to: "cup")?.formatted == "1 cup")
        #expect(volume(60, "ml").converted(to: "cup")?.formatted == "¼ cup")
        #expect(mass(1, "lb").converted(to: "g")?.formatted == "454 g")
        #expect(mass(8, "oz").converted(to: "g")?.formatted == "227 g")
        #expect(mass(500, "g").converted(to: "oz")?.formatted == "17⅝ oz")
        #expect(mass(250, "g").converted(to: "kg")?.formatted == "0.25 kg")
        #expect(volume(5, "ml").converted(to: "l")?.formatted == "0.005 l")
        #expect(mass(454, "g").converted(to: "lb")?.formatted == "1 lb")
        #expect(mass(570, "g").converted(to: "lb")?.formatted == "1¼ lb")
    }

    @Test func theBridgeReadsMassAndVolumeLinesAsMeasures() throws {
        let flour = try #require(IngredientLine.parse("1 1/2 cups flour, sifted"))
        let reading = try #require(flour.reading)
        #expect(reading.measure == volume(1.5, "cup") && reading.hasWheel)
        #expect(flour.typedAmountText == "1 1/2 cups")
        let butter = try #require(IngredientLine.parse("200g butter"))
        #expect(butter.reading?.measure == mass(200, "g") && butter.typedAmountText == "200g")
        let beef = try #require(IngredientLine.parse("1 lb ground beef"))
        #expect(beef.reading?.measure?.converted(to: "g")?.formatted == "454 g")
        let oil = try #require(IngredientLine.parse("2–3 tbsp olive oil"))
        guard case let .measure(low, upper?)? = oil.reading else {
            Issue.record("not a ranged measure")
            return
        }
        #expect(low == volume(2, "tbsp") && upper == volume(3, "tbsp"))
        let milk = try #require(IngredientLine.parse("500 ml milk"))
        #expect(milk.reading?.measure?.converted(to: "cup")?.formatted == "2⅛ cups")
    }

    @Test func countsAndUnitsWithNoWheelComeBackAsPlainNumbers() throws {
        let eggs = try #require(IngredientLine.parse("3 eggs"))
        #expect(eggs.reading == .plain(amount: 3, upper: nil, word: nil) && eggs.reading?.hasWheel == false)
        let garlic = try #require(IngredientLine.parse("2 cloves garlic"))
        #expect(garlic.reading == .plain(amount: 2, upper: nil, word: "clove"))
        let tomatoes = try #require(IngredientLine.parse("1 (14.5 oz) can diced tomatoes"))
        #expect(tomatoes.reading?.hasWheel == false)
        // A pint has a wheel now; a can does not.
        let cream = try #require(IngredientLine.parse("1 pint cream"))
        #expect(cream.reading?.measure == volume(1, "pt"))
        #expect(IngredientLine.parse("salt to taste")?.reading == nil)
    }

    @Test func readingALineNeverChangesIt() throws {
        let line = try #require(IngredientLine.parse("1 1/2 cups flour, sifted"))
        let before = line
        _ = line.reading?.measure?.converted(to: "ml")
        #expect(line == before && line.amount == 1.5 && line.unit == .cup)
    }

    @Test func theKitchenKindsKeepTheirOwnChoiceAndLeaveBodyWeightAlone() {
        var units = DisplayUnits()
        units.choose("oz", for: .kitchenMass)
        units.choose("lb", for: .weight)
        #expect(units.unit(for: .kitchenMass) == "oz" && units.unit(for: .kitchenVolume) == nil)
        #expect(units.shown(mass(454, "g")).formatted == "16 oz")
        #expect(units.shown(Measure(80, "kg")).formatted == "176.4 lb")
        #expect(units.shown(volume(1, "cup")) == volume(1, "cup"))
        #expect(DisplayUnits(encoded: units.encoded) == units)
    }

    @Test func moneyAndTheOtherKindsAreUnchanged() {
        #expect(Measure(82.5, "kg").converted(to: "lb")?.formatted == "181.9 lb")
        #expect(MeasureKind.kind(ofUnit: "g") == .kitchenMass && MeasureKind.kind(ofUnit: "cup") == .kitchenVolume)
        #expect(Measure.money(12.4, currency: "EUR").converted(to: "GBP") == nil)
        #expect(MeasureKind.allCases.count == 8)
    }
}
