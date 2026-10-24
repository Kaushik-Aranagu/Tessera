import Foundation

// H2: the director's playbook. A small model fills it ahead of time (once a day, at the first open after 4 am); the
// director reads it at the moment of a decision, so no model call ever waits on the screen. Anything the playbook has
// no entry for falls through to `RuleDirector`, and `TessDirection.decide` still clamps every choice afterwards.

/// How long he was away, in the four buckets the playbook speaks in.
public enum AwayBucket: String, Codable, CaseIterable, Sendable {
    case underOneHour, oneToEightHours, overEightHours, firstOpenAfterFour

    /// `nil` away is a cold launch, which the rules own.
    public static func bucket(away: TimeInterval?, firstOpenAfterFour: Bool) -> AwayBucket? {
        if firstOpenAfterFour {
            return .firstOpenAfterFour
        }
        guard let away else { return nil }
        if away < 3600 {
            return .underOneHour
        }
        return away < 8 * 3600 ? .oneToEightHours : .overEightHours
    }
}

public struct PlaybookEntry<Choice: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    public var choice: Choice
    /// One line for the Explain screen.
    public var why: String

    public init(_ choice: Choice, why: String) {
        self.choice = choice
        self.why = why
    }
}

public struct PlaybookBurst: Codable, Equatable, Sendable {
    public var shape: BurstShape
    public var count: Int
    public var seconds: Double

    public init(shape: BurstShape, count: Int, seconds: Double) {
        self.shape = shape
        self.count = count
        self.seconds = seconds
    }
}

public struct PlaybookReaction: Codable, Equatable, Sendable {
    public var kind: OpenReactionKind
    public var seconds: Double

    public init(kind: OpenReactionKind, seconds: Double) {
        self.kind = kind
        self.seconds = seconds
    }
}

/// Which accent Tess takes on a page: one of the page's own, or nil for Ember.
public struct PlaybookPalette: Codable, Equatable, Sendable {
    public var accent: AppID?

    public init(accent: AppID?) {
        self.accent = accent
    }
}

extension BurstShape: Codable {}
extension OpenReactionKind: Codable {}
extension BurstKind: Codable {}

public struct DirectorPlaybook: Codable, Equatable, Sendable {
    /// "2026-10-24": the house day it was made for.
    public var day: String
    /// Key: the page's accent ids, sorted and joined with commas.
    public var tessPalette: [String: PlaybookEntry<PlaybookPalette>] = [:]
    public var burst: [BurstKind: PlaybookEntry<PlaybookBurst>] = [:]
    public var reaction: [AwayBucket: PlaybookEntry<PlaybookReaction>] = [:]

    public init(day: String) {
        self.day = day
    }

    public static func paletteKey(_ accents: Set<AppID>) -> String {
        accents.map(\.rawValue).sorted().joined(separator: ",")
    }

    /// Every entry clamped to `TessDirection`'s maxima, and an entry that cannot be made sensible dropped on its own.
    /// Run when the playbook is stored and again when it is read.
    public func clamped() -> DirectorPlaybook {
        var result = DirectorPlaybook(day: day)
        for (key, entry) in tessPalette {
            let ids = Set(key.split(separator: ",").map(String.init))
            // One clear accent only: the key must be exactly one known app, and the entry that app or Ember.
            guard ids.count == 1, let only = ids.first.flatMap(AppID.init(rawValue:)),
                  entry.choice.accent == nil || entry.choice.accent == only, !entry.why.isEmpty else { continue }
            result.tessPalette[key] = PlaybookEntry(entry.choice, why: Self.line(entry.why))
        }
        for (kind, entry) in burst {
            guard entry.choice.seconds.isFinite, !entry.why.isEmpty else { continue }
            let choice = entry.choice
            result.burst[kind] = PlaybookEntry(
                PlaybookBurst(shape: choice.shape,
                              count: min(max(choice.count, 0), TessDirection.maxBurstCount),
                              seconds: min(max(choice.seconds, 0), TessDirection.maxBurstSeconds)),
                why: Self.line(entry.why)
            )
        }
        for (bucket, entry) in reaction {
            guard entry.choice.seconds.isFinite, !entry.why.isEmpty else { continue }
            result.reaction[bucket] = PlaybookEntry(
                PlaybookReaction(kind: entry.choice.kind,
                                 seconds: min(max(entry.choice.seconds, 0), TessDirection.maxReactionSeconds)),
                why: Self.line(entry.why)
            )
        }
        return result
    }

    /// One short line, no breaks: the Explain screen shows it as written.
    static func line(_ text: String) -> String {
        String(text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces).prefix(120))
    }
}

/// The playbook on disk: `Application Support/Tessera/director-playbook.json`, keyed by day, kept out of backups. A
/// playbook for another day is not read.
public struct PlaybookStore: Sendable {
    public static let fileName = "director-playbook.json"

    private struct File: Codable {
        var playbook: DirectorPlaybook
        /// How many times it was asked for on that day (the cap is three).
        var runs: Int
    }

    public let url: URL?

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    public init(url: URL? = PlaybookStore.defaultURL) {
        self.url = url
    }

    private func read(day: String) -> File? {
        guard let url, let data = try? Data(contentsOf: url), let file = try? JSONDecoder().decode(
            File.self,
            from: data
        ),
            file.playbook.day == day else { return nil }
        return file
    }

    /// Today's playbook, clamped again as it is read.
    public func playbook(day: String) -> DirectorPlaybook? {
        read(day: day)?.playbook.clamped()
    }

    public func runs(day: String) -> Int {
        read(day: day)?.runs ?? 0
    }

    /// Stores a playbook (clamped) and counts the run. A run that made nothing still counts.
    public func save(_ playbook: DirectorPlaybook?, day: String) {
        guard let url else { return }
        let runs = runs(day: day) + 1
        let kept = (playbook ?? read(day: day)?.playbook ?? DirectorPlaybook(day: day)).clamped()
        guard let data = try? JSONEncoder().encode(File(playbook: kept, runs: runs)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: [.atomic])
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }
}

/// Reads today's playbook; any ask with no entry falls through to the rules. `TessDirection.decide` stays the only
/// entry point, so scene asks still go to the rules and the clamps still run after every choice.
public struct PlaybookDirector: TessDirector {
    public var playbook: DirectorPlaybook?
    private let rules = RuleDirector()

    public init(playbook: DirectorPlaybook?) {
        self.playbook = playbook?.clamped()
    }

    public func decide(_ ask: DirectorAsk, context: DirectorContext) -> DirectorDecision {
        guard let playbook else { return rules.decide(ask, context: context) }
        switch ask {
        case let .burst(kind, tone):
            if let entry = playbook.burst[kind] {
                let choice = BurstChoice(shape: entry.choice.shape, count: entry.choice.count,
                                         duration: entry.choice.seconds, tone: tone)
                return DirectorDecision(
                    choice: .burst(choice),
                    why: entry.why,
                    key: "burst-\(entry.choice.shape.rawValue)"
                )
            }
        case let .tessPalette(accents):
            if let entry = playbook.tessPalette[DirectorPlaybook.paletteKey(accents)] {
                let accent = entry.choice.accent
                let colors = accent.flatMap { context.accents[$0] }.map {
                    TessPalette.derive(from: $0, dark: context.dark)
                } ?? []
                let palette = colors.isEmpty ? TessPaletteChoice.ember : TessPaletteChoice(
                    accent: accent,
                    colors: colors
                )
                return DirectorDecision(choice: .tessPalette(palette), why: entry.why, key: "tessPalette")
            }
        case let .reaction(.opened(away, firstAfterFour, momentPlaying)):
            // A moment already playing wins, and a cold launch is the rules': neither is in the playbook.
            if !momentPlaying, let bucket = AwayBucket.bucket(away: away, firstOpenAfterFour: firstAfterFour),
               let entry = playbook.reaction[bucket]
            {
                return DirectorDecision(choice: .reaction(ReactionChoice(kind: entry.choice.kind,
                                                                         duration: entry.choice.seconds)),
                                        why: entry.why, key: "reaction-\(entry.choice.kind.rawValue)")
            }
        default:
            break
        }
        return rules.decide(ask, context: context)
    }
}
