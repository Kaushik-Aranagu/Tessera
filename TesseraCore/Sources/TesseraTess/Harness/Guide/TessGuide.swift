import Foundation
import TesseraCore

/// Tess's guide to herself and the app (docs/ai/harness/guide.md): short pages built from the same catalogs the
/// screens and tools are built from, read with one tool, `guide`. A path reads a page ("/calls/pauseRoutine"); words
/// search the pages ("how do I pause"). Every page ends with the paths it leads to, so she pages in only what an ask
/// needs (progressive disclosure: the contents line rides in the pack, a page on a call, a deeper page on a follow).
///
/// The guide is what the app is, never his data, so every page is claude-safe under strict too. `TessGuideTests` fails
/// when a room, place, call, form, trait or tool has no page, so the book can't fall behind the app.
@MainActor
public enum TessGuide {
    /// Nonisolated, with `aboutPhrases` and `isAbout`, because the tool picker reads them off the main actor.
    public nonisolated static let name = "guide"
    /// The most one answer holds.
    public static let maxCharacters = 1200
    /// The most pages one search lists.
    static let maxHits = 6

    public struct Page: Sendable, Equatable {
        public var path: String
        /// One line: what the page is about, as contents and search hits show it.
        public var title: String
        public var body: String
    }

    /// The ship names of the rooms, by the catalog's keys.
    static let roomNames: [String: String] = [
        "bridge": "Bridge (Home)", "log": "Log (Notes and Lists)", "lookout": "Lookout (Weather)",
        "deck": "Deck (Training)", "galley": "Galley (Kitchen)", "watch": "Watch (Routines)", "purse": "Purse (Money)",
    ]

    /// The pack's line (tier 1): what the guide holds, in one line, so she knows what to page in.
    public static let contentsLine = "Your guide (call guide with a path or words): /you who you are and your limits, "
        + "/rules his house rules, /rooms each room's places and calls, /places, /calls what each call does, "
        + "/looks forms and traits, /tools every tool"

    // MARK: Tool

    public static var spec: ToolSpec {
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["path"],
            "properties": [
                "path": [
                    "type": "string",
                    "description": "A page path like /calls/pauseRoutine, or words to search for, like how to pause.",
                ],
            ],
        ]
        return ToolSpec(name: name, description: "Read your guide to yourself and the app: rooms, places, calls, "
            + "looks, tools and his rules. Read it before saying how something in the app works; read only.",
            schema: (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8))
    }

    /// The text the tool returns: the page at a path, or the pages that best fit the words.
    public static func run(arguments: Data) -> (text: String, isError: Bool) {
        let object = (try? JSONSerialization.jsonObject(with: arguments)) as? [String: Any]
        let asked = (object?["path"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !asked.isEmpty else { return ("Say a path or what to look for.", true) }
        if asked.hasPrefix("/") {
            let path = asked.count > 1 && asked.hasSuffix("/") ? String(asked.dropLast()) : asked
            if let page = book[path] {
                return (clip(page.body), false)
            }
            let near = search(path.split(separator: "/").joined(separator: " "))
            return (clip((["No page there."] + near.map { "\($0.path): \($0.title)" }).joined(separator: "\n")), true)
        }
        let hits = search(asked)
        guard !hits.isEmpty else { return ("Nothing in the guide fits. Contents: /", true) }
        return (clip(hits.map { "\($0.path): \($0.title)" }.joined(separator: "\n")), false)
    }

    static func clip(_ text: String) -> String {
        text.count > maxCharacters ? String(text.prefix(maxCharacters - 1)) + "…" : text
    }

    // MARK: Search

    /// Words that say nothing about which page.
    static let filler: Set<String> = [
        "a", "an", "the", "i", "me", "my", "you", "your", "do", "does", "did", "how", "what", "where", "why", "when",
        "can", "could", "is", "are", "it", "this", "that", "to", "of", "in", "on", "for", "with", "and", "or", "be",
        "work", "works", "use", "app", "tess",
    ]

    /// Lowercased words, camel case split ("pauseRoutine" is "pause routine"), filler dropped, a plural's "s" off.
    static func words(_ text: String) -> Set<String> {
        var spaced = ""
        for character in text {
            if character.isUppercase, let last = spaced.last, last.isLowercase {
                spaced.append(" ")
            }
            spaced.append(character)
        }
        let raw = spaced.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        return Set(raw.map { $0.count > 3 && $0.hasSuffix("s") && !$0.hasSuffix("ss") ? String($0.dropLast()) : $0 }
            .filter { !filler.contains($0) })
    }

    /// The pages whose path and title share the most words with the ask, then their body; ties go to the shorter path.
    static func search(_ text: String) -> [Page] {
        let asked = words(text)
        guard !asked.isEmpty else { return [] }
        let scored: [(page: Page, score: Int)] = book.values.map { page in
            let head = words(page.path + " " + page.title)
            let body = words(page.body)
            return (page, asked.reduce(0) { $0 + (head.contains($1) ? 3 : body.contains($1) ? 1 : 0) })
        }
        return scored.filter { $0.score > 0 }
            .sorted { ($1.score, $0.page.path.count, $0.page.path) < ($0.score, $1.page.path.count, $1.page.path) }
            .prefix(maxHits).map(\.page)
    }

    // MARK: Asks about the app

    /// Asks about how the app or Tess works ("how do I pause a routine", "what does the dial do"): the picker offers
    /// the guide on these. "Why is my bench stuck" is about his training, not the app, so a bare "why is" is not one.
    nonisolated static let aboutPhrases = [
        "how do i", "how can i", "how does", "how do you", "what does", "what can you", "what can i", "what do you",
        "where is", "where do i", "where can i", "why did you", "why do you", "what is this", "what's this",
        "who are you", "what are you", "is there a way", "help me understand",
    ]

    public nonisolated static func isAbout(_ ask: String) -> Bool {
        let spaced = " " + ask.lowercased().split { !$0.isLetter && $0 != "'" }.joined(separator: " ") + " "
        return aboutPhrases.contains { spaced.contains(" \($0) ") }
    }

    // MARK: The book

    /// Every page by path, built once from the catalogs.
    public static let book: [String: Page] = build()

    static func build() -> [String: Page] {
        var pages: [Page] = [you, rules]
        pages += roomPages() + placePages() + callPages() + lookPages() + toolPages()
        let shelves: [(String, String)] = [
            ("/rooms", "The rooms"), ("/places", "The places of every room's screen"), ("/calls", "Every call"),
            ("/looks", "Forms and traits a place can take"), ("/tools", "Every tool you may be offered"),
        ]
        for (shelf, title) in shelves {
            // Names only, grouped by folder, so a shelf of 40 tools still fits one answer.
            var folders: [String: [String]] = [:]
            for page in pages where page.path.hasPrefix(shelf + "/") {
                let parts = page.path.split(separator: "/")
                folders["/" + parts.dropLast().joined(separator: "/"), default: []].append(String(parts.last ?? ""))
            }
            let lines = folders.keys.sorted().map { folder in
                "\(folder)/<name> for: \((folders[folder] ?? []).sorted().joined(separator: ", "))"
            }
            pages.append(Page(path: shelf, title: title, body: ([title] + lines).joined(separator: "\n")))
        }
        pages.append(Page(path: "/", title: "Contents", body: contentsLine))
        return Dictionary(pages.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
    }

    static var you: Page {
        Page(path: "/you", title: "Who you are, your rungs, the Door and your limits", body: """
        You are Tess, his assistant inside Tessera. You speak for every room; each room also has its own agent, \
        which you ask with ask_agent
        Rungs: rules and short commands run with no model, then the phone's own model, then Haiku, then Sonnet \
        for open asks. The smallest that fits answers
        The Door: under strict, his money, health, body, calorie and calendar things stay on the phone; under lab \
        they may reach Claude. Money actions are never offered to Claude. A private thing shows only by its label. \
        His key is never seen or sent
        Changes: every change you make lands pending, as a ghost row with Undo for 10 seconds. At most \
        \(TessTools.maxRecordsPerPhrase) changes per ask, \(TessRun.maxRounds) rounds and \(ToolPicker.maxTools) \
        tools
        Memory: recall, open, links and history read his things and what you know about him; remember keeps a \
        maybe he keeps or dismisses
        More: /rules, /tools, /rooms
        """)
    }

    static var rules: Page {
        Page(path: "/rules", title: "His house rules for the app", body: """
        Weeks start Monday
        Undo lasts 10 seconds everywhere
        Swipe right means Done; swipe left means Not now
        Money amounts are never red or green, and an undone money change reads Reversed. No money on the Bridge
        Shown lines end with no full stop; notes and documents keep theirs. Sentence case
        Sample data never touches his real things
        More: /you
        """)
    }

    static func roomPages() -> [Page] {
        ElementCatalog.rooms.keys.sorted().map { room in
            let shown = roomNames[room] ?? room
            var lines = ["\(shown): what each place offers you"]
            for place in ElementPlace.allCases {
                let calls = ElementCatalog.calls(room: room, place: place).map(\.name)
                if !calls.isEmpty {
                    lines.append("\(place.rawValue): \(calls.joined(separator: ", "))")
                }
            }
            lines.append("More: /calls/<name>, /places/<place>, /looks")
            return Page(path: "/rooms/\(room)", title: shown, body: lines.joined(separator: "\n"))
        }
    }

    static func placePages() -> [Page] {
        ElementPlace.allCases.map { place in
            var lines = [placeWords(place)]
            let rooms = ElementCatalog.rooms.keys.sorted().filter { room in
                !ElementCatalog.calls(room: room, place: place).isEmpty
            }
            if !rooms.isEmpty {
                lines.append("Offers calls in: \(rooms.map { roomNames[$0] ?? $0 }.joined(separator: ", "))")
            }
            if let forms = LookCatalog.places[place.rawValue]?.forms, !forms.isEmpty {
                lines.append("Forms: \(forms.map(\.form).joined(separator: ", ")); read /looks/forms/<form>")
            }
            return Page(path: "/places/\(place.rawValue)", title: placeWords(place),
                        body: lines.joined(separator: "\n"))
        }
    }

    /// What each place of the standing shell is (docs/design/shell-contract-283.md).
    static func placeWords(_ place: ElementPlace) -> String {
        switch place {
        case .title: "The title: the room's name at the top"
        case .navWord: "The nav word: the word that goes back one level"
        case .switcher: "The switcher: the window word, like Today, Tomorrow or This week"
        case .needs: "The needs: the update rows under the title, what wants him now"
        case .doorTitle: "The door title: the name of the door page that is open"
        case .keystone: "The keystone: the room's own picture at the top, live at every level"
        case .caption: "The caption: the line under the keystone"
        case .widget: "The widget: the one thing that matters now, with its glyph"
        case .glyph: "The glyph: the widget's small drawing"
        case .dial: "The dial: the room's doors, on the right under his thumb"
        case .doorSummary: "The door summary: the focused door's line, on the left"
        case .page: "The page: a door's rows once it is open"
        case .actionWord: "The action word: the room's verb, bottom left"
        case .tess: "Tess: you, bottom right"
        }
    }

    static func callPages() -> [Page] {
        let specs = specsByName()
        return ElementCatalog.everyCall.map { call in
            // The same call can sit on several places with other words ("walk" is createTask on the Lookout).
            var phrases: [String] = []
            var offered: [String] = []
            for room in ElementCatalog.rooms.keys.sorted() {
                let places = ElementPlace.allCases.filter { place in
                    let here = ElementCatalog.calls(room: room, place: place).filter { $0.name == call.name }
                    for phrase in here.flatMap(\.phrases) where !phrases.contains(phrase) {
                        phrases.append(phrase)
                    }
                    return !here.isEmpty
                }
                if !places.isEmpty {
                    offered.append("\(roomNames[room] ?? room) \(places.map(\.rawValue).joined(separator: ", "))")
                }
            }
            let what = TessTools.tool(named: call.name)?.description ?? specs[call.name]?.description ?? call.name
            var lines = ["\(call.name): \(what)"]
            lines.append(call.kind == .tool
                ? "Writes his things as you, pending: a ghost row with Undo 10 s"
                : "Changes only what is shown; writes nothing")
            if !call.inputs.isEmpty {
                let inputs = call.inputs.map { input in
                    "\(input.name) (\(sourceWords(input.source))\(input.required ? "" : ", optional"))"
                }
                lines.append("Inputs: \(inputs.joined(separator: ", "))")
            }
            if !phrases.isEmpty {
                lines.append("Words that name it: \(phrases.joined(separator: ", "))")
            }
            if !call.kinds.isEmpty {
                lines.append("Acts on: \(call.kinds.sorted().joined(separator: ", "))")
            }
            lines.append("On screen: \(reactionWords(call.reaction))")
            lines.append(call.reach == .deviceOnly
                ? "Runs on the phone only, never Claude (money)" : "Any rung may run it")
            if !offered.isEmpty {
                lines.append("Offered: \(offered.joined(separator: "; "))")
            }
            lines.append("More: /tools/\(call.name)")
            return Page(path: "/calls/\(call.name)", title: what, body: lines.joined(separator: "\n"))
        }
    }

    static func sourceWords(_ source: InputSource) -> String {
        switch source {
        case .asked: "his words"
        case .referent: "the thing he means by this"
        case .window: "the switcher's window"
        case .door: "the dial's door"
        case .now: "the moment he asked"
        }
    }

    static func reactionWords(_ reaction: Reaction) -> String {
        switch reaction {
        case .strike: "the Big line is struck, with Undo 10 s"
        case .next: "the item leaves and the next rises in"
        case .keystoneTakes: "the keystone takes it its own way"
        case .reform: "the glyph collapses to a point and forms again"
        case .navigate: "a door page or the item opens"
        case .lines: "the needs or door summary change in place"
        case .tessLine: "nothing moves; your line says it"
        case .reshape: "the place takes its new form or trait"
        }
    }

    static func lookPages() -> [Page] {
        var pages = ElementForms.all.map { form in
            let places = LookCatalog.places.keys.sorted().filter { place in
                LookCatalog.places[place]?.forms.contains { $0.form == form.name } == true
            }
            var lines = ["\(form.name): \(form.summary)"]
            lines.append("Draws: \(form.draws.map(\.rawValue).sorted().joined(separator: ", "))")
            if !places.isEmpty {
                lines.append("Places that take it: \(places.joined(separator: ", "))")
            }
            if !form.phrases.isEmpty {
                lines.append("Words that name it: \(form.phrases.joined(separator: ", "))")
            }
            if !form.traits.isEmpty {
                lines.append("Its traits: \(form.traits.map(\.name).joined(separator: ", "))")
            }
            lines.append("Change it with setLook; showLooks lets him swipe through them")
            return Page(path: "/looks/forms/\(form.name)", title: form.summary, body: lines.joined(separator: "\n"))
        }
        // A trait name can mean more than one thing ("shows" is the glyph on a widget, the line on an action word).
        var traits: [String: [String]] = [:]
        let placeTraits = LookCatalog.places.keys.sorted().flatMap { place in
            (LookCatalog.places[place]?.traits ?? []).map { (place, $0) }
        }
        let formTraits = ElementForms.all.flatMap { form in form.traits.map { (form.name, $0) } }
        for (owner, trait) in placeTraits + formTraits {
            let line = "On \(owner): \(trait.summary). Values: \(trait.values.joined(separator: ", ")); "
                + "designed: \(trait.designed)"
            if traits[trait.name]?.contains(line) != true {
                traits[trait.name, default: []].append(line)
            }
        }
        pages += traits.keys.sorted().map { name in
            Page(path: "/looks/traits/\(name)", title: "The \(name) trait",
                 body: (["\(name)"] + (traits[name] ?? []) + ["Change it with setLook"]).joined(separator: "\n"))
        }
        return pages
    }

    static func toolPages() -> [Page] {
        specsByName().values.sorted { $0.name < $1.name }.map { spec in
            var lines = ["\(spec.name): \(spec.description)"]
            let json = (try? JSONSerialization.jsonObject(with: spec.schema)) as? [String: Any]
            if let properties = json?["properties"] as? [String: Any], !properties.isEmpty {
                let inputs = properties.keys.sorted().map { key in
                    let about = (properties[key] as? [String: Any])?["description"] as? String
                    return about.map { "\(key) (\($0))" } ?? key
                }
                lines.append("Takes: \(inputs.joined(separator: "; "))")
            }
            if TessTools.tool(named: spec.name)?.deviceOnly == true {
                lines.append("The phone only, never Claude (money)")
            }
            return Page(path: "/tools/\(spec.name)", title: spec.description, body: lines.joined(separator: "\n"))
        }
    }

    /// Every tool she may be offered: Claude's tools, the phone-only ones, `open`, recall, the shell, and the guide.
    static func specsByName() -> [String: ToolSpec] {
        var specs: [String: ToolSpec] = [:]
        for spec in TessRun.toolSpecs() + TessRun.shellSpecs() where specs[spec.name] == nil {
            specs[spec.name] = spec
        }
        for tool in TessTools.all where specs[tool.name] == nil {
            let schema = (try? JSONSerialization.data(withJSONObject: tool.input.json, options: [.sortedKeys]))
                ?? Data("{}".utf8)
            specs[tool.name] = ToolSpec(name: tool.name, description: tool.description, schema: schema)
        }
        return specs
    }
}
