import SwiftUI
import TesseraCore

/// Together (sheet 135, Kaushik's pick Oct 22, 4:21 PM PT): the apps remember each other. Every piece rides its own
/// Review switch on the Together page, default Off; Off is the app as it was. Privacy walls are unchanged, and no
/// line about money, health, body or calories goes to any model.
enum Together {
    static let daySentence = "daySentence"
    static let linkColours = "linkColours"
    static let writeAnywhere = "writeAnywhere"
    static let oneHands = "oneHands"
    static let occasions = "occasions"
    static let makeAKind = "makeAKind"

    @MainActor static func isOn(_ id: String) -> Bool {
        ReviewChoices.shared.value(of: id) == "On"
    }
}

/// The app an object lives in, by its class: its name and its one accent (Theme.Colors.Accent, 131 table).
enum HomeApp: String, CaseIterable {
    case training = "Training", kitchen = "Kitchen", money = "Money", notes = "Notes", lists = "Lists"
    case routines = "Routines"

    var accent: Color {
        switch self {
        case .training: Theme.Colors.Accent.training
        case .kitchen: Theme.Colors.Accent.kitchen
        case .money: Theme.Colors.Accent.money
        case .notes: Theme.Colors.Accent.notes
        case .lists: Theme.Colors.Accent.lists
        case .routines: Theme.Colors.Accent.routines
        }
    }

    /// The app whose classes the object's class descends from; nil for a plain thing.
    @MainActor
    static func of(_ object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> HomeApp? {
        guard let classDef = object.classDef else { return nil }
        let homes: [(SystemCatalog.Key, HomeApp)] = [
            (.activity, .training), (.workout, .training), (.exerciseEntry, .training), (.set, .training),
            (.muscle, .training), (.equipment, .training), (.plan, .training),
            (.routine, .routines),
            (.ingredient, .kitchen), (.recipe, .kitchen), (.cook, .kitchen), (.place, .kitchen),
            (.spend, .money), (.pool, .money), (.inflow, .money), (.poolMove, .money),
            (.note, .notes),
            (.list, .lists), (.listItem, .lists),
        ]
        return homes.first { key, _ in
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }?.1
    }

    /// The noun a "Mentioned in" line counts in: "3 notes", "2 workouts".
    func count(_ number: Int) -> String {
        let noun = switch self {
        case .training: number == 1 ? "workout" : "workouts"
        case .kitchen: number == 1 ? "recipe" : "recipes"
        case .money: number == 1 ? "spend" : "spends"
        case .notes: number == 1 ? "note" : "notes"
        case .lists: number == 1 ? "list" : "lists"
        case .routines: number == 1 ? "routine" : "routines"
        }
        return "\(number) \(noun)"
    }
}

/// "Mentioned in" (135 §3): what links to an object, one line per app other than its own. Read from the store's
/// backlinks until Core's `ObjectStore.mentions(of:)` lands; then this reads that. A private or walled object has no
/// Mentioned in at all, and a walled source counts but is never named.
@MainActor
enum Mentions {
    struct Line: Identifiable, Equatable {
        let app: HomeApp
        /// "3 notes", or the one source's title.
        let text: String

        var id: String {
            app.rawValue
        }
    }

    static func lines(of object: ObjectRecord, store: ObjectStore,
                      classes: [SystemCatalog.Key: ClassDef]) -> [Line]
    {
        guard ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) == nil else { return [] }
        let home = HomeApp.of(object, classes: classes)
        var byApp: [HomeApp: [ObjectRecord]] = [:]
        for source in store.backlinks(to: object) where !source.isDeleted {
            guard let app = HomeApp.of(source, classes: classes) else { continue }
            byApp[app, default: []].append(source)
        }
        // Only its own app mentions it: nothing to say.
        guard byApp.keys.contains(where: { $0 != home }) else { return [] }
        return HomeApp.allCases.compactMap { app in
            guard app != home, let sources = byApp[app], !sources.isEmpty else { return nil }
            if sources.count == 1, let only = sources.first {
                let shown = ObjectPrivacy.shownLabel(of: only, in: store, classes: classes) ?? store.displayTitle(of: only)
                return Line(app: app, text: shown)
            }
            return Line(app: app, text: app.count(sources.count))
        }
    }
}

/// The "Mentioned in" lines above an object page's doors: what mentions it, with the app name small on the right.
struct MentionedIn: View {
    let lines: [Mentions.Line]

    var body: some View {
        if !lines.isEmpty {
            MarginSection(label: "Mentioned in") {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    ForEach(lines) { line in
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                            Text(line.text)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Theme.Spacing.s)
                            Text(line.app.rawValue)
                                .textRole(.data)
                                .foregroundStyle(Theme.Colors.inkTertiary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

/// Words remember (135 §3): an @ word takes a 1 pt underline in its home app's accent, its text in ink. A private or
/// walled word stays plain ink with no underline.
enum LinkColours {
    /// Underlines each @mention in `text` whose name is a key of `homes` (lowercased) with that app's accent.
    static func underline(_ attributed: inout AttributedString, text: String, homes: [String: HomeApp]) {
        for match in text.matches(of: /@\[[^\]]+\]|@[^\s@]+(?: [A-Z][^\s@]*)*/) {
            let name = String(text[match.range]).dropFirst().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            guard let app = homes[name.lowercased()],
                  let lower = AttributedString.Index(match.range.lowerBound, within: attributed),
                  let upper = AttributedString.Index(match.range.upperBound, within: attributed) else { continue }
            attributed[lower ..< upper].foregroundColor = Theme.Colors.ink
            attributed[lower ..< upper].underlineStyle = Text.LineStyle(pattern: .solid, color: app.accent)
        }
    }

    /// The home app of each object a note links to, by its shown name; walled ones are left out (they stay plain).
    @MainActor
    static func homes(of note: ObjectRecord, store: ObjectStore,
                      classes: [SystemCatalog.Key: ClassDef]) -> [String: HomeApp]
    {
        var homes: [String: HomeApp] = [:]
        for link in note.outgoingLinks ?? [] {
            if let target = link.toObject, !target.isDeleted,
               ObjectPrivacy.shownLabel(of: target, in: store, classes: classes) == nil,
               let app = HomeApp.of(target, classes: classes)
            {
                homes[store.displayTitle(of: target).lowercased()] = app
            } else if let classDef = link.toClass, let prototype = store.objects(of: classDef).first,
                      let app = HomeApp.of(prototype, classes: classes)
            {
                homes[classDef.name.lowercased()] = app
            }
        }
        return homes
    }
}
