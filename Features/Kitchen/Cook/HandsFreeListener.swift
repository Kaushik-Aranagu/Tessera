import AVFoundation
import Observation
import Speech
import SwiftUI

/// Where a hands-free cook's words come from: the microphone through on-device speech in the app, a script in tests
/// and in simulator recordings. Cumulative transcripts, as Speech gives them.
@MainActor
protocol HandsFreeSource: AnyObject {
    /// Starts, delivering the running transcript. Returns why it can't, when it can't.
    func start(onText: @escaping @MainActor (String) -> Void) async -> SpeechListener.Refusal?
    func stop()
}

/// The microphone, on device only (`requiresOnDeviceRecognition`): the cook phrases never leave the phone and never
/// go to Claude. The mic level is never read, so Low Power has nothing to feed (SPK:27).
@MainActor
final class MicHandsFreeSource: HandsFreeSource {
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start(onText: @escaping @MainActor (String) -> Void) async -> SpeechListener.Refusal? {
        guard await AVAudioApplication.requestRecordPermission() else { return .micOff }
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { @Sendable status in continuation.resume(returning: status) }
        }
        guard speech == .authorized else { return .speechOff }
        guard let recognizer = SFSpeechRecognizer(locale: .current) ?? SFSpeechRecognizer(),
              recognizer.supportsOnDeviceRecognition, recognizer.isAvailable else { return .noLanguage }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            guard session.isInputAvailable else { return .busy }
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            // Command words, not prose: the recogniser leans toward them.
            request.contextualStrings = ["next", "back", "timer", "note"]
            self.request = request
            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0),
                             block: Self.tap(appendingTo: request))
            engine.prepare()
            try engine.start()
            task = recognizer.recognitionTask(with: request) { @Sendable result, _ in
                guard let text = result?.bestTranscription.formattedString else { return }
                Task { @MainActor in onText(text) }
            }
        } catch {
            stop()
            return .busy
        }
        return nil
    }

    func stop() {
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private nonisolated static func tap(appendingTo request: SFSpeechAudioBufferRecognitionRequest)
        -> AVAudioNodeTapBlock
    {
        { buffer, _ in request.append(buffer) }
    }
}

/// Plays a script in as if it were heard: `-handsFreeScript "next|timer bread 8|back"` (read through LaunchFlags, so
/// the simulator only), and tests.
@MainActor
final class ScriptedHandsFreeSource: HandsFreeSource {
    private let phrases: [String]
    private let gap: Duration
    private var task: Task<Void, Never>?

    init(phrases: [String], gap: Duration = .milliseconds(1800)) {
        self.phrases = phrases
        self.gap = gap
    }

    func start(onText: @escaping @MainActor (String) -> Void) async -> SpeechListener.Refusal? {
        task = Task { @MainActor [phrases, gap] in
            var transcript = ""
            for phrase in phrases {
                try? await Task.sleep(for: gap)
                guard !Task.isCancelled else { return }
                transcript += (transcript.isEmpty ? "" : " ") + phrase
                onText(transcript)
            }
        }
        return nil
    }

    func stop() {
        task?.cancel()
    }
}

/// The listening window of a hands-free cook (Product, Oct 19): opened by his tap, no wake word, closed after 8 s of
/// silence or when he leaves the page, a visible mark while open, no sound of ours, one light tick on a heard command.
/// A command commits after a 400 ms trailing pause, not a full Speak's 1.2 s, because "back" undoes "next".
@MainActor @Observable
final class HandsFreeController {
    enum State: Equatable {
        case closed
        case asking
        case listening
    }

    private(set) var state = State.closed
    /// The cook word as heard, shown large in Tess's line for a moment ("next", "timer 8").
    private(set) var heard: String?
    /// "Listening" is spelled out on first use only, then the mark alone.
    private(set) var refusal: SpeechListener.Refusal?
    private(set) var cue = HapticCue()
    /// Whether the word "Listening" is spelled out (first use).
    var spellsOut: Bool {
        !UserDefaults.standard.bool(forKey: "handsFreeListeningSeen")
    }

    private var window = HandsFreeWindow()
    private let source: any HandsFreeSource
    private let session: CookClockSession
    private var pause: Task<Void, Never>?
    private var watch: Task<Void, Never>?
    private var clear: Task<Void, Never>?
    /// The most recent transcript, for the trailing pause.
    private var transcript = ""

    init(session: CookClockSession, source: (any HandsFreeSource)? = nil) {
        self.session = session
        self.source = source ?? Self.defaultSource()
    }

    static func defaultSource() -> any HandsFreeSource {
        if let script = LaunchFlags.value(after: "-handsFreeScript") {
            return ScriptedHandsFreeSource(phrases: script.split(separator: "|").map(String.init))
        }
        return MicHandsFreeSource()
    }

    var isOpen: Bool {
        state == .listening
    }

    /// His tap on the mark opens or closes the window.
    func toggle() async {
        if state == .closed {
            await open()
        } else {
            close()
        }
    }

    func open() async {
        guard state == .closed else { return }
        refusal = nil
        state = .asking
        let refused = await source.start { [weak self] text in self?.hear(text) }
        guard state == .asking else {
            source.stop()
            return
        }
        if let refused {
            state = .closed
            refusal = refused
            return
        }
        state = .listening
        window.open(at: AppClock.now)
        transcript = ""
        cue.play(.listening)
        UserDefaults.standard.set(true, forKey: "handsFreeListeningSeen")
        watch = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, state == .listening else { return }
                if window.isSilent(at: AppClock.now) {
                    close()
                    return
                }
            }
        }
    }

    /// Closes the window: 8 s of silence, a tap, leaving the page, the scene going inactive.
    func close() {
        guard state != .closed else { return }
        pause?.cancel()
        watch?.cancel()
        source.stop()
        window.close()
        state = .closed
    }

    private func hear(_ text: String) {
        guard state == .listening, window.newWords(in: text, at: AppClock.now) != nil else { return }
        transcript = text
        pause?.cancel()
        pause = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(HandsFreeWindow.trailingPause * 1000)))
            guard !Task.isCancelled else { return }
            self?.commit()
        }
    }

    private func commit() {
        let words = transcript.split(whereSeparator: \.isWhitespace)
        let heardNow = words.dropFirst(window.consumed).joined(separator: " ")
        window.commit(wordCount: words.count)
        let outcome = HandsFreeGrammar.parse(heardNow)
        guard outcome != .silent else { return }
        // A heard command is one light tick; the action's own haptic is held back inside the same moment.
        if case .command = outcome {
            cue.play(.selection)
        }
        show(heardNow, outcome: outcome)
        session.handle(outcome)
    }

    private func show(_ phrase: String, outcome: HandsFreeGrammar.Outcome) {
        if case .command = outcome {
            heard = String(phrase.prefix(40))
        } else {
            heard = nil
        }
        clear?.cancel()
        clear = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            if !Task.isCancelled {
                self?.heard = nil
            }
        }
    }
}
