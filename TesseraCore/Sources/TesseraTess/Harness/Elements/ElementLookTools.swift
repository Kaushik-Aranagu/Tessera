import Foundation
import TesseraCore

// Living looks, Tess's side (Design sheet 286; docs/ai/harness/element-looks.md). A look is a setting, so Tess changes
// one with a shell call (`setLook`), never a tool: no ghost row, nothing of his touched; the shell plays sheet 285's
// wash, the swap and the Undo line. The frame is the same in every look, so nothing here reads or changes
// `ElementMeaning`. A short ask that names one look on the place he means is bound with no model ("the doors as a
// column", "quieter sky", "as drawn"); anything open ("I don't like this dial") goes to the model with the place's
// looks. She never changes a look he didn't ask about.

/// The words he changes looks with.
public enum LookWords {
    /// The look shell calls.
    public static let calls: Set<String> = ["setLook", "showLooks"]

    /// Words that name a place ("the doors", "the sky").
    static let places: [String: ElementPlace] = [
        "dial": .dial, "doors": .dial, "keystone": .keystone, "board": .keystone, "blackboard": .keystone,
        "rail": .keystone, "tickets": .keystone, "woods": .keystone, "sky": .keystone, "mosaic": .keystone,
        "chart": .keystone, "wall": .keystone, "widget": .widget, "summary": .doorSummary, "needs": .needs,
        "switcher": .switcher, "glyph": .glyph, "rows": .page, "page": .page, "tess": .tess,
    ]

    /// Words that put a place back as the studio drew it.
    static let back = ["as drawn", "as it was", "how it was", "original look", "old look", "the default"]
    /// Words that ask to see the looks (Layout mode on that pane).
    static let browse = ["other looks", "what looks", "show me the looks", "other ways to show"]
    /// Words that mean he's talking about how something looks.
    static let about: Set<String> = ["look", "looks", "drawn", "style", "layout", "ugly", "cluttered"]

    /// A look ask, read: the place he named (or the one aimed at), the look he named on it, and every room.
    public struct Read: Equatable, Sendable {
        public var place: ElementPlace?
        /// He named the place ("the doors"), rather than the frame aiming at it.
        public var named: Bool
        public var look: String?
        public var browse: Bool
        public var everywhere: Bool
    }

    /// Reads an ask against one place's looks. `fallback` is where the frame aims when he names no place.
    public static func read(_ ask: String, aimedAt fallback: ElementPlace?, room: String) -> Read {
        let words = TessFrame.words(ask)
        let named = words.compactMap { places[$0] }.first
        let place = named ?? fallback
        let everywhere = words.contains("everywhere") || ToolPicker.contains(words, ["every", "room"])
            || ToolPicker.contains(words, ["all", "rooms"]) || (words.contains("every") && named != nil)
        let browsing = browse.contains { ToolPicker.contains(words, TessFrame.words($0)) }
        guard let place else {
            return Read(place: nil, named: false, look: nil, browse: browsing, everywhere: everywhere)
        }
        let looks = LookCatalog.looks(for: place.rawValue, room: everywhere ? "" : room)
        var look: String?
        if back.contains(where: { ToolPicker.contains(words, TessFrame.words($0)) }) {
            look = looks.first?.id
        } else {
            // The longest phrase wins, so "one sentence" beats "sentence".
            let hits = looks.flatMap { def in def.phrases.map { (id: def.id, phrase: $0) } }
                .filter { ToolPicker.contains(words, TessFrame.words($0.phrase)) }
                .sorted { $0.phrase.count > $1.phrase.count }
            look = hits.first?.id
        }
        return Read(place: place, named: named != nil, look: look, browse: browsing, everywhere: everywhere)
    }

    /// Whether the ask is about looks at all.
    public static func isAbout(_ ask: String) -> Bool {
        let words = TessFrame.words(ask)
        let phrases = back + browse + ["don't like", "as a", "as an", "quieter", "calmer"]
        return !about.isDisjoint(with: words) || phrases.contains { ToolPicker.contains(words, TessFrame.words($0)) }
    }
}

extension ToolPicker {
    /// The most words a look ask may have and still run with no model ("show the doors as a column").
    static let lookMaxWords = 8

    /// A short look ask on one place, filled from the frame: the place he named, else the one he touched, else "this".
    /// Shown places only. Nil when it needs the model (no place, no one look named, a look this room can't show).
    /// It binds only when the ask is about looks or names the place: "quiet hours at 10" never quiets the widget.
    static func lookBound(_ ask: String, frame: TessFrame, about: Bool) -> Bound? {
        guard TessFrame.words(ask).count <= lookMaxWords else { return nil }
        let read = LookWords.read(ask, aimedAt: lookTarget(frame: frame), room: frame.room)
        guard about || read.named, let place = read.place, frame.element(place)?.isShown ?? false else { return nil }
        if let look = read.look {
            let scope = read.everywhere ? "everywhere" : "room"
            return Bound(call: "setLook", place: place, object: nil,
                         arguments: ["place": place.rawValue, "look": look, "scope": scope, "room": frame.room])
        }
        if read.browse {
            return Bound(call: "showLooks", place: place, object: nil, arguments: ["place": place.rawValue])
        }
        return nil
    }

    /// The place a look ask means when he names none: the one he touched in the last 30 s, then "this"'s place.
    static func lookTarget(frame: TessFrame) -> ElementPlace? {
        if let touch = frame.touch, frame.now.timeIntervalSince(touch.at) <= TessFrame.touchWindow,
           frame.element(touch.place)?.isShown ?? false
        {
            return touch.place
        }
        return frame.referent()?.place
    }
}

extension TessFrame {
    /// The look lines for an ask about looks: per shown place, what it shows now and what it could show. They come
    /// from his settings, not from the frame, so the frame stays the same in every look.
    public func lookLines(_ looks: RoomLooks) -> [PackFragment] {
        elements.filter(\.isShown).compactMap { element in
            let place = element.place.rawValue
            let all = LookCatalog.looks(for: place, room: room)
            guard all.count > 1 else { return nil }
            let now = looks.look(room: room, place: place)
            let name = all.first { $0.id == now }?.name ?? now
            let others = all.filter { $0.id != now }.map { "\($0.name) (\($0.id))" }
            return PackFragment("Look of \(place): \(name); could be \(others.joined(separator: ", ")).")
        }
    }
}
