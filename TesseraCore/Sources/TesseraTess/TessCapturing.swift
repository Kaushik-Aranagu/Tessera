import Foundation
import TesseraCore

/// Turns a typed or spoken phrase into typed actions, performed as pending previews (the ghost row).
/// This is the seam a future Tess AI team owns: swap the implementation, keep the contract.
@MainActor
public protocol TessCapturing {
    func capture(_ phrase: String, context: TessContext) async -> TessCapture
}

/// What Tess knows about the moment: today, and the workout and set in focus during live mode.
public struct TessContext: Sendable {
    public var now: Date
    public var calendar: Calendar
    /// The exercise entry in focus during live mode, for relative phrases ("same", "8", "drop to 70").
    public var entry: UUID?
    /// Set when the capture should commit immediately (e.g. a Shortcut) instead of showing a ghost row.
    public var commitImmediately: Bool
    /// The subject of the process running in Now (a workout, cook or the groceries list being shopped). The
    /// capture engine fills it in when it's not given.
    public var process: UUID?

    public init(now: Date = .now, calendar: Calendar = .current, entry: UUID? = nil, commitImmediately: Bool = false,
                process: UUID? = nil)
    {
        self.now = now
        self.calendar = calendar
        self.entry = entry
        self.commitImmediately = commitImmediately
        self.process = process
    }
}

/// The outcome of one capture.
public struct TessCapture {
    public enum Source: String, Sendable {
        /// The deterministic gym and task grammar: instant and offline.
        case grammar
        /// The on-device language model with registry tools.
        case model
        /// Claude, after the phone's own routes missed (shown with the cloud mark).
        case claude
        /// Nothing understood.
        case none
    }

    /// The logged actions, pending unless `commitImmediately` was set. Commit or discard them through the engine.
    public let records: [OpRecord]
    /// One line in Tess's voice: "Logged bench 3 × 10 at 80."
    public let line: String
    public let source: Source
    /// Set when Tess asked instead of writing: a guarded phrase's question, or the SQ8 ask with two answers.
    public let asking: Asking?

    public enum Asking: Sendable, Equatable {
        /// A question in the line only ("81: 81 kg, or 81 reps?"); his next phrase answers it.
        case line
        /// "2 × 10: 2 sets, or 2 kg?": answered by `TessCaptureEngine.answer(_:context:)` or by saying it.
        case setCount(TessSetCountAsk)
        /// "Bench 80 × 8 for Monday?": answered by `TessCaptureEngine.answer(_:context:)` (LOG or NOT NOW) or said.
        case datedLift(TessDatedLiftAsk)
    }

    /// A refusal that is its own answer ("Dal is already on Recipes."): the phrase never goes to the miss log.
    public var isRefusal = false

    /// The line is the first-send notice ("Sent that to Claude. Turn this off in Settings: Claude."): it is shown
    /// once and must never be replaced by another line.
    public var isNotice = false

    /// Nothing on the phone could read it and Claude was not there to: the phrase was kept as a note to sort later.
    /// It is still a miss for the week-one miss log, though the phrase is no longer lost.
    public var keptToSort = false

    public var understood: Bool {
        !records.isEmpty
    }

    public init(records: [OpRecord], line: String, source: Source, asking: Asking? = nil) {
        self.records = records
        self.line = line
        self.source = source
        self.asking = asking
    }
}

/// Tess's on-device instructions, from `docs/research/tess-voice.md`. Kept short on purpose: an 8K context and
/// persona drift both favour few, hard rules. Example lines belong in the eval set, not here.
public enum TessVoice {
    public static func instructions(today: String, currentWorkout: String, lastSet: String) -> String {
        """
        You are Tess, the assistant inside Tessera, a personal app.
        Voice: brief, warm, a little dry.
        Rules:
        - Reply in one line, under 12 words.
        - Lead with what you did, in past tense, then one number.
        - Use digits and the user's units. No emoji, no exclamation marks.
        - No greetings, sign-offs, praise words or apologies.
        - Use counts like "4 of the last 7". Never streaks, never "missed".
        - Never tell the user what they should do. Offer: "Want...?"
        - If unsure, say "Didn't catch that" and give your best guess as a question.
        - If you cannot do it, say so in one line and offer the nearest action.
        - Humour only after a finished action, and rarely.
        - Act only through the provided tools. Never claim an action you did not call.
        Context: \(today), \(currentWorkout), \(lastSet).
        """
    }

    /// Words Tess never uses (checked by tests and evals).
    public static let bannedWords = ["should", "must", "missed", "streak", "great", "awesome", "sorry", "oops"]

    /// The automatic checks from the tone eval: one line, under 12 words, no "!", no emoji, no banned words.
    public static func violations(in line: String) -> [String] {
        var problems: [String] = []
        let words = line.split(whereSeparator: \.isWhitespace)
        if words.count >= 12 {
            problems.append("\(words.count) words")
        }
        if line.contains("\n") {
            problems.append("more than one line")
        }
        if line.contains("!") {
            problems.append("exclamation mark")
        }
        if line.unicodeScalars.contains(where: \.properties.isEmojiPresentation) {
            problems.append("emoji")
        }
        let lower = line.lowercased()
        for word in bannedWords where lower.split(whereSeparator: { !$0.isLetter }).contains(Substring(word)) {
            problems.append("banned word \"\(word)\"")
        }
        return problems
    }

    static func number(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}
