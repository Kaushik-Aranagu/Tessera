import Foundation
import TesseraCore

/// Fills the director's playbook through the Door (harness H2). Haiku 5.5, effort low, one strict tool `setPlaybook`
/// whose schema is built from the same enums the director uses (`BurstShape`, `OpenReactionKind`). It runs at the
/// first open after 4 am and at most three times a day, costs about $0.0002 a call, and sends no word of his: only
/// the part of the day, the weekday, whether it is quiet, Reduce Motion, the app accent names, and the last ten
/// choice keys (fixed vocabulary). Claude off, offline, over the cap or the flag Off: no playbook, the rules answer.
@MainActor
public struct PlaybookJob {
    public static let flag = "tessDirectorPlaybook"
    public static let maxRunsPerDay = 3
    public static let toolName = "setPlaybook"

    public struct Inputs: Sendable, Equatable {
        public var partOfDay: String
        public var weekday: String
        public var quiet: Bool
        public var reduceMotion: Bool
        /// The app accents a page can carry (names, not colours).
        public var accents: [AppID]
        public var recent: [String]

        public init(partOfDay: String, weekday: String, quiet: Bool, reduceMotion: Bool, accents: [AppID],
                    recent: [String])
        {
            self.partOfDay = partOfDay
            self.weekday = weekday
            self.quiet = quiet
            self.reduceMotion = reduceMotion
            self.accents = accents
            self.recent = Array(recent.prefix(10))
        }
    }

    public enum Result: Equatable, Sendable {
        case filled(DirectorPlaybook)
        case skipped(String)
    }

    public let door: Door
    public let store: PlaybookStore
    public var enabled: () -> Bool
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current

    public init(door: Door, store: PlaybookStore = PlaybookStore(), enabled: @escaping () -> Bool = { true }) {
        self.door = door
        self.store = store
        self.enabled = enabled
    }

    /// The house day a playbook belongs to ("2026-10-24"; before 4 am it is still yesterday's).
    public func day() -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: TesseraDay(calendar: calendar).day(of: now()))
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    // MARK: Schema

    static var schema: Data {
        let shapes = BurstShape.allCases.map(\.rawValue)
        let kinds = OpenReactionKind.allCases.map(\.rawValue)
        let apps = AppID.allCases.map(\.rawValue)
        let why: [String: Any] = ["type": "string", "description": "One short plain line: why this."]
        func burst() -> [String: Any] {
            ["type": "object", "additionalProperties": false, "required": ["shape", "count", "seconds", "why"],
             "properties": ["shape": ["type": "string", "enum": shapes],
                            "count": ["type": "integer", "minimum": 0, "maximum": TessDirection.maxBurstCount],
                            "seconds": ["type": "number", "minimum": 0, "maximum": TessDirection.maxBurstSeconds],
                            "why": why]]
        }
        func reaction() -> [String: Any] {
            ["type": "object", "additionalProperties": false, "required": ["kind", "seconds", "why"],
             "properties": ["kind": ["type": "string", "enum": kinds],
                            "seconds": ["type": "number", "minimum": 0, "maximum": TessDirection.maxReactionSeconds],
                            "why": why]]
        }
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["palette", "burst", "reaction"],
            "properties": [
                "palette": ["type": "array", "items": [
                    "type": "object", "additionalProperties": false, "required": ["app", "accent", "why"],
                    "properties": ["app": ["type": "string", "enum": apps],
                                   "accent": ["type": "string", "enum": apps + ["ember"]], "why": why],
                ]],
                "burst": ["type": "object", "additionalProperties": false,
                          "required": BurstKind.allCases.map(\.rawValue),
                          "properties": Dictionary(uniqueKeysWithValues: BurstKind.allCases
                              .map { ($0.rawValue, burst()) })],
                "reaction": ["type": "object", "additionalProperties": false,
                             "required": AwayBucket.allCases.map(\.rawValue),
                             "properties": Dictionary(uniqueKeysWithValues: AwayBucket.allCases.map {
                                 ($0.rawValue, reaction())
                             })],
            ],
        ]
        return (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8)
    }

    static let instructions = """
    You choose how Tess's looks and reactions behave today, ahead of time. Reply only by calling setPlaybook. \
    Palette: for each app, say whether Tess takes that app's accent on a page where it is the only accent, or ember. \
    Burst: a shape, a count (0 to 24) and a length in seconds (0 to 2.5) for each kind of finish. Reaction: what the \
    mosaic does when the person opens the app after each length of time away, with a length (0 to 2.6 seconds). Keep it calm \
    in the morning, quiet when quiet is on, and none of it when reduce motion is on. Vary from the recent choices. \
    Each why is one plain sentence of at most 14 words, ending in a full stop, with no digits.
    """

    // MARK: Parse

    /// The playbook a tool call carries, or nil when it does not decode. The result is clamped.
    nonisolated static func playbook(from input: Data, day: String) -> DirectorPlaybook? {
        guard let root = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any] else { return nil }
        var playbook = DirectorPlaybook(day: day)
        for item in root["palette"] as? [[String: Any]] ?? [] {
            guard let app = (item["app"] as? String).flatMap(AppID.init(rawValue:)),
                  let accent = item["accent"] as? String, let why = item["why"] as? String else { continue }
            playbook.tessPalette[DirectorPlaybook.paletteKey([app])] = PlaybookEntry(
                PlaybookPalette(accent: AppID(rawValue: accent)), why: why
            )
        }
        let bursts = root["burst"] as? [String: Any] ?? [:]
        for kind in BurstKind.allCases {
            guard let item = bursts[kind.rawValue] as? [String: Any],
                  let shape = (item["shape"] as? String).flatMap(BurstShape.init(rawValue:)),
                  let count = item["count"] as? Int, let seconds = item["seconds"] as? Double,
                  let why = item["why"] as? String else { continue }
            playbook.burst[kind] = PlaybookEntry(PlaybookBurst(shape: shape, count: count, seconds: seconds), why: why)
        }
        let reactions = root["reaction"] as? [String: Any] ?? [:]
        for bucket in AwayBucket.allCases {
            guard let item = reactions[bucket.rawValue] as? [String: Any],
                  let kind = (item["kind"] as? String).flatMap(OpenReactionKind.init(rawValue:)),
                  let seconds = item["seconds"] as? Double, let why = item["why"] as? String else { continue }
            playbook.reaction[bucket] = PlaybookEntry(PlaybookReaction(kind: kind, seconds: seconds), why: why)
        }
        let clamped = playbook.clamped()
        return clamped.tessPalette.isEmpty && clamped.burst.isEmpty && clamped.reaction.isEmpty ? nil : clamped
    }

    // MARK: Run

    /// Asks Haiku for today's playbook. Never throws and never blocks a screen: any failure leaves the rules.
    public func fill(_ inputs: Inputs) async -> Result {
        guard enabled() else { return .skipped("flag off") }
        let day = day()
        guard store.runs(day: day) < Self.maxRunsPerDay else { return .skipped("three runs today") }
        let facts = [
            "part of day: \(inputs.partOfDay)", "weekday: \(inputs.weekday)", "quiet: \(inputs.quiet)",
            "reduce motion: \(inputs.reduceMotion)", "apps: \(inputs.accents.map(\.rawValue).joined(separator: ", "))",
            "recent choices: \(inputs.recent.joined(separator: ", "))",
        ].joined(separator: "\n")
        let tool = ToolSpec(name: Self.toolName, description: "Sets today's playbook.", schema: Self.schema)
        let request = BrainRequest(system: [TextBlock(Self.instructions)],
                                   messages: [BrainMessage(.user, text: "Today:\n\(facts)")], tools: [tool],
                                   toolChoice: .tool(Self.toolName), maxTokens: 900, effort: .low,
                                   deadline: .seconds(20))
        let estimate = TessUsageLedger.estimate(
            text: Door.words(request) + String(decoding: Self.schema, as: UTF8.self),
            maxTokens: request.maxTokens,
            model: ClaudeBrain.Model.haiku.rawValue
        )
        let job = DoorJob(name: "director-playbook", ladder: [.haiku], request: request, estimateNano: estimate,
                          validator: { Self.playbook(from: $0, day: "x") != nil })
        var found: DirectorPlaybook?
        do {
            for try await event in door.run(job) {
                if case let .toolUse(_, name, input) = event, name == Self.toolName {
                    found = Self.playbook(from: input, day: day)
                }
            }
        } catch {
            found = nil
        }
        // A run counts even when it made nothing, so a bad day cannot loop.
        store.save(found, day: day)
        return found.map(Result.filled) ?? .skipped("no playbook")
    }
}
