import Foundation

/// What the Notes landing says (design 131, Product build sheet Oct 22). Facts only, computed on the phone: no counts
/// are drawn, no private note's words leave this file (a private note only sets `hasPrivate`), and a walled name is
/// masked before any template sees it. A read that fails returns empty, never crashes the launch.
@MainActor
public struct NotesLanding {
    public struct Thing: Equatable, Sendable {
        public let name: String
        /// Notes about the thing: the size it is drawn at, never shown as a number.
        public let weight: Int
        /// The three heaviest are drawn large.
        public let isLarge: Bool
    }

    public struct Margin: Equatable, Sendable {
        public enum Kind: Sendable { case waiting, new }
        public let kind: Kind
        public let sentence: LandingSentence
        /// The underlined link word of a waiting line ("Link them", "Make it a thing").
        public let action: String?
    }

    public struct Facts: Equatable, Sendable {
        public let hasNotes: Bool
        public let things: [Thing]
        public let hasLoose: Bool
        public let hasPrivate: Bool
        public let margin: [Margin]
        /// The book being read, last touched (absent when Reading has none).
        public let book: String?

        public var topNames: [String] {
            things.prefix(3).map(\.name)
        }
    }

    public struct Options: Sendable {
        /// notesMargin: the margin lines show at all.
        public var margin = true
        /// notesLinkSuggest: "Your note from Tue names Bench press. Link them".
        public var linkSuggest = false
        public var lastSeen: Date?
        public var now: Date = .now
        public var calendar: Calendar = .current

        public init(margin: Bool = true, linkSuggest: Bool = false, lastSeen: Date? = nil, now: Date = .now,
                    calendar: Calendar = .current)
        {
            self.margin = margin
            self.linkSuggest = linkSuggest
            self.lastSeen = lastSeen
            self.now = now
            self.calendar = calendar
        }
    }

    public static let maxThings = 12
    public static let largeThings = 3
    public static let maxMargin = 3

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Private by its flag or by its words (a secret, money or a body fact): the one rule every screen uses.
    func isPrivate(_ note: ObjectRecord) -> Bool {
        store.value("isPrivate", of: note) == .bool(true)
            || ObjectPrivacy.shownLabel(of: note, in: store, classes: classes) != nil
    }

    func notes() -> [ObjectRecord] {
        guard let noteClass = classes[.note] else { return [] }
        return store.objects(of: noteClass).filter { !$0.isDeleted }
    }

    func body(_ note: ObjectRecord) -> String {
        store.value("body", of: note)?.stringValue ?? note.title
    }

    func linked(_ note: ObjectRecord) -> [ObjectRecord] {
        store.linkedObjects("about", of: note).filter { !$0.isDeleted }
    }

    func shown(_ object: ObjectRecord) -> String? {
        ObjectPrivacy.isPrivateWord(object.title, in: store) ? nil : object.title
    }

    public func facts(_ options: Options = Options()) -> Facts {
        let all = notes()
        let open = all.filter { !isPrivate($0) }
        var weights: [UUID: (object: ObjectRecord, weight: Int, latest: Date)] = [:]
        var hasLoose = false
        for note in open {
            let links = linked(note)
            if links.isEmpty {
                hasLoose = true
            }
            for object in links where object.classDef?.id != classes[.note]?.id {
                var entry = weights[object.id] ?? (object, 0, .distantPast)
                entry.weight += 1
                entry.latest = max(entry.latest, note.updatedAt)
                weights[object.id] = entry
            }
        }
        let ordered = weights.values.compactMap { entry -> (name: String, weight: Int, latest: Date)? in
            shown(entry.object).map { ($0, entry.weight, entry.latest) }
        }
        .sorted { $0.weight != $1.weight ? $0.weight > $1.weight : $0.latest > $1.latest }
        .prefix(Self.maxThings)
        let things = ordered.enumerated().map { index, entry in
            Thing(name: entry.name, weight: entry.weight, isLarge: index < Self.largeThings)
        }
        let margin = options.margin ? marginLines(open: open, things: things, options: options) : []
        let book = classes[.book].flatMap { _ in
            Bookshelf(store: store, classes: classes).lastTouchedReading().flatMap(shown)
        }
        return Facts(
            hasNotes: !all.isEmpty,
            things: things,
            hasLoose: hasLoose,
            hasPrivate: all.contains(where: isPrivate),
            margin: margin,
            book: book
        )
    }

    // MARK: Margin

    func marginLines(open: [ObjectRecord], things: [Thing], options: Options) -> [Margin] {
        var waiting: [Margin] = []
        var fresh: [Margin] = []
        let weekday = DateFormatter()
        weekday.locale = Locale(identifier: "en_US")
        weekday.calendar = options.calendar
        weekday.timeZone = options.calendar.timeZone
        weekday.dateFormat = "EEE"
        let newestFirst = open.sorted { $0.createdAt > $1.createdAt }
        if options.linkSuggest {
            let names = things.map(\.name)
            for note in newestFirst {
                let text = body(note).lowercased()
                let linkedNames = Set(linked(note).map { $0.title.lowercased() })
                guard let name = names.first(where: { name in
                    !linkedNames.contains(name.lowercased()) && Self.contains(text, word: name.lowercased())
                }) else { continue }
                waiting.append(Margin(kind: .waiting, sentence: LandingSentences.notesNames(
                    day: weekday.string(from: note.createdAt), thing: name
                ), action: LandingSentences.linkThem))
                break
            }
        }
        if let word = unknownMention(in: newestFirst) {
            waiting.append(Margin(kind: .waiting, sentence: LandingSentences.notThingYet(word),
                                  action: LandingSentences.makeAThing))
        }
        if let seen = options.lastSeen {
            let newNotes = newestFirst.filter { $0.createdAt > seen }
            if !newNotes.isEmpty {
                var names: [String] = []
                for note in newNotes {
                    for object in linked(note) {
                        if let name = shown(object), !names.contains(name) {
                            names.append(name)
                        }
                    }
                }
                fresh.append(Margin(
                    kind: .new,
                    sentence: LandingSentences.newNotes(count: newNotes.count, about: names),
                    action: nil
                ))
            }
        }
        return Array((waiting + fresh).prefix(Self.maxMargin))
    }

    /// The first @word of a note that names nothing yet.
    func unknownMention(in notes: [ObjectRecord]) -> String? {
        let list = NoteList(store: store, classes: classes)
        for note in notes {
            let text = body(note)
            for match in text.matches(of: /@([A-Za-z][A-Za-z0-9'-]*)/) {
                let word = String(match.1)
                if list.resolve(word) == nil, !list.mentions(in: text).contains(where: {
                    $0.title.lowercased().hasPrefix(word.lowercased())
                }) {
                    return ObjectPrivacy.isPrivateWord(word, in: store) ? nil : word
                }
            }
        }
        return nil
    }

    static func contains(_ text: String, word: String) -> Bool {
        guard !word.isEmpty else { return false }
        var start = text.startIndex
        while let range = text.range(of: word, range: start ..< text.endIndex) {
            let before = range.lowerBound == text.startIndex ? nil : text[text.index(before: range.lowerBound)]
            let after = range.upperBound == text.endIndex ? nil : text[range.upperBound]
            if !(before?.isLetter ?? false), !(after?.isLetter ?? false), before != "@" {
                return true
            }
            start = range.upperBound
        }
        return false
    }
}
