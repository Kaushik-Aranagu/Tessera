import SwiftUI
@testable import Tessera
import Testing

/// The words of a number (Design 138): hung decimals, vulgar fractions only when asked, the no-break space, "was".
struct HouseNumberTests {
    @Test func aWeightHangsItsDecimalPart() {
        #expect(HouseNumberText.parts(82.5) == ("82", ".5"))
        #expect(HouseNumberText.parts(12.25) == ("12", ".25"))
        #expect(HouseNumberText.parts(82.6) == ("82", ".6"))
        #expect(HouseNumberText.parts(80) == ("80", nil))
    }

    @Test func vulgarFractionsAreOnlyForKitchen() {
        #expect(HouseNumberText.parts(0.5, style: .vulgar) == ("", "½"))
        #expect(HouseNumberText.parts(1.5, style: .vulgar) == ("1", "½"))
        #expect(HouseNumberText.parts(2.75, style: .vulgar) == ("2", "¾"))
        // A weight never reads "82½ kg": the default is decimal.
        #expect(!HouseNumberText.line(82.5, unit: "kg").contains("½"))
        #expect(HouseNumberText.line(82.5, unit: "kg") == "82.5\u{00A0}kg")
        // A vulgar style still hangs a non-quarter as a decimal.
        #expect(HouseNumberText.parts(1.6, style: .vulgar) == ("1", ".6"))
    }

    @Test func theUnitIsJoinedByANoBreakSpace() {
        #expect(HouseNumberText.line(12, unit: nil) == "12")
        #expect(!HouseNumberText.line(30, unit: "min").contains(" "))
        #expect(HouseNumberText.line(0.5, unit: "cup", style: .vulgar) == "½\u{00A0}cup")
    }

    @Test func wasNeverShowsOnMoney() {
        #expect(HouseNumberText.was(80, unit: "kg", isMoney: false) == "was 80\u{00A0}kg")
        #expect(HouseNumberText.was(80, unit: nil, isMoney: true) == nil)
        #expect(HouseNumberText.was(nil, unit: "kg", isMoney: false) == nil)
    }

    @Test func anExactValueIsOneStepHeavierThanAnEstimate() {
        #expect(HouseNumberText.weight(estimate: true, size: 40) == .thin)
        #expect(HouseNumberText.weight(estimate: false, size: 40) == .light)
        #expect(HouseNumberText.weight(estimate: true, size: 20) == .light)
        #expect(HouseNumberText.weight(estimate: false, size: 20) == .regular)
    }

    @Test func aPullAddsUpToTwoHundred() {
        #expect(HouseNumberText.weight(.light, pressure: 0) == .light)
        #expect(HouseNumberText.weight(.light, pressure: 1) == .medium)
        #expect(HouseNumberText.weight(.regular, pressure: 0.5) == .medium)
        #expect(HouseNumberText.weight(.light, pressure: 9) == .medium)
    }

    @Test func theFractionIsOneRoleSmaller() {
        #expect(HouseNumber.smaller(.titleNumber) == .body)
        #expect(HouseNumber.smaller(.heroNumber) == .titleNumber)
        #expect(HouseNumber.smaller(.body) == .label)
    }

    @Test func theOffPathPrintsPlainDigits() {
        #expect(HouseNumber.plain(82.5, unit: "kg") == "82.5 kg")
        #expect(HouseNumber.plain(80, unit: nil) == "80")
        #expect(!HouseNumber.plain(82.5, unit: "kg").contains("½"))
    }

    @Test func theSwitchShipsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "numberRules" })
        #expect(choice.defaultValue == "Off")
    }
}
