import Foundation

/// Surfaces v2 (Design 142): widgets, the Lock Screen and Live Activities in today's grammar. Pure and Foundation-only,
/// compiled into the app and the widget extension. The switch lives in the app (`ReviewChoices`, "surfacesV2"); the
/// extension cannot read that store, so the app mirrors the switch into the App Group (`flagKey`) and writes the
/// day's clauses to `snapshotKey` only while it is On. Off removes the snapshot, so nothing stale is ever drawn.
///
/// The wall: the snapshot holds only clauses Core's `HomeSentence` composed (already masked: "Private workout",
/// money as due words only). `SurfacesSnapshot.scrubbed` is a second lock that drops any clause that still looks like
/// an amount or a body, health or calorie word before anything is written.
enum SurfacesV2 {
    static let choiceID = "surfacesV2"
    static let group = "group.com.kaushikaranagu.tessera"
    static let flagKey = "surfaces.v2.on"
    static let snapshotKey = "surfaces.v2.snapshot"

    /// The pure reading of the switch's value.
    static func isOn(value: String?) -> Bool {
        value == "On"
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: group)
    }

    /// Mirrors the switch for the extension. Turning it Off also clears the snapshot.
    static func mirrorFlag(_ on: Bool, to defaults: UserDefaults? = SurfacesV2.sharedDefaults) {
        guard let defaults else { return }
        if on {
            defaults.set(true, forKey: flagKey)
        } else {
            defaults.removeObject(forKey: flagKey)
            defaults.removeObject(forKey: snapshotKey)
        }
    }

    static func flagIsOn(in defaults: UserDefaults? = SurfacesV2.sharedDefaults) -> Bool {
        defaults?.bool(forKey: flagKey) ?? false
    }
}

/// One clause of the day sentence as the widget keeps it: plain values, no object ids (a widget never opens one).
struct SurfaceClause: Codable, Equatable, Hashable {
    /// `AppID.rawValue`: training, kitchen, money, notes, lists, routines.
    var app: String
    var text: String
    /// The key word as UTF-16 offsets into `text`.
    var keyFrom: Int?
    var keyTo: Int?
    /// When in the day it belongs; nil for an untimed clause.
    var at: Date?
}

struct SurfacesSnapshot: Codable, Equatable {
    var written: Date
    var clauses: [SurfaceClause]

    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(_ data: Data?) -> SurfacesSnapshot? {
        data.flatMap { try? JSONDecoder().decode(SurfacesSnapshot.self, from: $0) }
    }

    /// Writes the snapshot when the switch is On, else clears it.
    static func store(_ clauses: [SurfaceClause], on: Bool, now: Date,
                      in defaults: UserDefaults? = SurfacesV2.sharedDefaults)
    {
        guard let defaults else { return }
        SurfacesV2.mirrorFlag(on, to: defaults)
        guard on else { return }
        let snapshot = SurfacesSnapshot(written: now, clauses: scrubbed(clauses))
        defaults.set(snapshot.encoded(), forKey: SurfacesV2.snapshotKey)
    }

    /// What the extension draws: nothing unless the switch is mirrored On and a snapshot is there.
    static func read(from defaults: UserDefaults? = SurfacesV2.sharedDefaults) -> SurfacesSnapshot? {
        guard SurfacesV2.flagIsOn(in: defaults) else { return nil }
        return decode(defaults?.data(forKey: SurfacesV2.snapshotKey))
    }

    // MARK: The wall

    private static let walledWords = [
        "calorie", "kcal", "bpm", "heart rate", "resting heart", "body weight", "bodyweight", "body fat",
        "blood", "sleep score", "steps today",
    ]

    /// Money gives due words only (no digit, no currency sign); nobody's body, health or calories at all.
    static func isWalled(_ clause: SurfaceClause) -> Bool {
        let lower = clause.text.lowercased()
        if clause.app == "money",
           clause.text.contains(where: { $0.isNumber || "$€£¥₹".contains($0) })
        {
            return true
        }
        return walledWords.contains { lower.contains($0) }
    }

    static func scrubbed(_ clauses: [SurfaceClause]) -> [SurfaceClause] {
        clauses.filter { !isWalled($0) }
    }
}

/// The words a surface says, from the clauses. Pure.
enum SurfaceLine {
    static let quietDay = "A quiet day."
    static let notYet = "Open Tessera."

    struct Run: Equatable {
        let text: String
        let isKey: Bool
    }

    /// The clause as runs: the key word apart from the rest, so a surface paints it in the app's accent.
    static func runs(_ clause: SurfaceClause) -> [Run] {
        let units = clause.text.utf16
        guard let from = clause.keyFrom, let to = clause.keyTo, from >= 0, from < to, to <= units.count else {
            return [Run(text: clause.text, isKey: false)]
        }
        let start = units.startIndex
        let low = units.index(start, offsetBy: from), high = units.index(start, offsetBy: to)
        guard let head = String(units[start ..< low]), let key = String(units[low ..< high]),
              let tail = String(units[high ..< units.endIndex])
        else { return [Run(text: clause.text, isKey: false)] }
        return [Run(text: head, isKey: false), Run(text: key, isKey: true), Run(text: tail, isKey: false)]
            .filter { !$0.text.isEmpty }
    }

    /// The small widget's line: the first clause (the day's order is Core's).
    static func first(_ clauses: [SurfaceClause]) -> SurfaceClause? {
        clauses.first
    }

    /// The next thing by clock time: the earliest timed clause still ahead (a clause stays "next" for `grace`
    /// after its time), else the first untimed one, else nil.
    static func next(_ clauses: [SurfaceClause], now: Date, grace: TimeInterval = 15 * 60) -> SurfaceClause? {
        let timed = clauses.compactMap { clause in clause.at.map { (clause, $0) } }
            .filter { $0.1 >= now.addingTimeInterval(-grace) }
            .min { $0.1 < $1.1 }
        return timed?.0 ?? clauses.first { $0.at == nil }
    }

    /// "6:10 pm" for a timed clause, else nil. The house clock.
    static func timeWord(_ clause: SurfaceClause, calendar: Calendar = .current) -> String? {
        clause.at.map { HouseClock.time($0, calendar: calendar) }
    }

    /// The Lock Screen's one inline line: "6:10 pm Push A". The key word when there is one, else the clause.
    static func inline(_ clause: SurfaceClause, calendar: Calendar = .current) -> String {
        let key = runs(clause).first(where: \.isKey)?.text ?? clause.text
        return [timeWord(clause, calendar: calendar), key].compactMap(\.self).joined(separator: " ")
    }

    /// The moments the face changes: now, then each later clause time (so "Next" moves on without the app).
    static func changeDates(_ clauses: [SurfaceClause], now: Date, limit: Int = 8) -> [Date] {
        let later = Set(clauses.compactMap(\.at).filter { $0 > now })
        return [now] + Array(later.sorted().prefix(limit))
    }
}

/// Each app's accent as the widget draws it. A copy of `Theme.Colors.Accent` (the extension cannot see the app's
/// design system); `SurfacesV2Tests` checks the two agree.
enum SurfaceAccent {
    static func hex(app: String, dark: Bool) -> UInt32 {
        switch app {
        case "training": dark ? 0xCC4478 : 0xA8203F
        case "kitchen": dark ? 0xD49A52 : 0xA8701F
        case "money": dark ? 0x8DBFA7 : 0x3F7A62
        case "notes": dark ? 0xB9A9E0 : 0x5B3FB8
        case "lists": dark ? 0xB5BE7A : 0x5E6B1F
        case "routines": dark ? 0xD79AA6 : 0xA4505F
        default: dark ? 0xF5F2EC : 0x26201E
        }
    }
}

/// Masking for the Lock Screen and Dynamic Island, which show a name without unlocking.
enum SurfaceMask {
    /// The name a surface may print: the privacy label when there is one ("Private workout"), else the real name.
    static func shown(_ name: String, privateLabel: String?) -> String {
        if let privateLabel, !privateLabel.isEmpty {
            return privateLabel
        }
        return name
    }
}

/// Training's set marks: one per planned set, the done ones filled, the one being rested for next.
enum SurfaceMarks {
    enum Mark: Equatable {
        case done, current, todo
    }

    static let most = 12

    static func marks(done: Int, total: Int) -> [Mark] {
        let count = min(max(total, 0), most)
        let finished = min(max(done, 0), count)
        return (0 ..< count).map { $0 < finished ? .done : ($0 == finished ? .current : .todo) }
    }
}
