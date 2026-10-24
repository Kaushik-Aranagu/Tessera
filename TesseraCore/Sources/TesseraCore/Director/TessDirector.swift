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
    /// Light or dark page, for Tess's derived palette.
    public var dark: Bool
    /// Each app's accent in OKLCH (the app knows its colours; Core only derives from them).
    public var accents: [AppID: OKLCH]
    /// Keys of the last choices, newest first, so a pick can vary without a random call.
    public var recent: [String]
    public var seed: UInt64

    public init(now: Date, quiet: Bool = false, reduceMotion: Bool = false, lowPower: Bool = false,
                asksClaude: Bool = false, dark: Bool = false, accents: [AppID: OKLCH] = [:],
                recent: [String] = [], seed: UInt64 = 0)
    {
        self.now = now
        self.quiet = quiet
        self.reduceMotion = reduceMotion
        self.lowPower = lowPower
        self.asksClaude = asksClaude
        self.dark = dark
        self.accents = accents
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
    case tessBurst(pageAccents: Set<AppID>)
    case palette(from: MosaicTone, to: MosaicTone)
    /// The accents on the page. Ember is her base; with exactly one accent she takes a palette built from it.
    case tessPalette(pageAccents: Set<AppID>)
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

public struct OKLCH: Equatable, Sendable {
    public var lightness: Double
    public var chroma: Double
    /// Degrees, 0 up to 360.
    public var hue: Double

    public init(lightness: Double, chroma: Double, hue: Double) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
    }
}

/// Tess's own colours (sheet 215 G2). Ember is her base. With exactly one accent on the page she takes a palette built
/// from it, never a mix with Ember: the middle at L 0.64 on light or 0.74 on dark (chroma at least 0.15), and the
/// sides 18° either way in hue, a little lighter on the cooler side and a little darker on the other.
public enum TessPalette {
    public static let sideHue = 18.0
    public static let sideLightness = 0.05
    public static let minChroma = 0.15

    public static func middleLightness(dark: Bool) -> Double {
        dark ? 0.74 : 0.64
    }

    /// The three colours, cooler side first.
    public static func derive(from accent: OKLCH, dark: Bool) -> [OKLCH] {
        let lightness = middleLightness(dark: dark)
        let chroma = max(accent.chroma, minChroma)
        func wrap(_ hue: Double) -> Double {
            (hue.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        }
        return [
            OKLCH(lightness: lightness + sideLightness, chroma: chroma, hue: wrap(accent.hue - sideHue)),
            OKLCH(lightness: lightness, chroma: chroma, hue: wrap(accent.hue)),
            OKLCH(lightness: lightness - sideLightness, chroma: chroma, hue: wrap(accent.hue + sideHue)),
        ]
    }

    /// Whether two palettes are the same colours, to within 1e-6.
    public static func matches(_ a: [OKLCH], _ b: [OKLCH]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { x, y in
            abs(x.lightness - y.lightness) < 1e-6 && abs(x.chroma - y.chroma) < 1e-6 && abs(x.hue - y.hue) < 1e-6
        }
    }

    /// Whether three colours are exactly the palette `derive` would make from some accent.
    public static func isDerived(_ colors: [OKLCH], dark: Bool) -> Bool {
        guard colors.count == 3, colors.allSatisfy({ $0.chroma >= minChroma - 1e-9 }) else { return false }
        func close(_ a: Double, _ b: Double) -> Bool {
            abs(a - b) < 1e-6
        }
        func apart(_ a: Double, _ b: Double, by degrees: Double) -> Bool {
            let delta = (b - a).truncatingRemainder(dividingBy: 360)
            return close((delta + 360).truncatingRemainder(dividingBy: 360), degrees)
        }
        return close(colors[1].lightness, middleLightness(dark: dark))
            && close(colors[0].lightness, colors[1].lightness + sideLightness)
            && close(colors[2].lightness, colors[1].lightness - sideLightness)
            && apart(colors[0].hue, colors[1].hue, by: sideHue) && apart(colors[1].hue, colors[2].hue, by: sideHue)
            && close(colors[0].chroma, colors[1].chroma) && close(colors[2].chroma, colors[1].chroma)
    }
}

/// Ember (no accent, no colours), or the one page accent and the three colours derived from it.
public struct TessPaletteChoice: Equatable, Sendable {
    public var accent: AppID?
    public var colors: [OKLCH]

    public static let ember = TessPaletteChoice(accent: nil, colors: [])
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
    public static let maxReactionSeconds = 2.6

    public static func decide(_ director: any TessDirector, _ ask: DirectorAsk,
                              context: DirectorContext) -> DirectorDecision
    {
        // Anything that carries his facts or the kind of place is answered by the rules, whichever director is asked,
        // so
        // a model director never sees them.
        let answering: any TessDirector = carriesFacts(ask) ? RuleDirector() : director
        var decision = answering.decide(ask, context: context)
        decision.choice = clamp(decision.choice, ask: ask, context: context)
        return decision
    }

    static func carriesFacts(_ ask: DirectorAsk) -> Bool {
        if case .scene = ask {
            return true
        }
        return false
    }

    static func clamp(_ choice: DirectorChoice, ask: DirectorAsk, context: DirectorContext) -> DirectorChoice {
        // Low Power is Reduce Motion: no bursts or reactions, and every glide is an instant swap.
        let still = context.reduceMotion || context.lowPower
        switch choice {
        case var .mosaic(decision):
            var before = MosaicSwitchState()
            if case let .mosaic(_, state, _) = ask {
                before = state
            } else if case let .handBack(state) = ask {
                before = state
            }
            if let play = decision.directive.play, context.quiet, !play.name.playsInQuietHours {
                decision.directive.play = nil
                decision.state.playing = before.playing
            }
            // Quiet hours keep the mood he had; they never clear it.
            if context.quiet, let change = decision.directive.mood, change.mood != .night {
                decision.directive.mood = nil
                decision.state.mood = before.mood
            }
            decision.plainSwap = still
            return .mosaic(decision)
        case var .burst(burst):
            clampBurst(&burst.shape, &burst.count, &burst.duration, context: context)
            return .burst(burst)
        case var .tessBurst(burst):
            clampBurst(&burst.shape, &burst.count, &burst.duration, context: context)
            burst.palette = clampTess(burst.palette, context: context)
            return .tessBurst(burst)
        case var .palette(palette):
            palette.mix = min(max(palette.mix, 0), maxPaletteMix)
            palette.duration = still ? 0 : min(max(palette.duration, 0), maxPaletteSeconds)
            return .palette(palette)
        case let .tessPalette(palette):
            return .tessPalette(clampTess(palette, context: context))
        case var .reaction(reaction):
            reaction.duration = min(max(reaction.duration, 0), maxReactionSeconds)
            if still || context.quiet {
                reaction = ReactionChoice(kind: .none, duration: 0)
            }
            return .reaction(reaction)
        case var .scene(scene):
            scene.still = scene.still || still
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

    /// Ember, or the one accent with exactly the palette derived from it. A palette that isn't the derived one is
    /// rebuilt from the accent's own colour; an accent whose colour isn't known falls back to Ember.
    private static func clampTess(_ palette: TessPaletteChoice, context: DirectorContext) -> TessPaletteChoice {
        guard let accent = palette.accent, let own = context.accents[accent] else { return .ember }
        // Kept only when it is exactly the palette derived from this accent's own colour: the right pattern in the
        // wrong hue is rebuilt.
        let derived = TessPalette.derive(from: own, dark: context.dark)
        if TessPalette.matches(palette.colors, derived) {
            return palette
        }
        return TessPaletteChoice(accent: accent, colors: derived)
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
        case let .tessBurst(accents):
            let shape = vary(from: [.ring, .rise, .scatter], context: context, prefix: "burst")
            let palette = Self.palette(pageAccents: accents, context: context)
            return DirectorDecision(choice: .tessBurst(TessBurstChoice(shape: shape, count: 12, duration: 1.2,
                                                                       palette: palette)),
                                    why: "Her own colour, a \(shape.rawValue).", key: "burst-\(shape.rawValue)")
        case let .palette(from, to):
            return DirectorDecision(choice: .palette(PaletteChoice(from: from, to: to, mix: 0.2, duration: 0.6,
                                                                   curve: .easeInOut)),
                                    why: "A light wash toward the page's accent.", key: "palette")
        case let .tessPalette(accents):
            let palette = Self.palette(pageAccents: accents, context: context)
            return DirectorDecision(choice: .tessPalette(palette),
                                    why: palette.accent == nil ? "Ember: no single accent on this page."
                                        : "A palette built from the page's one accent.", key: "tessPalette")
        case let .reaction(event):
            return reaction(event)
        case let .scene(backdrop, facts, place, weather, calendar):
            let scene = MosaicScenePicker.pick(backdrop, facts: facts, place: place, weather: weather,
                                               calendar: calendar)
            return DirectorDecision(choice: .scene(SceneChoice(scene: scene, still: false)),
                                    why: "The hour, the weather and the kind of place.", key: "scene")
        }
    }

    /// Ember is her base. Exactly one accent on the page is clear; with several she stays Ember.
    static func palette(pageAccents: Set<AppID>, context: DirectorContext) -> TessPaletteChoice {
        guard pageAccents.count == 1, let accent = pageAccents.first, let own = context.accents[accent] else {
            return .ember
        }
        return TessPaletteChoice(accent: accent, colors: TessPalette.derive(from: own, dark: context.dark))
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
