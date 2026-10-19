@testable import Tessera
import Testing

/// Kitchen hunt 27 (ruled): cancelling during the first mic prompt never leaves a live listen.
@MainActor
struct SpeechListenerTests {
    @Test func aStopDuringTheMicPromptLeavesNoListen() async {
        let listener = SpeechListener()
        var finished: [String?] = []
        listener.onFinish = { finished.append($0) }
        var spokeToSpeech = false
        listener.askSpeech = { spokeToSpeech = true; return true }
        // The prompt is answered "Allow" only after he has already cancelled.
        listener.askMic = { [listener] in
            listener.stop(send: false)
            return true
        }
        let refusal = await listener.start(hold: false)
        #expect(refusal == nil)
        #expect(listener.state == .idle)
        #expect(!spokeToSpeech)
        #expect(finished == [nil])
    }

    @Test func aStopDuringTheSpeechPromptLeavesNoListen() async {
        let listener = SpeechListener()
        listener.askMic = { true }
        listener.askSpeech = { [listener] in
            listener.stop(send: false)
            return true
        }
        _ = await listener.start(hold: false)
        #expect(listener.state == .idle)
    }

    @Test func aRefusedMicStillSaysMicOff() async {
        let listener = SpeechListener()
        listener.askMic = { false }
        #expect(await listener.start(hold: false) == .micOff)
        #expect(listener.state == .idle)
    }
}
