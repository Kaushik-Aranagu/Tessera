import Foundation
import TesseraCore

// Living looks, Tess's side (Design sheets 286 and 287; docs/ai/harness/element-looks.md). A look is a setting, so
// Tess changes one with a shell call (`setLook`), never a tool: no ghost row, nothing of his touched; the shell plays
// sheet 285's wash, the travel and the Undo line. The frame is the same in every look, so nothing here reads or
// changes `ElementMeaning`. A short ask that names one form or one trait step on the place he means is bound with no
// model ("the doors as an index", "calmer sky", "denser", "as drawn"); anything open ("I don't like this dial") goes
// to the model with the place's look lines, and a form she picks is staged off screen first. She never changes a look
// he didn't ask about.

/// The words he changes looks with.
public enum LookWords {
    /// The look shell calls.
    public static let calls: Set<String> = ["setLook", "showLooks"]

    /// Words that name a place ("the doors", "the sky").
    static let places: [String: ElementPlace] = [
        "dial": .dial, "doors": .dial, "keystone": .keystone, "board": .keystone, "blackboard": .keystone,
        "rail": .keystone, "tickets": .keystone, "woods": .keystone, "sky": .keystone, "mosaic": .keystone,
        "chart": .keystone, "wall": .keystone, "widget": .widget, "summary": .doorSummary, "needs": .needs,
        "switcher": .switcher, "glyph": .glyph, "rows": .page, "page": .page,
    ]

    /// Words that put a place back as the studio drew it.
    static let back = ["as drawn", "as it was", "how it was", "original look", "old look", "the default"]
    /// Words that ask to see the forms (shape mode on that place).
    static let browse = ["other looks", "what looks", "show me the looks", "other ways to show", "other forms",
                         "what forms", "reshape"]
    /// Words that mean he's talking about how something looks.
    static let about: Set<String> = ["look", "looks", "drawn", "style", "layout", "ugly", "cluttered", "form", "forms",
                                     "shape", "reshape"]
    /// Words that carry nothing in a short look ask ("make it a bit calmer").
    static let fillers: Set<String> = ["make", "it", "this", "that", "a", "bit", "little", "please", "lot", "much",
                                       "be", "can", "you", "the", "way"]

    /// A look ask, read against one place.
    public struct Read: Equatable, Sendable {
        public var place: ElementPlace?
        /// He named the place ("the doors"), rather than the frame aiming at it.
        public var named: Bool
        /// The one change his words name: the longest phrase wins, so "one sentence" beats "sentence".
        public var change: LookChange?
        public var browse: Bool
        public var everywhere: Bool
        /// Nothing in the ask but the change and filler, so a bare "denser" binds to the place he touched while
        /// "add bigger plates" never does.
        public var bare: Bool
    }

    /// Reads an ask against one place's forms and traits. `fallback` is where the frame aims when he names no place;
    /// `looks` gives the values a trait steps from.
    public static func read(_ ask: String, aimedAt fallback: ElementPlace?, room: String, looks: RoomLooks) -> Read {
        let words = TessFrame.words(ask)
        let named = words.compactMap { places[$0] }.first
        let place = named ?? fallback
        let everywhere = words.contains("everywhere") || ToolPicker.contains(words, ["every", "room"])
            || ToolPicker.contains(words, ["all", "rooms"]) || (words.contains("every") && named != nil)
        let browsing = browse.contains { ToolPicker.contains(words, TessFrame.words($0)) }
        guard let place else {
            return Read(place: nil, named: false, change: nil, browse: browsing, everywhere: everywhere, bare: false)
        }
        let key = place.rawValue
        let current = looks.look(room: room, place: key)
        var offers: [(phrase: String, change: LookChange)] = back.map { (phrase: $0, change: LookChange.designed) }
        for form in LookCatalog.forms(for: key, room: everywhere ? nil : room) {
            offers += form.phrases.map { (phrase: $0, change: LookChange.form(form.name)) }
        }
        for trait in LookCatalog.traits(for: key, form: everywhere ? nil : current.form) {
            let value = current.traits[trait.name] ?? trait.designed
            offers += trait.named.map { (phrase: $0.key, change: LookChange.trait(trait.name, $0.value)) }
            if let up = trait.step(value, by: 1) {
                offers += trait.up.map { (phrase: $0, change: LookChange.trait(trait.name, up)) }
            }
            if let down = trait.step(value, by: -1) {
                offers += trait.down.map { (phrase: $0, change: LookChange.trait(trait.name, down)) }
            }
        }
        let hit = offers.filter { ToolPicker.contains(words, TessFrame.words($0.phrase)) }
            .max { $0.phrase.count < $1.phrase.count }
        let spent = Set(TessFrame.words(hit?.phrase ?? ""))
        let bare = hit != nil && words.allSatisfy { spent.contains($0) || fillers.contains($0) }
        return Read(place: place, named: named != nil, change: hit?.change, browse: browsing, everywhere: everywhere,
                    bare: bare)
    }

    /// Whether the ask is about looks at all.
    public static func isAbout(_ ask: String) -> Bool {
        let words = TessFrame.words(ask)
        let phrases = back + browse + ["don't like", "as a", "as an"]
        return !about.isDisjoint(with: words) || phrases.contains { ToolPicker.contains(words, TessFrame.words($0)) }
    }

    /// A change as `setLook`'s arguments: a form, the studio's ("designed"), or a trait and its value.
    public static func arguments(_ change: LookChange) -> [String: String] {
        switch change {
        case let .form(id): ["form": id]
        case .designed: ["form": "designed"]
        case let .trait(name, value): ["trait": name, "value": value]
        }
    }

    /// `setLook`'s arguments as a change, or nil when they name none.
    public static func change(_ arguments: [String: String]) -> LookChange? {
        if let form = arguments["form"], !form.isEmpty {
            return form == "designed" ? .designed : .form(form)
        }
        if let trait = arguments["trait"], let value = arguments["value"] {
            return .trait(trait, value)
        }
        return nil
    }

    /// Whether `setLook`'s arguments name a change this place can take somewhere: the shell still checks the room
    /// (`RoomLooks.applying`).
    public static func isKnown(_ change: LookChange, place: String) -> Bool {
        let forms = LookCatalog.places[place]?.forms.map(\.form) ?? []
        switch change {
        case let .form(id):
            return forms.contains(id)
        case .designed:
            return !forms.isEmpty
        case let .trait(name, value):
            let traits = forms.flatMap { LookCatalog.traits(for: place, form: $0) }
            return traits.contains { $0.name == name && $0.values.contains(value) }
        }
    }
}

extension ToolPicker {
    /// The most words a look ask may have and still run with no model ("show the doors as an index").
    static let lookMaxWords = 8

    /// A short look ask on one place, filled from the frame: the place he named, else the one he touched, else "this".
    /// Shown places only. Nil when it needs the model (no place, no one change named, one this room can't take). It
    /// binds only when the ask is about looks, names the place, or is nothing but the change: "quiet hours at 10"
    /// never quiets anything.
    static func lookBound(_ ask: String, frame: TessFrame, about: Bool, looks: RoomLooks) -> Bound? {
        guard TessFrame.words(ask).count <= lookMaxWords else { return nil }
        let read = LookWords.read(ask, aimedAt: lookTarget(frame: frame), room: frame.room, looks: looks)
        guard about || read.named || read.bare, let place = read.place,
              frame.element(place)?.isShown ?? false else { return nil }
        if let change = read.change {
            var arguments = ["place": place.rawValue, "scope": read.everywhere ? "everywhere" : "room",
                             "room": frame.room]
            arguments.merge(LookWords.arguments(change)) { _, new in new }
            return Bound(call: "setLook", place: place, object: nil, arguments: arguments)
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
    /// The look lines for an ask about looks: per shown place, its form and traits now, and what else it could take.
    /// They come from his settings, not from the frame, so the frame stays the same in every look.
    public func lookLines(_ looks: RoomLooks) -> [PackFragment] {
        elements.filter(\.isShown).compactMap { element in
            let place = element.place.rawValue
            guard LookCatalog.isLiving(place, room: room) else { return nil }
            let now = looks.look(room: room, place: place)
            let others = LookCatalog.forms(for: place, room: room).map(\.name).filter { $0 != now.form }
            let traits = LookCatalog.traits(for: place, form: now.form).map { trait in
                "\(trait.name) \(now.traits[trait.name] ?? trait.designed) of \(trait.values.joined(separator: "/"))"
            }
            var line = "Look of \(place): \(now.form ?? "designed")"
            if !others.isEmpty {
                line += "; other forms \(others.joined(separator: ", "))"
            }
            if !traits.isEmpty {
                line += "; traits \(traits.joined(separator: ", "))"
            }
            return PackFragment(line + ".")
        }
    }
}
