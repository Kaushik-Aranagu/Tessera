@testable import Tessera
import Testing

@MainActor
struct TwinsOfferTests {
    @Test func theSwitchIsLiveAndDefaultsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "twinsV2" })
        #expect(choice.defaultValue == "Off")
        #expect(choice.readiness == .live)
        #expect(choice.values == ["Off", "On"])
    }

    @Test func noFacetHoldsMoreThanSix() {
        for facet in ReviewChoices.facets {
            #expect(facet.ids.count <= 6)
        }
        #expect(ReviewChoices.facets.contains { $0.ids.contains("twinsV2") })
    }
}
