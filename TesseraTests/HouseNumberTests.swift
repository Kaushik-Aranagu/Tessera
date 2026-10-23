@testable import Tessera
import Testing

/// The words of a number (Design 138): hung fractions, the no-break space, "was", weights.
struct HouseNumberTests {
    @Test func aQuarterHalfOrThreeQuartersHangs() {
        #expect(HouseNumberText.parts(82.5) == ("82", "½"))
        #expect(HouseNumberText.parts(12.25) == ("12", "¼"))
        #expect(HouseNumberText.parts(7.75) == ("7", "¾"))
    }

    @Test func otherFractionsStayDecimal() {
        #expect(HouseNumberText.parts(82.6) == ("82.6", nil))
        #expect(HouseNumberText.parts(80) == ("80", nil))
        #expect(HouseNumberText.parts(-2.5) == ("-2", "½"))
    }

    @Test func theUnitIsJoinedByANoBreakSpace() {
        #expect(HouseNumberText.line(82.5, unit: "kg") == "82½\u{00A0}kg")
        #expect(HouseNumberText.line(12, unit: nil) == "12")
        #expect(!HouseNumberText.line(30, unit: "min").contains(" "))
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

    @Test func theSwitchShipsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "numberRules" })
        #expect(choice.defaultValue == "Off")
    }
}
