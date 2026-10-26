import Foundation
import TesseraCore

// Living elements, Tess's side (docs/ai/harness/element-looks.md). Every place's look is in her frame when he talks
// about looks; a short nudge on the place he means ("denser", "as a list", "calmer", "as it was") is bound and runs
// with no model; anything open ("I don't like this dial") goes to the model with the place's look line and the two
// tools, and she tries a look he can undo. She never reshapes anything he didn't ask about.

extension LookInfo {
    /// From the resolved look, as the room and the shell read it.
    @MainActor
    public static func make(_ scope: LookScope, shape: ContentShape, designed: String, store: ObjectStore,
                            classes: [SystemCatalog.Key: ClassDef]) -> LookInfo?
    {
        guard let look = ElementLooks.look(scope, shape: shape, designed: designed, store: store, classes: classes)
        else { return nil }
        let forms = ElementForms.forms(place: scope.place, room: scope.room, shape: shape, designed: designed)
        return LookInfo(scope: scope, shape: shape, form: look.form.name, designed: designed,
                        forms: forms.map { $0.name }, traits: look.traits, isChanged: look.isChanged)
    }
}

/// The words he reshapes with.
public enum LookWords {
    public enum Change: Equatable, Sendable {
        case form(String)
        /// One step along a trait's words ("denser" is +1 density).
        case step(String, by: Int)
        case set(String, to: String)
        case restore
    }

    /// The look tools, bound only through `ToolPicker.lookBound`.
    public static let calls: Set<String> = ["reshape", "restoreLook"]

    /// "as a list", "like a wall", "into an index": the word after names the form.
    static let formNames: [String: String] = [
        "list": "rows", "rows": "rows", "wall": "wall", "index": "index", "reel": "reel", "ledger": "ledger",
        "stack": "stack", "line": "trace", "trace": "trace", "type": "type", "tickets": "tickets", "chalk": "chalk",
        "woods": "woods", "sky": "sky", "chart": "chart", "mosaic": "mosaic",
    ]

    static let nudges: [(phrase: String, change: Change)] = [
        ("denser", .step("density", by: 1)), ("tighter", .step("density", by: 1)),
        ("more compact", .step("density", by: 1)), ("airier", .step("density", by: -1)),
        ("looser", .step("density", by: -1)), ("more space", .step("density", by: -1)),
        ("bigger", .step("size", by: 1)), ("larger", .step("size", by: 1)), ("smaller", .step("size", by: -1)),
        ("calmer", .step("motion", by: -1)), ("less motion", .step("motion", by: -1)),
        ("quieter", .step("motion", by: -1)), ("stop moving", .set("motion", to: "still")),
        ("stop animating", .set("motion", to: "still")), ("keep it still", .set("motion", to: "still")),
        ("more motion", .set("motion", to: "designed")), ("livelier", .set("motion", to: "designed")),
        ("more detail", .step("facts", by: 1)), ("less detail", .step("facts", by: -1)),
        ("just names", .set("facts", to: "none")), ("show more", .step("count", by: 1)),
        ("show fewer", .step("count", by: -1)), ("one at a time", .form("rise")),
        ("as drawn", .restore), ("as it was", .restore), ("how it was", .restore), ("original look", .restore),
        ("old look", .restore),
    ]

    /// Words that name a place ("the dial", "the board").
    static let places: [String: ElementPlace] = [
        "dial": .dial, "doors": .dial, "keystone": .keystone, "board": .keystone, "blackboard": .keystone,
        "rail": .keystone, "tickets": .keystone, "woods": .keystone, "sky": .keystone, "mosaic": .keystone,
        "chart": .keystone, "wall": .keystone, "widget": .widget, "caption": .caption, "needs": .needs,
        "title": .title, "glyph": .glyph, "list": .page, "rows": .page, "page": .page,
    ]

    /// Words that mean he is talking about how something looks, so the frame carries the look lines.
    static let lookWords: Set<String> = ["look", "looks", "drawn", "style", "reshape", "layout", "ugly", "cluttered",
                                         "cramped"]

    /// What a short ask changes: the form, trait steps or sets, or the studio's look back; the place it names; and
    /// whether he said every room.
    public static func read(_ ask: String) -> (changes: [Change], place: ElementPlace?, everywhere: Bool) {
        let words = TessFrame.words(ask)
        var changes: [Change] = []
        var formWords: Set<Int> = []
        for (index, word) in words.enumerated() where ["as", "like", "into"].contains(word) {
            var next = index + 1
            if words.indices.contains(next), ["a", "an", "the"].contains(words[next]) {
                next += 1
            }
            if words.indices.contains(next), let form = formNames[words[next]] {
                changes.append(.form(form))
                formWords.insert(next)
            }
        }
        for nudge in nudges where ToolPicker.contains(words, TessFrame.words(nudge.phrase)) {
            if !changes.contains(nudge.change) {
                changes.append(nudge.change)
            }
        }
        let place = words.enumerated().first { !formWords.contains($0.offset) && places[$0.element] != nil }
            .flatMap { places[$0.element] }
        let everywhere = words.contains("everywhere") || ToolPicker.contains(words, ["every", "room"])
            || ToolPicker.contains(words, ["all", "rooms"]) || (words.contains("every") && place != nil)
        return (changes, place, everywhere)
    }

    /// Whether the ask is about looks at all.
    public static func isAbout(_ ask: String) -> Bool {
        let words = TessFrame.words(ask)
        return !read(ask).changes.isEmpty || !lookWords.isDisjoint(with: words)
            || ToolPicker.contains(words, ["don't", "like"])
    }
}

extension ToolPicker {
    /// The most words a look nudge may have and still run with no model ("show the dial as a list").
    static let lookMaxWords = 8

    /// A short look nudge on one place, filled from the frame: the place he named, else the one he touched, else
    /// "this". Nil when it needs the model (no place, more than one change, a form that can't draw this content, a
    /// trait already at its end).
    static func lookBound(_ ask: String, frame: TessFrame) -> Bound? {
        let words = TessFrame.words(ask)
        guard words.count <= lookMaxWords else { return nil }
        let read = LookWords.read(ask)
        // "Bigger" alone, "make it denser", or a place named; "log a bigger set" is not about a look.
        let aimed = read.place != nil || words.count <= 3 || contains(words, ["make", "it"])
            || contains(words, ["make", "this"]) || contains(words, ["make", "the"])
        guard aimed, read.changes.count == 1, let change = read.changes.first,
              let element = lookTarget(read.place, frame: frame), let look = element.look
        else { return nil }
        var arguments = ["place": element.place.rawValue, "room": read.everywhere ? "" : frame.room]
        switch change {
        case .restore:
            return Bound(call: "restoreLook", place: element.place, object: nil, arguments: arguments)
        case let .form(name):
            guard look.forms.contains(name), name != look.form else { return nil }
            arguments["form"] = name
        case let .step(name, offset):
            guard let trait = ElementForms.form(look.form)?.trait(name), let now = look.traits[name],
                  let next = trait.step(now, by: offset) else { return nil }
            arguments["trait"] = name
            arguments["value"] = next
        case let .set(name, value):
            guard let trait = ElementForms.form(look.form)?.trait(name), trait.values.contains(value),
                  look.traits[name] != value else { return nil }
            arguments["trait"] = name
            arguments["value"] = value
        }
        return Bound(call: "reshape", place: element.place, object: nil, arguments: arguments)
    }

    /// The place a look ask means: one he named, the one he touched in the last 30 s, then "this"'s place. Shown
    /// places only, and only ones with a look.
    static func lookTarget(_ named: ElementPlace?, frame: TessFrame) -> ElementMeaning? {
        let shown = frame.elements.filter { $0.isShown && $0.look != nil }
        if let named {
            return shown.first { $0.place == named }
        }
        if let touch = frame.touch, frame.now.timeIntervalSince(touch.at) <= TessFrame.touchWindow,
           let touched = shown.first(where: { $0.place == touch.place })
        {
            return touched
        }
        if let place = frame.referent()?.place {
            return shown.first { $0.place == place }
        }
        return nil
    }
}

// MARK: - Tools

@MainActor
extension TessTools {
    static var reshape: Tool {
        Tool(name: "reshape",
             description: "Change how a place on screen looks: the form it takes, or a trait (density, size, motion, "
                 + "facts, order, count). Only forms and words from the place's look line. Never changes his things.",
             input: .object([
                 ("place", .string("The place: widget, keystone, dial, page, caption, needs, title, glyph")),
                 ("room", .nullable(.string("The room (bridge, log, lookout, deck, galley, watch, purse); null for "
                         + "every room"))),
                 ("level", .nullable(.string("landing or door to change only one; null for both"))),
                 ("form", .nullable(.string("A form the look line says it could be; null to keep the form"))),
                 ("traits", .array(.object([("name", .string("A trait from the look line")),
                                            ("value", .string("One of its words"))]))),
             ]))
        { args, call in
            let scope = try LookScope(room: args["room"] as? String ?? "", place: args.string("place"),
                                      level: args["level"] as? String ?? "")
            let kept = ElementLooks.stored(scope, store: call.store, classes: call.engine.classes)
            var traits = kept.traits
            for pair in args["traits"] as? [[String: Any]] ?? [] {
                if let name = pair["name"] as? String, let value = pair["value"] as? String {
                    traits[name] = value
                }
            }
            // A bound nudge carries one trait flat.
            if let name = args["trait"] as? String, let value = args["value"] as? String {
                traits[name] = value
            }
            let form = (args["form"] as? String)?.lowercased() ?? kept.form
            // A new form keeps only the traits it takes.
            if let chosen = ElementForms.form(form) {
                traits = traits.filter { chosen.trait($0.key) != nil }
            }
            guard form != kept.form || traits != kept.traits else {
                throw TessToolAnswer(line: "It already looks that way.")
            }
            return try [call.perform(SetElementLook(scope: scope, form: form, traits: traits))]
        }
    }

    static var restoreLook: Tool {
        Tool(name: "restoreLook", description: "Put a place back to how the studio drew it",
             input: .object([
                 ("place", .string("The place")),
                 ("room", .nullable(.string("The room; null for every room"))),
                 ("level", .nullable(.string("landing or door; null for both"))),
             ]))
        { args, call in
            let scope = try LookScope(room: args["room"] as? String ?? "", place: args.string("place"),
                                      level: args["level"] as? String ?? "")
            let kept = ElementLooks.stored(scope, store: call.store, classes: call.engine.classes)
            guard !kept.form.isEmpty || !kept.traits.isEmpty else {
                throw TessToolAnswer(line: "It's already as drawn.")
            }
            return try [call.perform(RestoreElementLook(scope: scope))]
        }
    }
}
