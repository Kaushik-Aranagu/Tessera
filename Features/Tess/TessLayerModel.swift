import Foundation
import Observation
import TesseraCore
import TesseraTess

/// The running conversation in Tess's layer (sheet 215 rev 5 to 16). The turns persist through Core's
/// `TessConversation` (on this phone only, seven days, never in a backup); what this model holds in memory (the lines
/// on screen, an unsent draft, what is being said) clears when the layer closes.
@MainActor @Observable
final class TessLayerModel {
    struct Line: Identifiable, Equatable {
        let id: UUID
        let role: TessConversation.Role
        let text: String
        let date: Date
        /// The shown labels in `text` that are doors (weight 500, never broken across lines).
        var names: [String]
        /// Who answered this line of hers: Claude or the phone's own routes (nil for lines she says first).
        var answeredBy: AnswerSource?
    }

    /// Who answered a reply, for the one small line under it on her sheet.
    enum AnswerSource: Equatable {
        case claude, phone
        /// The phone answered because there is no Claude key: say so and where to add one.
        case phoneNoKey

        /// The capture's source: Claude only when Claude answered; the grammar, the on-device model, a routed write
        /// or a miss kept on the phone are all this phone.
        init(_ source: TessCapture.Source?) {
            self = source == .claude ? .claude : .phone
        }

        /// As above, but with no key stored the phone's answer says why Claude did not answer.
        init(_ source: TessCapture.Source?, keyPresent: Bool) {
            self = source == .claude ? .claude : (keyPresent ? .phone : .phoneNoKey)
        }

        /// Plain small text, sentence case, no full stop.
        var line: String {
            switch self {
            case .claude: "Answered by Claude"
            case .phone: "Answered on this phone"
            case .phoneNoKey: "No Claude key yet, so this stayed on the phone. Add one in Settings > Claude"
            }
        }
    }

    /// Whether Claude is behind her, in two plain words for her sheet and the corner (the key's presence only).
    static func statusLine(keyPresent: Bool) -> String {
        keyPresent ? "Claude is on" : "No key yet"
    }

    /// Today's earlier turns, oldest first, then the newest exchange.
    private(set) var lines: [Line] = []
    /// At most three plain replies she offers under her line.
    private(set) var replies: [String] = []
    /// The marker above the opening line: "Now, 1:31 pm" after 20 minutes or more.
    private(set) var openingMarker: String?
    /// The newest line of hers whose words are still arriving.
    private(set) var arriving: UUID?
    /// A word that brightens (ink2 to ink) because her newest line named it again.
    private(set) var echo: (line: UUID, name: String)?
    /// The reply just picked: it flashes cobalt for 0.22 s before she acts.
    private(set) var picked: String?
    /// The state line in ink 3: "Listening", "Quiet until 2:30 pm", or nothing.
    var stateLine = ""
    var draft = ""
    /// Live words while he speaks (28 pt Light), cleared on release.
    var liveSpeech = ""
    /// "Quiet for an hour": she does not speak first until then.
    private(set) var quietUntil: Date?

    private var conversation: TessConversation?
    private var lastTurnAt: Date?

    static let pickFlashSeconds: TimeInterval = 0.22

    // MARK: Opening

    /// Opens the conversation: today's earlier turns from the store, then her opening line and at most three replies.
    func open(engine: ActionEngine, classes: [SystemCatalog.Key: ClassDef], facts: MosaicFacts?, now: Date = .now) {
        let conversation = TessConversation(store: engine.store, classes: classes)
        self.conversation = conversation
        conversation.expire(now: now)
        let last = conversation.lastTessTurn()
        lastTurnAt = conversation.turns().last?.createdAt
        lines = conversation.turns().map { turn in
            Line(id: turn.id, role: conversation.role(of: turn), text: conversation.text(of: turn),
                 date: turn.createdAt, names: conversation.about(turn).compactMap { $0.title.isEmpty ? nil : $0.title })
        }
        openingMarker = TessTimeMarker.openingMarker(last: lastTurnAt, now: now)
        guard let facts,
              let opening = TessOpener.opening(engine: engine, facts: facts, plan: nil, lastTurn: last,
                                               quiet: QuietHours.current, quietUntil: quietUntil)
        else {
            replies = []
            return
        }
        // She never repeats a line of hers: if the last thing she said is this very line and he has not answered, it is
        // already there.
        if lines.last?.role == .tess, lines.last?.text == opening.line {
            arriving = nil
        } else {
            say(opening.line, names: [], at: now)
        }
        replies = opening.replies
    }

    /// Everything on screen clears: the lines, the draft, what was being said. The turns stay in the store.
    func close() {
        lines = []
        replies = []
        draft = ""
        liveSpeech = ""
        stateLine = ""
        arriving = nil
        echo = nil
        picked = nil
        openingMarker = nil
    }

    // MARK: Turns

    /// What he said (typed, picked or spoken): stored filtered, shown as he said it.
    func hear(_ text: String, about: [ObjectRecord] = [], at date: Date = .now) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let row = conversation?.append(role: .user, text: clean, about: about, at: date)
        lines.append(Line(id: row?.id ?? UUID(), role: .user, text: clean, date: date, names: []))
        replies = []
        draft = ""
        lastTurnAt = date
    }

    /// One line of hers: stored, shown with its words arriving, and the earlier mention of a name in it brightens.
    func say(_ text: String, names: [String], about: [ObjectRecord] = [], at date: Date = .now,
             answeredBy: AnswerSource? = nil)
    {
        let row = conversation?.append(role: .tess, text: text, about: about, at: date)
        let line = Line(id: row?.id ?? UUID(), role: .tess, text: text, date: date, names: names,
                        answeredBy: answeredBy)
        let earlier = lines.map(\.text)
        lines.append(line)
        arriving = line.id
        lastTurnAt = date
        if let found = TessEcho.earlierMention(of: names, in: earlier) {
            echo = (lines[found.line].id, found.name)
        } else {
            echo = nil
        }
    }

    /// At most three plain replies under her newest line.
    func offer(_ options: [String]) {
        replies = Array(options.prefix(3))
    }

    /// Her line has finished arriving.
    func arrived(_ id: UUID) {
        if arriving == id {
            arriving = nil
        }
    }

    // MARK: Replies

    /// He picked one of her replies: it flashes, becomes his line, and she answers. "That's all" closes the layer
    /// (returns true).
    func choose(_ reply: String, answer: (String) -> String?) async -> Bool {
        picked = reply
        try? await Task.sleep(for: .seconds(Self.pickFlashSeconds))
        picked = nil
        hear(reply)
        if Self.closes(reply) {
            return true
        }
        if let line = answer(reply) {
            say(line, names: [])
        }
        return false
    }

    static func closes(_ reply: String) -> Bool {
        let plain = reply.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return plain == "that's all" || plain == "thats all" || plain == "thanks"
    }

    // MARK: Quiet

    func quietForAnHour(now: Date = .now) {
        quietUntil = now.addingTimeInterval(3600)
    }

    func wake() {
        quietUntil = nil
    }

    func isQuiet(now: Date = .now) -> Bool {
        quietUntil.map { $0 > now } ?? false
    }
}
