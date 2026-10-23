@testable import Tessera
import Testing

/// Ask the page (Design 166): the answer rule and the switch default.
struct AskPageTests {
    @Test func aPrivateObjectStaysOnThePhone() {
        #expect(AskAnswer.make(sentence: "Private workout", isPrivate: true, story: [], changes: 3) == .stays)
    }

    @Test func aClassWithNoSentenceStaysOnThePhone() {
        // Money, body and health classes get no sentence from Describe.
        #expect(AskAnswer.make(sentence: nil, isPrivate: false, story: [], changes: 0) == .stays)
        #expect(AskAnswer.staysWords == "That stays on this phone.")
    }

    @Test func aPlainObjectAnswersWithItsStory() {
        let answer = AskAnswer.make(sentence: "Pay rent, due Friday.", isPrivate: false,
                                    story: ["Moved to Friday"], changes: 2)
        #expect(answer == .answer(sentence: "Pay rent, due Friday.", story: ["Moved to Friday"], changes: 2))
        #expect(AskAnswer.changesWords(1) == "1 change")
        #expect(AskAnswer.changesWords(3) == "3 changes")
    }

    @Test func theSwitchShipsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "askPageV2" })
        #expect(choice.defaultValue == "Off")
        #expect(choice.readiness == .live)
    }
}
