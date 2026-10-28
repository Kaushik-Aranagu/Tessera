@testable import Tessera
import Testing

/// What the Ask bar answers by itself and what goes to Tess.
struct BottomChromeRoutingTests {
    @Test func onlyBestsPrsAndSecretWordsStayOnThePhone() {
        #expect(BottomChrome.answersOnThePhone("what's my best bench?"))
        #expect(BottomChrome.answersOnThePhone("bench pr"))
        #expect(!BottomChrome.answersOnThePhone("how many sets did I do this week?"))
        #expect(!BottomChrome.answersOnThePhone("what should I cook tonight"))
        #expect(!BottomChrome.answersOnThePhone("how much did I spend on food?"))
    }
}
