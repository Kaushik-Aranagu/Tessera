@testable import Tessera
import Testing

/// The Stats switches (Product build sheet, Oct 22): all three ship Off, so the app looks exactly like master.
@MainActor
struct TrainingStatsSwitchTests {
    @Test func theThreeSwitchesAreLiveAndDefaultOff() throws {
        for id in ["trainingStats", "trainingLog", "statsBalance", "trainingLightWeeks"] {
            let choice = try #require(ReviewChoices.all.first { $0.id == id })
            #expect(choice.defaultValue == "Off")
            #expect(choice.readiness == .live)
        }
    }

    @Test func theStatsFacetNamesThem() throws {
        let facet = try #require(ReviewChoices.facets.first { $0.word == "Training stats" })
        #expect(facet.ids == ["trainingStats", "trainingLog", "statsBalance", "trainingLightWeeks"])
    }

    @Test func rangeWordsMatchTheKnob() {
        #expect(StatsRangeWord.allCases.map(\.rawValue) == ["3 months", "Year"])
    }
}
