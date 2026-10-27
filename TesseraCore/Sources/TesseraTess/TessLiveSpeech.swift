import AVFoundation
import Foundation
import Speech

/// A live listen on SpeechAnalyzer: words stream out as volatile text and settle as final text, the screen's names
/// prime the model, and nothing but text leaves this file (no audio, no timings, nothing written anywhere).
/// The caller owns the microphone and feeds `append(_:)`; this type converts to the analyzer's format.
public final class TessLiveSpeech: @unchecked Sendable {
    private let transcriber: SpeechTranscriber
    private let analyzer: SpeechAnalyzer
    private let format: AVAudioFormat
    private let builder: AsyncStream<AnalyzerInput>.Continuation
    private let input: AsyncStream<AnalyzerInput>
    private let lock = NSLock()
    private var converter: AVAudioConverter?
    private var results: Task<String, Error>?

    /// Nil when the on-device model can't run here (not downloaded, unsupported language): the caller falls back.
    public init?(locale: Locale = .current, onWords: @escaping @Sendable (String) -> Void) async {
        guard SpeechTranscriber.isAvailable,
              let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else { return nil }
        let transcriber = SpeechTranscriber(locale: supported, transcriptionOptions: [],
                                            reportingOptions: [.volatileResults], attributeOptions: [])
        guard await AssetInventory.status(forModules: [transcriber]) == .installed,
              let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else { return nil }
        self.transcriber = transcriber
        self.format = format
        analyzer = SpeechAnalyzer(modules: [transcriber])
        (input, builder) = AsyncStream.makeStream(of: AnalyzerInput.self)
        results = Task { [transcriber] in
            var settled = ""
            for try await result in transcriber.results {
                let text = String(result.text.characters)
                if result.isFinal {
                    settled += (settled.isEmpty ? "" : " ") + text.trimmingCharacters(in: .whitespaces)
                    onWords(settled)
                } else {
                    onWords(settled.isEmpty ? text : settled + " " + text)
                }
            }
            return settled
        }
    }

    /// Fetches Apple's on-device speech model for this language if it isn't installed, so the next listen streams.
    /// The system downloads it; no audio or text is involved. Safe to call on every launch; it returns at once when
    /// the model is there or the language is unsupported.
    public static func installModelIfNeeded(locale: Locale = .current) async {
        guard SpeechTranscriber.isAvailable,
              let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else { return }
        let transcriber = SpeechTranscriber(locale: supported, transcriptionOptions: [],
                                            reportingOptions: [.volatileResults], attributeOptions: [])
        guard let request = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber]) else { return }
        try? await request.downloadAndInstall()
    }

    /// Primes the model with the names on screen. Safe to skip; a failure only costs the priming.
    public func prime(with strings: [String]) async {
        guard !strings.isEmpty else { return }
        let context = AnalysisContext()
        context.contextualStrings[.general] = strings
        try? await analyzer.setContext(context)
    }

    public func start() async throws {
        try await analyzer.start(inputSequence: input)
    }

    /// Called from the audio thread.
    public func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        let source = buffer.format
        if source == format {
            builder.yield(AnalyzerInput(buffer: buffer))
            return
        }
        if converter == nil { converter = AVAudioConverter(from: source, to: format) }
        guard let converter else { return }
        let ratio = format.sampleRate / source.sampleRate
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64)
        else { return }
        var fed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if fed { status.pointee = .noDataNow; return nil }
            fed = true
            status.pointee = .haveData
            return buffer
        }
        if error == nil, out.frameLength > 0 { builder.yield(AnalyzerInput(buffer: out)) }
    }

    /// Ends the audio, lets the model settle the last words and returns the final text.
    public func finish() async -> String {
        builder.finish()
        try? await analyzer.finalizeAndFinishThroughEndOfInput()
        return (try? await results?.value) ?? ""
    }

    /// Drops everything heard.
    public func cancel() async {
        builder.finish()
        results?.cancel()
        await analyzer.cancelAndFinishNow()
    }
}
