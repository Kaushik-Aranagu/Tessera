import Foundation

// The look-and-change seam. Layers (mosaic, bursts, palette washes, open reactions, scenes, Tess's own colours) ask
// the director what plays and how it looks; none of them rolls its own random or fixed rule. Today `RuleDirector`
// answers. A model-backed director can replace it later under asksClaude, seeing the same context and nothing more:
// whatever it answers is clamped afterwards by `TessDirection`, so the walls hold whichever director is behind it.

/// Everything a director may read. Already-safe facts only: no titles, no values, no health, calendar, body, calorie
/// or money data.
public struct DirectorContext: Sendable {
    public var now: Date
    public var quiet: Bool
    public var reduceMotion: Bool
    public var lowPower: Bool
    public var asksClaude: Bool
    /// Keys of the last choices, newest first, so a pick can vary without a random call.
    public var recent: [String]
    public var seed: UInt64

    public init(now: Date, quiet: Bool = false, reduceMotion: Bool = false, lowPower: Bool = false,
                asksClaude: Bool = false, recent: [String] = [], seed: UInt64 = 0)
    {
        self.now = now
        self.quiet = quiet
        self.reduceMotion = reduceMotion
        self.lowPower = lowPower
        self.asksClaude = asksClaude
        self.recent = recent
        self.seed = seed
    }
}

public enum BurstKind: String, CaseIterable, Sendable {
    case done, best, finished, arrived
}

public enum BurstShape: String, CaseIterable, Sendable {
    case none, rise, ring, spray, scatter
}

public enum OpenEvent: Equatable, Sendable {
    /// `away` is nil on a cold launch. `firstOpenAfterFour` is the first open after 4 am local.
    case opened(away: TimeInterval?, firstOpenAfterFour: Bool, momentPlaying: Bool)
}

public enum DirectorAsk: Sendable {
    case mosaic(cues: [MosaicCue], state: MosaicSwitchState, weatherOn: Bool)
    case handBack(state: MosaicSwitchState)
    case burst(BurstKind, tone: MosaicTone)
    /// Tess's own colour burst.
    case tessBurst
    case palette(from: MosaicTone, to: MosaicTone)
    /// The page's accent shares (app → share of the page, 0 to 1). Ember is her base; she borrows only a clear one.
    case tessPalette(pageAccents: [AppID: Double])
    case reaction(OpenEvent)
    case scene(MosaicBackdrop, facts: MosaicFacts, place: PlaceKind?, weather: SceneWeather?, calendar: Calendar)
}

public struct MosaicDecision: Sendable {
    public var state: MosaicSwitchState
    public var directive: MosaicDirective
    /// Every changeover is a plain swap (Reduce Motion).
    public var plainSwap = false
}

public struct BurstChoice: Equatable, Sendable {
    public var shape: BurstShape
    public var count: Int
    public var duration: TimeInterval
    public var tone: MosaicTone
}

public enum PaletteCurve: String, Sendable {
    case easeInOut, spring
}

public struct PaletteChoice: Equatable, Sendable {
    public var from: MosaicTone
    public var to: MosaicTone
    /// How far the wash goes toward `to`, 0 to 1.
    public var mix: Double
    public var duration: TimeInterval
    public var curve: PaletteCurve
}

/// Tess's own colours: ember always, plus at most one page accent, mixed lightly.
public struct TessPaletteChoice: Equatable, Sendable {
    public var accent: AppID?
    public var mix: Double
}

public struct TessBurstChoice: Equatable, Sendable {
    public var shape: BurstShape
    public var count: Int
    public var duration: TimeInterval
    public var palette: TessPaletteChoice
}

public enum OpenReactionKind: String, Sendable {
    case none, ripple, flipRows, nightFalls, gatherBack, gatherFromNight
}

public struct ReactionChoice: Equatable, Sendable {
    public var kind: OpenReactionKind
    public var duration: TimeInterval
}

public struct SceneChoice: Equatable, Sendable {
    public var scene: MosaicScenery?
    /// Still (Reduce Motion or Low Power): the scene only changes with the hour, as a plain swap.
    public var still: Bool
}

public enum DirectorChoice: Sendable {
    case mosaic(MosaicDecision)
    case burst(BurstChoice)
    case tessBurst(TessBurstChoice)
    case palette(PaletteChoice)
    case tessPalette(TessPaletteChoice)
    case reaction(ReactionChoice)
    case scene(SceneChoice)
}

public struct DirectorDecision: Sendable {
    public var choice: DirectorChoice
    /// One plain line for the Explain screen: why this and not something else.
    public var why: String
    /// A key for `DirectorContext.recent`.
    public var key: String
}

public protocol TessDirector: Sendable {
    func decide(_ ask: DirectorAsk, context: DirectorContext) -> DirectorDecision
}

/// What layers call. The director decides; the clamps run after it, always, so no director can break a wall.
public enum TessDirection {
    public static let maxBurstCount = 24
    public static let maxBurstSeconds = 2.5
    public static let maxPaletteSeconds = 1.2
    public static let maxPaletteMix = 0.35
    public static let maxTessMix = 0.3
    public static let maxReactionSeconds = 2.6

    public static func decide(_ director: any TessDirector, _ ask: DirectorAsk,
                              context: DirectorContext) -> DirectorDecision
    {
        var decision = director.decide(ask, context: context)
        decision.choice = clamp(decision.choice, context: context)
        return decision
    }

    static func clamp(_ choice: DirectorChoice, context: DirectorContext) -> DirectorChoice {
        let still = context.reduceMotion
        switch choice {
        case var .mosaic(decision):
            if let play = decision.directive.play, context.quiet, !play.name.playsInQuietHours {
                decision.directive.play = nil
                decision.state.playing = nil
            }
            if context.quiet, let change = decision.directive.mood, change.mood != .night {
                decision.directive.mood = nil
                decision.state.mood = nil
            }
            decision.plainSwap = still
            return .mosaic(decision)
        case var .burst(burst):
            clampBurst(&burst.shape, &burst.count, &burst.duration, context: context)
            return .burst(burst)
        case var .tessBurst(burst):
            clampBurst(&burst.shape, &burst.count, &burst.duration, context: context)
            burst.palette = clampTess(burst.palette)
            return .tessBurst(burst)
        case var .palette(palette):
            palette.mix = min(max(palette.mix, 0), maxPaletteMix)
            palette.duration = still ? 0 : min(max(palette.duration, 0), maxPaletteSeconds)
            return .palette(palette)
        case let .tessPalette(palette):
            return .tessPalette(clampTess(palette))
        case var .reaction(reaction):
            reaction.duration = min(max(reaction.duration, 0), maxReactionSeconds)
            if still || context.quiet {
                reaction = ReactionChoice(kind: .none, duration: 0)
            }
            return .reaction(reaction)
        case var .scene(scene):
            scene.still = scene.still || still || context.lowPower
            return .scene(scene)
        }
    }

    private static func clampBurst(_ shape: inout BurstShape, _ count: inout Int, _ duration: inout TimeInterval,
                                   context: DirectorContext)
    {
        count = min(max(count, 0), maxBurstCount)
        duration = min(max(duration, 0), maxBurstSeconds)
        if context.reduceMotion || context.lowPower || context.quiet {
            shape = .none
        }
        if shape == .none {
            count = 0
            duration = 0
        }
    }

    /// One accent at most, lightly mixed; with no accent there is nothing to mix.
    private static func clampTess(_ palette: TessPaletteChoice) -> TessPaletteChoice {
        palette.accent == nil
            ? TessPaletteChoice(accent: nil, mix: 0)
            : TessPaletteChoice(accent: palette.accent, mix: min(max(palette.mix, 0), maxTessMix))
    }
}

/// Today's director: the rules, with variety from a seed and the recent choices, never a random call, so a test can
/// say exactly what it answers.
public struct RuleDirector: TessDirector {
    public init() {}

    public func decide(_ ask: DirectorAsk, context: DirectorContext) -> DirectorDecision {
        switch ask {
        case let .mosaic(cues, state, weatherOn):
            let result = MosaicSwitchboard.step(state, cues: cues, quiet: context.quiet,
                                                asksClaude: context.asksClaude, weatherOn: weatherOn)
            return DirectorDecision(choice: .mosaic(MosaicDecision(state: result.state, directive: result.directive)),
                                    why: "The switchboard: a moment beats a mood, Tess then apps then the clock.",
                                    key: "mosaic")
        case let .handBack(state):
            let result = MosaicSwitchboard.handedBack(state, quiet: context.quiet)
            return DirectorDecision(choice: .mosaic(MosaicDecision(state: result.state, directive: result.directive)),
                                    why: "The moment handed back; the best-ranked waiting one is next.",
                                    key: "handBack")
        case let .burst(kind, tone):
            let shape = vary(from: shapes(for: kind), context: context, prefix: "burst")
            let count = 8 + Int(context.seed % 9)
            return DirectorDecision(choice: .burst(BurstChoice(shape: shape, count: count, duration: 1.0, tone: tone)),
                                    why: "A \(shape.rawValue) for \(kind.rawValue), not the one before it.",
                                    key: "burst-\(shape.rawValue)")
        case .tessBurst:
            let shape = vary(from: [.ring, .rise, .scatter], context: context, prefix: "burst")
            let palette = Self.palette(pageAccents: [:])
            return DirectorDecision(choice: .tessBurst(TessBurstChoice(shape: shape, count: 12, duration: 1.2,
                                                                       palette: palette)),
                                    why: "Her own colour, a \(shape.rawValue).", key: "burst-\(shape.rawValue)")
        case let .palette(from, to):
            return DirectorDecision(choice: .palette(PaletteChoice(from: from, to: to, mix: 0.2, duration: 0.6,
                                                                   curve: .easeInOut)),
                                    why: "A light wash toward the page's accent.", key: "palette")
        case let .tessPalette(accents):
            let palette = Self.palette(pageAccents: accents)
            return DirectorDecision(choice: .tessPalette(palette),
                                    why: palette.accent == nil ? "Ember: no clear accent on this page."
                                        : "Ember with a touch of the page's accent.", key: "tessPalette")
        case let .reaction(event):
            return reaction(event)
        case let .scene(backdrop, facts, place, weather, calendar):
            let scene = MosaicScenePicker.pick(backdrop, facts: facts, place: place, weather: weather,
                                               calendar: calendar)
            return DirectorDecision(choice: .scene(SceneChoice(scene: scene, still: false)),
                                    why: "The hour, the weather and the kind of place.", key: "scene")
        }
    }

    /// Ember is her base. She borrows the page's accent only when one clearly leads: at least half the page and twice
    /// the next. Everything mixed together is never done.
    static func palette(pageAccents: [AppID: Double]) -> TessPaletteChoice {
        let ranked = pageAccents.sorted { $0.value > $1.value }
        guard let top = ranked.first, top.value >= 0.5, top.value >= 2 * (ranked.dropFirst().first?.value ?? 0) else {
            return TessPaletteChoice(accent: nil, mix: 0)
        }
        return TessPaletteChoice(accent: top.key, mix: 0.25)
    }

    private func reaction(_ event: OpenEvent) -> DirectorDecision {
        guard case let .opened(away, firstAfterFour, momentPlaying) = event else {
            return DirectorDecision(choice: .reaction(ReactionChoice(kind: .none, duration: 0)), why: "", key: "none")
        }
        let choice: ReactionChoice
        let why: String
        if momentPlaying {
            choice = ReactionChoice(kind: .none, duration: 0)
            why = "A moment is playing and wins."
        } else if away == nil {
            choice = ReactionChoice(kind: .gatherFromNight, duration: 1.8)
            why = "A cold launch gathers from the night."
        } else if let away, away >= 2 * 86400 {
            choice = ReactionChoice(kind: .gatherBack, duration: 2.4)
            why = "Two days or more away: dusty pixels gather into today."
        } else if firstAfterFour {
            choice = ReactionChoice(kind: .nightFalls, duration: 2.2)
            why = "The first open of the day: night falls away."
        } else if let away, away >= 120 {
            choice = ReactionChoice(kind: .flipRows, duration: 1.4)
            why = "Back after a while: the tiles flip row by row."
        } else {
            choice = ReactionChoice(kind: .ripple, duration: 0.9)
            why = "A quick return: a ripple from the middle."
        }
        return DirectorDecision(choice: .reaction(choice), why: why, key: "reaction-\(choice.kind.rawValue)")
    }

    private func shapes(for kind: BurstKind) -> [BurstShape] {
        switch kind {
        case .done: [.rise, .spray, .scatter]
        case .best: [.ring, .rise]
        case .finished: [.spray, .scatter]
        case .arrived: [.ring, .scatter]
        }
    }

    /// The next shape from the seed, skipping the one used last when there is another.
    private func vary(from shapes: [BurstShape], context: DirectorContext, prefix: String) -> BurstShape {
        let last = context.recent.first { $0.hasPrefix(prefix) }
        let fresh = shapes.filter { last != "\(prefix)-\($0.rawValue)" }
        let pool = fresh.isEmpty ? shapes : fresh
        return pool[Int(context.seed % UInt64(pool.count))]
    }
}
