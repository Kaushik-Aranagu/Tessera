import Foundation
@testable import Tessera
import Testing

/// Product 12:45 PM: one soft warning when a write did not save, once per failure, never on an immediate repeat.
@MainActor
struct FailureHapticTests {
    @Test func theDidntSaveLinePlaysTheWarningOnce() {
        let voice = TessVoice()
        let start = Date(timeIntervalSince1970: 1_792_000_000)
        voice.noteFailure(at: start)
        #expect(voice.failureCue.count == 1 && voice.failureCue.haptic == .notSaved)
        voice.noteFailure(at: start.addingTimeInterval(1))
        #expect(voice.failureCue.count == 1, "an immediate repeat stays quiet")
        voice.noteFailure(at: start.addingTimeInterval(5))
        #expect(voice.failureCue.count == 2, "a later failure plays again")
    }

    @Test func sayingTheLineTriggersItAndInformationLinesDoNot() {
        let voice = TessVoice()
        voice.say("Added rice.")
        voice.say("Didn't save that. A timer runs up to 24 hours.")
        #expect(voice.failureCue.count == 0)
        voice.say("Didn't save that. Try again.")
        #expect(voice.failureCue.count == 1)
    }
}
