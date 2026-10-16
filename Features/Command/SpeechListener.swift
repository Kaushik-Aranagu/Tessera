import AVFoundation
import Observation
import Speech

/// Tess's ears (docs/design/speak.md, Research's speak-first-use.md). On-device only: `requiresOnDeviceRecognition`
/// is always set, so the purpose strings stay true, and a language without on-device speech says so instead of
/// sending audio anywhere. Words stream into `heard`; a 1.2 s pause, a tap on the bloom, 60 s, or letting go of a
/// hold ends it. Nothing in the first 5 s ends it with nothing.
@MainActor @Observable
final class SpeechListener {
    enum State: Equatable {
        case idle
        /// Waiting on the system mic or speech alert.
        case asking
        case listening
    }

    /// Why listening can't start, each with Tess's one line (speak.md's table).
    enum Refusal: Equatable {
        case micOff, speechOff, noLanguage, busy

        var line: String {
            switch self {
            case .micOff: "Mic is off for Tessera."
            case .speechOff: "Speech is off for Tessera."
            case .noLanguage: "Voice isn't available in this language yet."
            case .busy: "The mic is busy with a call."
            }
        }

        /// The ink word after the line: Open Settings, or Write.
        var action: String {
            switch self {
            case .micOff, .speechOff: "Open Settings"
            case .noLanguage, .busy: "Write"
            }
        }
    }

    private(set) var state = State.idle
    /// The words so far, as the transcriber has them.
    private(set) var heard = ""
    /// Mic level, 0 … 1, for the bloom's breath.
    private(set) var level: Double = 0

    /// Called once when listening ends: the transcript, or nil when cancelled or nothing came.
    var onFinish: ((String?) -> Void)?
    /// Whether the last listen ended because no word came in the first 5 s.
    private(set) var endedInSilence = false

    static let pause: Duration = .milliseconds(1200)
    static let firstWord: Duration = .seconds(5)
    static let limit: Duration = .seconds(60)

    private enum ListenError: Error { case noInput }

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var timer: Task<Void, Never>?
    private var cap: Task<Void, Never>?
    private var holdMode = false

    /// Whether the mic can be used without asking (for the Speak word's state).
    static var micDenied: Bool {
        AVAudioApplication.shared.recordPermission == .denied
    }

    /// Starts listening, asking for the mic, then speech, the first time. Returns a refusal when it can't.
    func start(hold: Bool) async -> Refusal? {
        guard state == .idle else { return nil }
        holdMode = hold
        state = .asking
        guard await AVAudioApplication.requestRecordPermission() else {
            state = .idle
            return .micOff
        }
        let speech = await withCheckedContinuation { continuation in
            // Speech calls back on its own queue: the handler must not be main-actor (QA S2).
            SFSpeechRecognizer.requestAuthorization { @Sendable status in continuation.resume(returning: status) }
        }
        guard speech == .authorized else {
            state = .idle
            return .speechOff
        }
        guard let recognizer = SFSpeechRecognizer(locale: .current) ?? SFSpeechRecognizer(),
              recognizer.supportsOnDeviceRecognition, recognizer.isAvailable
        else {
            state = .idle
            return .noLanguage
        }
        do {
            try begin(with: recognizer)
        } catch {
            stopAudio()
            state = .idle
            return .busy
        }
        return nil
    }

    /// Ends listening. `send` false drops what was heard (a veil tap, a drag off the soul).
    func stop(send: Bool) {
        guard state == .listening || state == .asking else { return }
        let words = heard.trimmingCharacters(in: .whitespacesAndNewlines)
        stopAudio()
        state = .idle
        let finish = onFinish
        onFinish = nil
        finish?(send && !words.isEmpty ? words : nil)
    }

    private func begin(with recognizer: SFSpeechRecognizer) throws {
        heard = ""
        endedInSilence = false
        let session = AVAudioSession.sharedInstance()
        // .duckOthers needs playAndRecord (QA S1: with .record it throws, and every listen read as "busy").
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        // Touching inputNode with no input route aborts inside Core Audio (seen on the Simulator), so ask first.
        guard session.isInputAvailable else { throw ListenError.noInput }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true
        self.request = request
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format,
                         block: Self.tap(appendingTo: request) { [weak self] rms in
                             Task { @MainActor in self?.level = rms }
                         })
        engine.prepare()
        try engine.start()
        state = .listening
        task = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
            // Called on Speech's queue: take what's needed here, then hop to the main actor.
            let text = result?.bestTranscription.formattedString
            let done = error != nil || (result?.isFinal ?? false)
            Task { @MainActor in
                guard let self, self.state == .listening else { return }
                if let text, text != self.heard {
                    self.heard = text
                    self.armPause()
                }
                if done {
                    self.stop(send: true)
                }
            }
        }
        // Nothing in the first 5 s ends it with nothing; any listen ends at 60 s and sends.
        timer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.firstWord)
            guard let self, !Task.isCancelled, heard.isEmpty, !self.holdMode else { return }
            endedInSilence = true
            stop(send: false)
        }
        cap = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.limit)
            guard !Task.isCancelled else { return }
            self?.stop(send: true)
        }
    }

    /// A 1.2 s pause after the last word ends a tap-started listen (a hold ends on release).
    private func armPause() {
        timer?.cancel()
        guard !holdMode else { return }
        timer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.pause)
            guard !Task.isCancelled else { return }
            self?.stop(send: true)
        }
    }

    private func stopAudio() {
        timer?.cancel()
        cap?.cancel()
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// The tap runs on the audio thread, so it's built outside the main actor (QA S2).
    private nonisolated static func tap(appendingTo request: SFSpeechAudioBufferRecognitionRequest,
                                        level: @escaping @Sendable (Double) -> Void) -> AVAudioNodeTapBlock
    {
        { buffer, _ in
            request.append(buffer)
            level(rms(buffer))
        }
    }

    private nonisolated static func rms(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        var sum: Float = 0
        for index in 0 ..< Int(buffer.frameLength) {
            sum += data[index] * data[index]
        }
        let rms = sqrt(sum / Float(buffer.frameLength))
        return Double(min(max(rms * 12, 0), 1))
    }

    #if DEBUG
        /// `-speakScript` (read through LaunchFlags, so simulator only): plays words in as if heard, for recordings.
        func playScript(_ words: [String]) {
            state = .listening
            heard = ""
            Task { @MainActor in
                for word in words {
                    try? await Task.sleep(for: .milliseconds(380))
                    heard = heard.isEmpty ? word : heard + " " + word
                    level = Double.random(in: 0.3 ... 0.9)
                }
                try? await Task.sleep(for: Self.pause)
                state = .listening
                stop(send: true)
            }
        }
    #endif
}

/// What Tess does with a transcript before it's a capture: fillers squeezed out, spoken numbers made digits, and the
/// whole phrase "undo" or "take that back" recognised as UNDO.
enum SpokenPhrase {
    /// Not "like": "I'd like to" is a phrase (QA U1).
    static let fillers: Set<String> = ["um", "uh", "erm", "er", "hmm"]

    static func clean(_ heard: String) -> String {
        let words = heard.split(separator: " ").filter {
            !fillers.contains($0.lowercased().trimmingCharacters(in: .punctuationCharacters))
        }
        return words.joined(separator: " ")
    }

    static func isUndo(_ heard: String) -> Bool {
        let phrase = heard.lowercased().trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        return phrase == "undo" || phrase == "take that back"
    }
}
