import Foundation
@testable import TesseraCore
import Testing

/// A director that asks for everything it shouldn't, to prove the clamps run after it.
private struct WildDirector: TessDirector {
    func decide(_ ask: DirectorAsk, context _: DirectorContext) -> DirectorDecision {
        let wild: DirectorChoice = switch ask {
        case .burst, .tessBurst:
            .burst(BurstChoice(shape: .spray, count: 5000, duration: 99, tone: .glaze))
        case let .palette(from, to):
            .palette(PaletteChoice(from: from, to: to, mix: 1, duration: 30, curve: .spring))
        case .tessPalette:
            .tessPalette(TessPaletteChoice(accent: .training, mix: 1))
        case .reaction:
            .reaction(ReactionChoice(kind: .flipRows, duration: 60))
        case .scene:
            .scene(SceneChoice(scene: .beach, still: false))
        case .mosaic, .handBack:
            .mosaic(MosaicDecision(state: MosaicSwitchState(mood: .running),
                                   directive: MosaicDirective(
                                       mood: MosaicMoodChange(mood: .running, changeover: .wave),
                                       play: MosaicQueuedMoment(name: .best, handBack: .melt, key: "x", sourceRank: 1)
                                   )))
        }
        return DirectorDecision(choice: wild, why: "wild", key: "wild")
    }
}

@MainActor
struct TessDirectorTests {
    func facts() throws -> MosaicFacts {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        return MosaicFacts.make(engine: engine, now: now, calendar: .current, place: (37.8, -122.4), events: [])
    }

    let now = Date(timeIntervalSince1970: 1_792_000_000)

    func context(quiet: Bool = false, reduce: Bool = false, low: Bool = false, seed: UInt64 = 0,
                 recent: [String] = []) -> DirectorContext
    {
        DirectorContext(now: now, quiet: quiet, reduceMotion: reduce, lowPower: low, recent: recent, seed: seed)
    }

    @Test func clampsRunAfterTheDirector() throws {
        let wild = WildDirector()
        guard case let .burst(burst) = TessDirection.decide(wild, .burst(.done, tone: .glaze), context: context())
            .choice
        else { Issue.record("not a burst"); return }
        #expect(burst.count == TessDirection.maxBurstCount && burst.duration == TessDirection.maxBurstSeconds)
        for flag in [(true, false, false), (false, true, false), (false, false, true)] {
            let ctx = context(quiet: flag.0, reduce: flag.1, low: flag.2)
            guard case let .burst(quiet) = TessDirection.decide(wild, .tessBurst, context: ctx).choice
            else { Issue.record("not a burst"); return }
            #expect(quiet.shape == .none && quiet.count == 0 && quiet.duration == 0, "\(flag)")
        }
        guard case let .palette(palette) = TessDirection.decide(wild, .palette(from: .glaze, to: .accent(.training)),
                                                                context: context(reduce: true)).choice
        else { Issue.record("not a palette"); return }
        #expect(palette.mix == TessDirection.maxPaletteMix && palette.duration == 0)
        guard case let .tessPalette(tess) = TessDirection.decide(wild, .tessPalette(pageAccents: [:]),
                                                                 context: context()).choice
        else { Issue.record("not a tess palette"); return }
        #expect(tess.mix == TessDirection.maxTessMix)
        guard case let .reaction(reaction) = TessDirection.decide(
            wild, .reaction(.opened(away: 600, firstOpenAfterFour: false, momentPlaying: false)),
            context: context()
        ).choice else { Issue.record("not a reaction"); return }
        #expect(reaction.duration == TessDirection.maxReactionSeconds)
        guard case let .reaction(still) = TessDirection.decide(
            wild, .reaction(.opened(away: 600, firstOpenAfterFour: false, momentPlaying: false)),
            context: context(reduce: true)
        ).choice else { Issue.record("not a reaction"); return }
        #expect(still.kind == .none)
        guard case let .scene(scene) = TessDirection.decide(
            wild, .scene(.tessPicks, facts: try facts(), place: nil, weather: nil, calendar: .current),
            context: context(low: true)
        ).choice else { Issue.record("not a scene"); return }
        #expect(scene.still)
    }

    @Test func quietHoursStripAWildMomentAndMood() {
        guard case let .mosaic(decision) = TessDirection.decide(WildDirector(),
                                                                .mosaic(cues: [], state: .init(), weatherOn: false),
                                                                context: context(quiet: true)).choice
        else { Issue.record("not a mosaic decision"); return }
        #expect(decision.directive.play == nil && decision.directive.mood == nil)
    }

    @Test func ruleDirectorFollowsTheSwitchboard() {
        let cues = [MosaicCue(.newBest, at: now, key: "b")]
        guard case let .mosaic(decision) = TessDirection.decide(
            RuleDirector(), .mosaic(cues: cues, state: .init(), weatherOn: false), context: context()
        ).choice else { Issue.record("not a mosaic decision"); return }
        #expect(decision.directive.play?.name == .best)
    }

    @Test func tessKeepsEmberUnlessOnePageAccentClearlyLeads() {
        func accent(_ shares: [AppID: Double]) -> AppID? {
            guard case let .tessPalette(choice) = TessDirection.decide(
                RuleDirector(), .tessPalette(pageAccents: shares), context: context()
            ).choice else { return nil }
            return choice.accent
        }
        #expect(accent([:]) == nil)
        #expect(accent([.training: 0.6, .kitchen: 0.1]) == .training)
        #expect(accent([.training: 0.4, .kitchen: 0.35, .lists: 0.25]) == nil)
        #expect(accent([.training: 0.5, .kitchen: 0.4]) == nil)
    }

    @Test func burstsVaryButAreRepeatable() {
        func shape(_ ctx: DirectorContext) -> BurstShape? {
            guard case let .burst(choice) = TessDirection.decide(RuleDirector(), .burst(.done, tone: .glaze),
                                                                 context: ctx).choice else { return nil }
            return choice.shape
        }
        let first = shape(context(seed: 4))
        #expect(first == shape(context(seed: 4)))
        let second = shape(context(seed: 4, recent: ["burst-\(first?.rawValue ?? "")"]))
        #expect(second != first)
    }

    @Test func openReactionsFollowTheTimeAway() {
        func kind(_ away: TimeInterval?, after4: Bool = false, playing: Bool = false) -> OpenReactionKind? {
            guard case let .reaction(choice) = TessDirection.decide(
                RuleDirector(), .reaction(.opened(away: away, firstOpenAfterFour: after4, momentPlaying: playing)),
                context: context()
            ).choice else { return nil }
            return choice.kind
        }
        #expect(kind(30) == .ripple)
        #expect(kind(3600) == .flipRows)
        #expect(kind(3600, after4: true) == .nightFalls)
        #expect(kind(3 * 86400, after4: true) == .gatherBack)
        #expect(kind(nil) == .gatherFromNight)
        #expect(kind(30, playing: true) == OpenReactionKind.none)
    }

    @Test func theDirectorSeesNoWordsOfHis() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../Sources/TesseraCore/Director/TessDirector.swift").standardized
        let text = try String(contentsOf: root, encoding: .utf8)
        for banned in ["title:", "ObjectRecord", "ObjectStore", "URLSession", "import HealthKit", "EventKit"] {
            #expect(!text.contains(banned), "\(banned)")
        }
    }
}
