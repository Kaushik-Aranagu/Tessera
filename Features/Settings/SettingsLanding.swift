import SwiftUI
import TesseraCore

/// The Settings landing on the shared kit (landing contract §12): a word wall of setting areas in the keystone slot,
/// weighted by the areas he opened last; the doors Tess, Privacy, Units, Claude, Backups and About on the dial; one
/// line about the last backup; no action word. Ink is the accent (the title), and the doors wear kind colours so the
/// big type never shares one: gold (Tess, About), slate (Privacy, Units, Claude), green (Backups). It only opens the
/// pages Settings already has: nothing here changes a setting, reads the Claude key or
/// touches a backup. The title opens every setting (the hub).
struct SettingsLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.realModel) private var realModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var focus = 0
    @State private var area: SettingsArea?
    @State private var backupLine: String?
    @State private var opened = 0

    var body: some View {
        let _ = model.revision
        let _ = opened
        let facts = facts
        LandingFrame(title: "Settings", accent: Theme.Colors.ink, stateLine: SettingsLandingWords.stateLine(facts),
                     onTitle: { open(.everything) },
                     keystone: {
                         LandingKeystone(label: "Setting areas") {
                             WordWallView(words: SettingsLandingWords.wall(opened: SettingsAreaSeen.all())) { id in
                                 if let area = SettingsArea(rawValue: id) {
                                     open(area)
                                 }
                             } label: { word in
                                 "\(SettingsArea(rawValue: word.id)?.title ?? word.text.capitalized), setting"
                             }
                         }
                     },
                     doors: SettingsLandingWords.doors(facts, colors: colors), focus: $focus,
                     openDoor: { door in
                         if let area = SettingsArea(rawValue: door.id) {
                             open(area)
                         }
                     },
                     brief: { brief },
                     action: nil,
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $area) { $0.destination }
            .task {
                // Read once, from the copies' own files; nothing is written.
                backupLine = BackupKeeper.lastLine(copies: BackupKeeper.localCopies(), now: AppClock.now)
            }
    }

    private var facts: SettingsLandingFacts {
        let memory = TessMemoryStore(engine: model.engine, forgetLogURL: model.forgetLogURL)
        let units = UnitsCopy.kinds.map { model.displayUnits.unit(for: $0) ?? UnitsCopy.standard($0) }
        return SettingsLandingFacts(remembers: memory.countWord(), asksClaude: model.asksClaude, units: units,
                                    backupLine: backupLine, build: BuildStamp.short,
                                    privacyLines: privacyLines)
    }

    /// Core's privacy sentences, counts only, from his own store even while Sample data is on (as the Privacy page).
    private var privacyLines: [String] {
        let real = realModel ?? model
        return PrivacyPage.lines(engine: real.engine, claudeOn: real.asksClaude, backupLine: backupLine ?? "")
    }

    private var colors: SettingsLandingWords.Colors {
        let dark = scheme == .dark
        return .init(ink: Theme.Colors.ink,
                     slate: dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F),
                     green: dark ? Color(hex: 0x8FC9A0) : Color(hex: 0x25803D),
                     gold: dark ? Color(hex: 0xD9C27A) : Color(hex: 0x7E6A1E))
    }

    @ViewBuilder
    private var brief: some View {
        let forms = SettingsLandingWords.brief(backupLine)
        if let lead = forms.lead {
            ViewThatFits(in: .horizontal) {
                (Text(lead).fontWeight(.semibold).foregroundStyle(Theme.Colors.ink) + Text(forms.rest))
                    .fixedSize()
                if let when = SettingsLandingWords.briefWhen(forms.rest) {
                    (Text("Backup").fontWeight(.semibold).foregroundStyle(Theme.Colors.ink) + Text(" \(when)"))
                        .fixedSize()
                }
                Text("Backed up").fontWeight(.semibold).foregroundStyle(Theme.Colors.ink).fixedSize()
            }
            .font(.custom("Figtree", size: 15, relativeTo: .callout))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(lead + forms.rest)
        }
    }

    private func open(_ next: SettingsArea) {
        SettingsAreaSeen.mark(next, at: AppClock.now)
        opened += 1
        area = next
    }
}

/// The areas the landing can open, each an existing Settings page.
enum SettingsArea: String, CaseIterable, Identifiable, Hashable {
    case tess, privacy, units, claude, backups, about, restDay, colours, aboutMe, undo, everything

    var id: String {
        rawValue
    }

    /// The word on the wall (and the door's name for the six doors).
    var title: String {
        switch self {
        case .tess: "Tess"
        case .privacy: "Privacy"
        case .units: "Units"
        case .claude: "Claude"
        case .backups: "Backups"
        case .about: "About"
        case .restDay: "Rest day"
        case .colours: "Colours"
        case .aboutMe: "About me"
        case .undo: "Undo"
        case .everything: "Everything"
        }
    }

    /// The six on the dial (contract §12).
    static let doors: [SettingsArea] = [.tess, .privacy, .units, .claude, .backups, .about]

    /// How much a word weighs before he has opened anything (0 to 1).
    var baseWeight: Double {
        switch self {
        case .tess: 0.9
        case .privacy: 0.8
        case .units: 0.7
        case .claude: 0.65
        case .backups: 0.6
        case .colours: 0.5
        case .restDay: 0.45
        case .aboutMe: 0.4
        case .undo: 0.35
        case .about: 0.3
        case .everything: 0.25
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .tess: TessKnowsPage()
        case .privacy: PrivacyWordsPage()
        case .units: HubPage(title: "Units") { UnitsSentence() }
        case .claude: HubPage(title: "Tess asks Claude") { ClaudeSection() }
        case .backups: BackupView()
        case .about: AboutPage()
        case .restDay: HubPage(title: "Rest day") { RestDaySentence() }
        case .colours: HubPage(title: "Colours") { LookSentence() }
        case .aboutMe: MePage()
        case .undo: RecentChangesPage()
        case .everything: SettingsHub(cameFrom: "Settings")
        }
    }
}

/// What the landing reads, gathered once per draw. No names, no key, no amounts: counts and on or off.
struct SettingsLandingFacts: Equatable {
    /// "12 things" or "Nothing yet" (Core's count word).
    var remembers: String
    var asksClaude: Bool
    /// Weight, distance, length and temperature units, in that order.
    var units: [String]
    /// "Last backup tonight, 9:14 pm. 4,210 things." once read; nil before.
    var backupLine: String?
    var build: String
    var privacyLines: [String] = []
}

/// The landing's words, pure so tests can read them.
enum SettingsLandingWords {
    struct Colors {
        let ink: Color
        let slate: Color
        let green: Color
        var gold: Color = .yellow
    }

    /// The header line, longest first; the last always fits (FitLine never wraps or ellipsizes).
    static func stateLine(_ facts: SettingsLandingFacts) -> [String] {
        let nothing = facts.remembers == "Nothing yet"
        let remembers = nothing ? "Tess remembers nothing yet" : "Tess remembers \(facts.remembers)"
        let claude = facts.asksClaude ? ", and asks Claude only with your key" : ", all on this phone"
        return [
            "\(remembers)\(claude).",
            "\(remembers).",
            nothing ? "Nothing kept." : "Tess keeps \(facts.remembers.split(separator: " ").first ?? "").",
        ]
    }

    /// The wall: every area, weighted by when he last opened it (the newest first), then by its base weight.
    static func wall(opened: [String: Date]) -> [WallWord] {
        let ranked = opened.sorted { $0.value > $1.value }.map(\.key)
        return SettingsArea.allCases.map { area in
            var weight = area.baseWeight * 0.6
            if let rank = ranked.firstIndex(of: area.rawValue) {
                weight += 0.4 * (1 - Double(rank) / Double(max(ranked.count, 1)))
            }
            return WallWord(id: area.rawValue, text: area.title, weight: min(weight, 1))
        }
    }

    static func doors(_ facts: SettingsLandingFacts, colors: Colors) -> [DialDoor] {
        SettingsArea.doors.map { area in
            switch area {
            case .tess:
                let count = facts.remembers.split(separator: " ").first.map(String.init)
                return DialDoor(id: area.rawValue, name: area.title,
                                count: count.flatMap { Int($0) == nil ? nil : $0 }, color: colors.gold,
                                label: "Tess remembers", lines: [facts.remembers.capitalizedFirst])
            case .privacy:
                return DialDoor(id: area.rawValue, name: area.title, color: colors.slate,
                                label: "Kept on this phone", lines: Array(facts.privacyLines.prefix(2)))
            case .units:
                let shown = facts.units
                let lines = stride(from: 0, to: shown.count, by: 2).map { shown[$0 ..< min($0 + 2, shown.count)]
                    .joined(separator: ", ")
                }
                return DialDoor(id: area.rawValue, name: area.title, color: colors.slate, label: "Measures in",
                                lines: lines)
            case .claude:
                return DialDoor(id: area.rawValue, name: area.title, color: colors.slate, label: "Tess asks Claude",
                                lines: facts.asksClaude ? ["On", "Only with your key"] : ["Off", "Nothing leaves"])
            case .backups:
                let lines = facts.backupLine.map(Self.sentences) ?? []
                return DialDoor(id: area.rawValue, name: area.title, color: colors.green, label: "On this phone",
                                lines: lines)
            default:
                return DialDoor(id: area.rawValue, name: area.title, color: colors.gold, label: "Tessera",
                                lines: ["Build \(facts.build)", "Credits"])
            }
        }
    }

    /// The brief at 612: the backup line's first words bold ("Last backup"), the rest in ink 2; nil lead when unread.
    static func brief(_ backupLine: String?) -> (lead: String?, rest: String) {
        guard let line = backupLine, !line.isEmpty else { return (nil, "") }
        let first = sentences(line).first ?? line
        let words = first.split(separator: " ")
        guard words.count > 2 else { return (first, "") }
        let lead = words.prefix(2).joined(separator: " ")
        return (lead, String(first.dropFirst(lead.count)))
    }

    /// The brief's short form: the day word of the rest, "this afternoon" kept whole ("Backup this afternoon",
    /// "Backup Saturday"). Nil when there is no rest.
    static func briefWhen(_ rest: String) -> String? {
        let words = rest.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters) }
        guard let first = words.first, !first.isEmpty else { return nil }
        return first.lowercased() == "this" && words.count > 1 ? "this \(words[1])" : first
    }

    /// "A. B." into ["A.", "B."].
    static func sentences(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for word in text.split(separator: " ") {
            current += current.isEmpty ? String(word) : " \(word)"
            if word.hasSuffix(".") {
                result.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}

/// When he last opened each area from the landing, on this phone only (UserDefaults), never in the op log, a backup or
/// a widget.
enum SettingsAreaSeen {
    private static let key = "landing.settings.opened"

    static func all(defaults: UserDefaults = .standard) -> [String: Date] {
        let raw = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        return raw.mapValues { Date(timeIntervalSince1970: $0) }
    }

    static func mark(_ area: SettingsArea, at date: Date, defaults: UserDefaults = .standard) {
        var raw = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        raw[area.rawValue] = date.timeIntervalSince1970
        defaults.set(raw, forKey: key)
    }
}

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
