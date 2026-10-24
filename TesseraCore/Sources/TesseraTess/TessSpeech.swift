import Foundation
import Speech

/// What a listen came back with. Only the final text ever leaves this file: no audio, no partials, no timings.
public enum TessHeard: Equatable, Sendable {
    case text(String)
    /// The on-device model can't run, so the UI shows the Ask field instead. Nothing is sent anywhere.
    case unavailable(TessListenGap)
    case nothingHeard
}

/// Why listening can't start. Every case falls back to the Ask field; none falls back to a server or to Siri.
public enum TessListenGap: Equatable, Sendable {
    /// This language's on-device model isn't downloaded yet. The app may offer the download; we never fetch it here.
    case modelNotDownloaded
    case unsupported
    case failed

    /// One plain line for the Ask field's placeholder.
    public var line: String {
        switch self {
        case .modelNotDownloaded: "Listening needs the on-device speech model. Type it for now."
        case .unsupported: "This phone can't listen on its own. Type it for now."
        case .failed: "Couldn't listen. Type it for now."
        }
    }
}

/// The on-device recogniser behind a seam, so the rules are tested without a microphone.
public protocol TessSpeechEngine: Sendable {
    func gap() async -> TessListenGap?
    /// Runs until the audio ends; returns the final text only.
    func finalText(from audio: AsyncStream<AnalyzerInput>) async throws -> String
}

public enum TessSpeech {
    /// Listen once. Checks the model first and never downloads it; audio is consumed and dropped by the engine, and
    /// only the trimmed final text comes back. Nothing here writes to the store, the log or the op log.
    public static func listen(
        engine: any TessSpeechEngine,
        audio: AsyncStream<AnalyzerInput>
    ) async -> TessHeard {
        if let gap = await engine.gap() {
            return .unavailable(gap)
        }
        do {
            let text = try await engine.finalText(from: audio).trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? .nothingHeard : .text(text)
        } catch {
            return .unavailable(.failed)
        }
    }
}

/// SpeechAnalyzer with the SpeechTranscriber module, on the device only. There is no server recogniser here, no
/// dictation fallback and no Siri path. Only results marked final are kept.
public struct TessOnDeviceSpeech: TessSpeechEngine {
    private let locale: Locale

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func gap() async -> TessListenGap? {
        guard SpeechTranscriber.isAvailable,
              let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else { return .unsupported }
        let module = SpeechTranscriber(locale: supported, preset: .transcription)
        switch await AssetInventory.status(forModules: [module]) {
        case .installed: return nil
        case .unsupported: return .unsupported
        default: return .modelNotDownloaded
        }
    }

    public func finalText(from audio: AsyncStream<AnalyzerInput>) async throws -> String {
        guard let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            throw CancellationError()
        }
        let transcriber = SpeechTranscriber(locale: supported, preset: .transcription)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let collecting = Task {
            var finals: [String] = []
            for try await result in transcriber.results where result.isFinal {
                finals.append(String(result.text.characters))
            }
            return finals.joined(separator: " ")
        }
        do {
            if let last = try await analyzer.analyzeSequence(audio) {
                try await analyzer.finalizeAndFinish(through: last)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            return try await collecting.value
        } catch {
            collecting.cancel()
            throw error
        }
    }
}
