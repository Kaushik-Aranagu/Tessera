@testable import Tessera
import Testing

/// The Training landing's words: one estimate, house lengths, the one key word.
struct TrainingLandingTests {
    @Test func theSentenceCarriesTheSessionAsItsKeyWord() {
        let sentence = TrainingPage.sentence(
            session: "Push A",
            minutes: 45,
            opener: (exercise: "Bench", weight: "82.5 kg")
        )
        #expect(sentence.text == "Push A today, about 45 min. Bench opens at 82.5 kg.")
        #expect(sentence.key == "Push A")
    }

    @Test func anHourOrMoreReadsTheHouseWay() {
        let sentence = TrainingPage.sentence(session: "Legs", minutes: 90, opener: nil)
        #expect(sentence.text == "Legs today, about 1 hr 30 min.")
    }

    @Test func nothingPlannedSaysSoWithNoKeyWord() {
        let sentence = TrainingPage.sentence(session: nil, minutes: nil, opener: nil)
        #expect(sentence.text == "Nothing planned today.")
        #expect(sentence.key == nil)
    }

    @Test func oneEstimateFeedsEveryLine() {
        // 18 sets at two and a half minutes is 45; the kicker's words and the sentence's minutes agree.
        #expect(TrainingPage.estimatedMinutes(sets: 18) == 45)
        #expect(TrainingPage.about(sets: 18) == "about 45 min")
        #expect(TrainingPage.about(sets: 36) == "about 1 hr 30 min")
    }
}
