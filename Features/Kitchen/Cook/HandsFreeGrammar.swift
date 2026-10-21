import Foundation
import TesseraCore

/// What a heard phrase means in a hands-free cook (docs/design/motion/tess-cook-parallel-steps-and-hands-free-motion.md
/// Part 2). A grammar, nothing more: it makes no network request, never goes to Claude, and talk with no cook word in
/// it gets no reply at all.
enum HandsFreeGrammar {
    enum Command: Equatable {
        case next
        case back
        /// "timer 8", "timer bread 8", "8 minute timer": `label` nil is the plain "Timer".
        case timer(minutes: Double, label: String?)
        /// "note: less salt" writes the cook's note for next time (CN-E5).
        case note(String)
    }

    enum Outcome: Equatable {
        /// No cook word: say nothing, show nothing.
        case silent
        case command(Command)
        /// A cook word with nothing it can act on ("timer" with no number): "Didn't catch that."
        case didntCatch
        /// Key-shaped text, or a phrase over 600 characters: refused first, nothing acts, nothing logged.
        case refused(Reason)
    }

    enum Reason: Equatable {
        case tooLong, keyShaped

        var line: String {
            switch self {
            case .tooLong: "That's too long to send. Say it shorter."
            case .keyShaped: "Didn't catch that."
            }
        }
    }

    static let maxLength = 600
    /// "next" and "back" are short commands: past this many words the phrase is talk, not a command.
    static let maxCommandWords = 4
    static let fillers: Set<String> = ["ok", "okay", "hey", "tess", "please", "now", "um", "uh", "and"]
    static let nextWords: Set<String> = ["next", "continue", "forward"]
    static let backWords: Set<String> = ["back", "previous"]

    static func parse(_ phrase: String) -> Outcome {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .silent }
        guard trimmed.count <= maxLength else { return .refused(.tooLong) }
        if let refusal = TessMemoryScreen.refusal(for: trimmed), refusal == .looksLikeKey || refusal == .secret {
            return .refused(.keyShaped)
        }
        let lower = trimmed.lowercased()
        var words = lower.split { !$0.isLetter && !$0.isNumber && $0 != "." }.map(String.init)
        while let first = words.first, fillers.contains(first) {
            words.removeFirst()
        }
        guard let head = words.first else { return .silent }

        if head == "note" {
            // "note: less salt" keeps the words as spoken, minus the cue.
            let body = trimmed.drop { $0 != ":" && !$0.isWhitespace }.drop { $0 == ":" || $0.isWhitespace }
            let text = String(body).trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? .didntCatch : .command(.note(String(text.prefix(280))))
        }
        if words.count <= maxCommandWords {
            if nextWords.contains(head), words.dropFirst().allSatisfy({ ["step", "one", "please"].contains($0) }) {
                return .command(.next)
            }
            if backWords.contains(head), words.dropFirst().allSatisfy({ ["step", "one", "please"].contains($0) }) {
                return .command(.back)
            }
            if head == "go", words.count == 2, words[1] == "back" {
                return .command(.back)
            }
        }
        if words.contains("timer") {
            return timer(words)
        }
        return .silent
    }

    /// "timer 8", "timer bread 8", "timer 8 minutes", "8 minute timer", "bread timer 8".
    private static func timer(_ words: [String]) -> Outcome {
        guard words.count <= 8, let at = words.firstIndex(of: "timer") else { return .silent }
        let units: Set = ["min", "mins", "minute", "minutes", "m"]
        let numbers = words.enumerated().compactMap { index, word -> (Int, Double)? in
            Double(word).map { (index, $0) }
        }
        guard let (numberIndex, minutes) = numbers.first, minutes > 0,
              minutes <= RecipeParser.maxTimerMinutes else { return .didntCatch }
        let rest = words.enumerated().filter { index, word in
            index != at && index != numberIndex && !units.contains(word) && !fillers.contains(word)
                && !["for", "a", "an", "the", "of", "set", "start"].contains(word)
        }.map(\.element)
        let label = rest.isEmpty ? nil : rest.joined(separator: " ").capitalizedFirst
        return .command(.timer(minutes: minutes, label: label))
    }
}

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

/// The listening window's rules, apart from the microphone so they test without one: opened by his tap, closed after
/// 8 s of silence, a command commits after a 400 ms trailing pause, every command is a new moment (Product, Oct 19).
struct HandsFreeWindow: Equatable {
    static let silence: TimeInterval = 8
    static let trailingPause: TimeInterval = 0.4

    private(set) var isOpen = false
    private(set) var lastHeardAt: Date?
    private(set) var openedAt: Date?
    /// Words of the running transcript already acted on, so a revised transcript never acts twice.
    private(set) var consumed = 0

    mutating func open(at now: Date) {
        isOpen = true
        openedAt = now
        lastHeardAt = now
        consumed = 0
    }

    mutating func close() {
        isOpen = false
    }

    /// The new words in a cumulative transcript, nil when nothing new. Marks them heard.
    mutating func newWords(in transcript: String, at now: Date) -> String? {
        let words = transcript.split(whereSeparator: \.isWhitespace)
        guard isOpen, words.count > consumed else { return nil }
        lastHeardAt = now
        return words[consumed...].joined(separator: " ")
    }

    /// Called once the pause has passed and the phrase was acted on (or ignored).
    mutating func commit(wordCount: Int) {
        consumed = wordCount
    }

    /// Whether 8 s of silence have passed since a word was heard (or since opening).
    func isSilent(at now: Date) -> Bool {
        guard isOpen, let last = lastHeardAt else { return false }
        return now.timeIntervalSince(last) >= Self.silence
    }

    /// When the window will close if nothing more is heard.
    var closesAt: Date? {
        lastHeardAt.map { $0.addingTimeInterval(Self.silence) }
    }
}
