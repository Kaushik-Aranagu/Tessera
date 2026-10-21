import AVFoundation
import Foundation

/// Tess saying a short line aloud (the Cook timer voice switch). A protocol so tests listen to a spy, never a speaker.
@MainActor
protocol CookSpeaking {
    func say(_ line: String)
}

/// The real voice: the system synthesizer, in the user's language, ducking other audio only while it speaks. It says
/// the timer's name and nothing else ("Simmer is done."); the line was already walled (a private label reads "Timer").
@MainActor
final class TessSpeech: NSObject, CookSpeaking {
    static let shared = TessSpeech()
    private let synthesizer = AVSpeechSynthesizer()

    func say(_ line: String) {
        let utterance = AVSpeechUtterance(string: line)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.prefersAssistiveTechnologySettings = true
        // A timer end replaces whatever was being said: the newest line is the true one.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }
}
