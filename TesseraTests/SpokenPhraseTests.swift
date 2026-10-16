@testable import Tessera
import Testing

/// Speak (speak.md): fillers squeezed out, the whole phrase "undo" recognised.
struct SpokenPhraseTests {
    @Test func fillersGoAndUndoIsRecognised() {
        #expect(SpokenPhrase.clean("um oat milk and uh eggs") == "oat milk and eggs")
        #expect(SpokenPhrase.isUndo("Undo."))
        #expect(SpokenPhrase.isUndo("take that back"))
        #expect(!SpokenPhrase.isUndo("undo the bench set"))
    }

    @Test func refusalsSayWhatStillWorks() {
        #expect(SpeechListener.Refusal.micOff.line == "Mic is off for Tessera.")
        #expect(SpeechListener.Refusal.micOff.action == "Open Settings")
        #expect(SpeechListener.Refusal.noLanguage.action == "Write")
    }
}
