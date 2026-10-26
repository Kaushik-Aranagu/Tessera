import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Harness H2: the playbook, its director, its store and the job that fills it.
@MainActor
struct PlaybookTests {
    let now = Date(timeIntervalSince1970: 1_792_000_000)
    let accents: [AppID: OKLCH] = [.training: OKLCH(lightness: 0.5, chroma: 0.1, hue: 25),
                                   .kitchen: OKLCH(lightness: 0.5, chroma: 0.2, hue: 150)]

    func context(quiet: Bool = false, reduce: Bool = false) -> DirectorContext {
        DirectorContext(now: now, quiet: quiet, reduceMotion: reduce, accents: accents, seed: 3)
    }

    /// Whys as they show (no closing stop), so a stored playbook reads back equal after the clamp.
    func playbook() -> DirectorPlaybook {
        var book = DirectorPlaybook(day: "2026-10-24")
        book.burst[.done] = PlaybookEntry(
            PlaybookBurst(shape: .ring, count: 14, seconds: 1.4),
            why: "A calm ring suits the morning"
        )
        book.tessPalette["training"] = PlaybookEntry(
            PlaybookPalette(accent: .training),
            why: "On the training page her ember takes its red"
        )
        book.reaction[.underOneHour] = PlaybookEntry(
            PlaybookReaction(kind: .flipRows, seconds: 1.1),
            why: "Back quickly, so the tiles flip"
        )
        return book
    }

    // MARK: Director

    @Test func withNoPlaybookEveryChoiceIsTheRulesChoice() {
        let rules = RuleDirector()
        let playbook = PlaybookDirector(playbook: nil)
        let asks: [DirectorAsk] = [
            .burst(.done, tone: .glaze), .burst(.best, tone: .accent(.training)), .tessBurst(pageAccents: [.training]),
            .tessPalette(pageAccents: [.training]), .tessPalette(pageAccents: [.training, .kitchen]),
            .reaction(.opened(away: 30, firstOpenAfterFour: false, momentPlaying: false)),
            .reaction(.opened(away: nil, firstOpenAfterFour: false, momentPlaying: false)),
        ]
        for ask in asks {
            let ours = TessDirection.decide(playbook, ask, context: context())
            let theirs = TessDirection.decide(rules, ask, context: context())
            #expect("\(ours.choice)" == "\(theirs.choice)" && ours.why == theirs.why)
        }
    }

    @Test func anEntryGivesTheChoiceAndItsWhy() {
        let director = PlaybookDirector(playbook: playbook())
        guard case let .burst(burst) = TessDirection.decide(director, .burst(.done, tone: .glaze), context: context())
            .choice
        else { Issue.record("not a burst"); return }
        #expect(burst.shape == .ring && burst.count == 14 && burst.duration == 1.4)
        #expect(TessDirection.decide(director, .burst(.done, tone: .glaze), context: context())
            .why == "A calm ring suits the morning")
        // An ask with no entry (another kind) is the rules'.
        let other = TessDirection.decide(director, .burst(.best, tone: .glaze), context: context())
        #expect(other.why == TessDirection.decide(RuleDirector(), .burst(.best, tone: .glaze), context: context()).why)
        let palette = TessDirection.decide(director, .tessPalette(pageAccents: [.training]), context: context())
        guard case let .tessPalette(choice) = palette.choice else { Issue.record("not a palette"); return }
        #expect(choice.accent == .training && choice.colors.count == 3 && palette.why.contains("red"))
        let reaction = TessDirection.decide(director, .reaction(.opened(away: 600, firstOpenAfterFour: false,
                                                                        momentPlaying: false)), context: context())
        guard case let .reaction(chosen) = reaction.choice else { Issue.record("not a reaction"); return }
        #expect(chosen.kind == .flipRows && chosen.duration == 1.1 && reaction
            .why == "Back quickly, so the tiles flip")
    }

    @Test func aMomentPlayingAndAColdLaunchStayWithTheRules() {
        var book = playbook()
        book.reaction[.firstOpenAfterFour] = PlaybookEntry(
            PlaybookReaction(kind: .nightFalls, seconds: 2),
            why: "Night falls away"
        )
        let director = PlaybookDirector(playbook: book)
        let playing = TessDirection.decide(director, .reaction(.opened(away: 30, firstOpenAfterFour: true,
                                                                       momentPlaying: true)), context: context())
        guard case let .reaction(none) = playing.choice else { return }
        #expect(none.kind == .none)
        let cold = TessDirection.decide(director, .reaction(.opened(away: nil, firstOpenAfterFour: false,
                                                                    momentPlaying: false)), context: context())
        guard case let .reaction(gather) = cold.choice else { return }
        #expect(gather.kind == .gatherFromNight)
    }

    @Test func anOutOfRangeEntryComesBackClampedEverywhere() {
        var book = DirectorPlaybook(day: "d")
        book.burst[.done] = PlaybookEntry(PlaybookBurst(shape: .spray, count: 99, seconds: 9), why: "A wild one")
        book.reaction[.overEightHours] = PlaybookEntry(
            PlaybookReaction(kind: .gatherBack, seconds: 40),
            why: "A wild one"
        )
        let clamped = book.clamped()
        #expect(clamped.burst[.done]?.choice.count == TessDirection.maxBurstCount)
        #expect(clamped.burst[.done]?.choice.seconds == TessDirection.maxBurstSeconds)
        #expect(clamped.reaction[.overEightHours]?.choice.seconds == TessDirection.maxReactionSeconds)
        // Even an unclamped book handed straight to a director is clamped on the way in and again by the clamps.
        var raw = PlaybookDirector(playbook: nil)
        raw.playbook = book
        guard case let .burst(burst) = TessDirection.decide(raw, .burst(.done, tone: .glaze), context: context()).choice
        else { Issue.record("not a burst"); return }
        #expect(burst.count == TessDirection.maxBurstCount && burst.duration == TessDirection.maxBurstSeconds)
        // And Reduce Motion / quiet still silence it after the playbook.
        guard case let .burst(still) = TessDirection.decide(
            PlaybookDirector(playbook: book),
            .burst(.done, tone: .glaze),
            context: context(reduce: true)
        ).choice
        else { Issue.record("not a burst"); return }
        #expect(still.shape == .none && still.count == 0)
    }

    @Test func aBadEntryIsDroppedAloneAndOnlyOneClearAccentCounts() {
        var book = playbook()
        book.burst[.best] = PlaybookEntry(PlaybookBurst(shape: .rise, count: 5, seconds: 1), why: "")
        book.tessPalette["kitchen,training"] = PlaybookEntry(
            PlaybookPalette(accent: .training),
            why: "Two accents here"
        )
        book.tessPalette["kitchen"] = PlaybookEntry(PlaybookPalette(accent: .training), why: "Wrong app")
        book.tessPalette["nonsense"] = PlaybookEntry(PlaybookPalette(accent: nil), why: "Unknown page")
        let clamped = book.clamped()
        #expect(clamped.burst[.best] == nil && clamped.burst[.done] != nil)
        #expect(clamped.tessPalette.keys.sorted() == ["training"])
        #expect(clamped.reaction[.underOneHour] != nil)
    }

    @Test func aPlaybookRoundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode(playbook())
        let back = try JSONDecoder().decode(DirectorPlaybook.self, from: data)
        #expect(back == playbook())
    }

    @Test func awayBucketsFollowTheRule() {
        #expect(AwayBucket.bucket(away: 1800, firstOpenAfterFour: false) == .underOneHour)
        #expect(AwayBucket.bucket(away: 3 * 3600, firstOpenAfterFour: false) == .oneToEightHours)
        #expect(AwayBucket.bucket(away: 9 * 3600, firstOpenAfterFour: false) == .overEightHours)
        #expect(AwayBucket.bucket(away: 60, firstOpenAfterFour: true) == .firstOpenAfterFour)
        #expect(AwayBucket.bucket(away: nil, firstOpenAfterFour: false) == nil)
    }

    // MARK: Store

    func tempURL() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(PlaybookStore.fileName)
    }

    @Test func theStoreIsKeyedByDayClampedOnReadAndOutOfBackups() throws {
        let url = try tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = PlaybookStore(url: url)
        #expect(store.playbook(day: "2026-10-24") == nil && store.runs(day: "2026-10-24") == 0)
        store.save(playbook(), day: "2026-10-24")
        #expect(store.playbook(day: "2026-10-24") == playbook() && store.runs(day: "2026-10-24") == 1)
        #expect(store.playbook(day: "2026-10-25") == nil)
        let excluded = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        #expect(excluded == true)
        // A file edited to something wild is clamped as it is read.
        var raw = try String(decoding: Data(contentsOf: url), as: UTF8.self)
        raw = raw.replacingOccurrences(of: "\"count\":14", with: "\"count\":99")
        try Data(raw.utf8).write(to: url)
        #expect(store.playbook(day: "2026-10-24")?.burst[.done]?.choice.count == TessDirection.maxBurstCount)
    }

    // MARK: Job

    func toolInput() -> Data {
        let burst: (String, Int) -> [String: Any] = { shape, count in
            ["shape": shape, "count": count, "seconds": 1.2, "why": "It fits the day"]
        }
        let reaction: (String) -> [String: Any] = { ["kind": $0, "seconds": 1.0, "why": "It fits the day"] }
        let body: [String: Any] = [
            "palette": [["app": "training", "accent": "training", "why": "The page is red"],
                        ["app": "kitchen", "accent": "ember", "why": "Keep her ember"]],
            "burst": ["done": burst("rise", 99), "best": burst("ring", 10), "finished": burst("spray", 8),
                      "arrived": burst("scatter", 6)],
            "reaction": ["underOneHour": reaction("ripple"), "oneToEightHours": reaction("flipRows"),
                         "overEightHours": reaction("gatherBack"), "firstOpenAfterFour": reaction("nightFalls")],
        ]
        return (try? JSONSerialization.data(withJSONObject: body)) ?? Data()
    }

    let inputs = PlaybookJob.Inputs(partOfDay: "morning", weekday: "Saturday", quiet: false, reduceMotion: false,
                                    accents: [.training, .kitchen], recent: ["burst-ring", "reaction-ripple"])

    func job(_ rig: DoorRig, url: URL, enabled: Bool = true) -> PlaybookJob {
        var job = PlaybookJob(door: rig.door, store: PlaybookStore(url: url), enabled: { enabled })
        job.now = { Date(timeIntervalSince1970: 1_792_000_000) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        job.calendar = calendar
        return job
    }

    @Test func aFillWritesAClampedPlaybookAndShowsInTheTraceAndSentLog() async throws {
        let url = try tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let haiku = FakeBrain(.haiku)
        haiku.toolInput = toolInput()
        let rig = try DoorRig(brains: [.haiku: haiku])
        let job = job(rig, url: url)
        let result = await job.fill(inputs)
        guard case let .filled(book) = result else { Issue.record("not filled: \(result)"); return }
        #expect(book.burst[.done]?.choice.count == TessDirection.maxBurstCount)
        #expect(book.tessPalette["training"]?.choice.accent == .training && book.tessPalette["kitchen"]?.choice
            .accent == nil)
        #expect(book.reaction.count == 4)
        #expect(PlaybookStore(url: url).playbook(day: job.day()) == book)
        // The call is in the trace and the sent log, and the words are only facts: no word of his.
        #expect(await rig.trace.all().contains { $0.name == "director-playbook" })
        let sent = try #require(rig.sent.entries().first)
        let words = rig.sent.words(of: sent)
        #expect(words.contains("part of day: morning") && words.contains("apps: training, kitchen"))
        let request = try #require(haiku.lastRequest)
        #expect(request.effort == .low && request.toolChoice == .tool("setPlaybook") && request.tools.count == 1)
        #expect(request.tools[0].strict)
    }

    @Test func claudeOffOfflineOverTheCapOrTheFlagOffMeansTheRules() async throws {
        let url = try tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let haiku = FakeBrain(.haiku)
        haiku.toolInput = toolInput()
        // Tess asks Claude off.
        let off = try DoorRig(brains: [.haiku: haiku], asks: false)
        #expect(await job(off, url: url).fill(inputs) == .skipped("no playbook"))
        #expect(haiku.streamCount == 0)
        // Offline.
        let offline = FakeBrain(.haiku)
        offline.outcome = .offline
        let down = try DoorRig(brains: [.haiku: offline])
        #expect(await job(down, url: url).fill(inputs) == .skipped("no playbook"))
        // The flag off: no call and no run counted.
        let rig = try DoorRig(brains: [.haiku: haiku])
        let before = PlaybookStore(url: url).runs(day: job(rig, url: url).day())
        #expect(await job(rig, url: url, enabled: false).fill(inputs) == .skipped("flag off"))
        #expect(PlaybookStore(url: url).runs(day: job(rig, url: url).day()) == before)
        // None of these left a playbook: the rules answer.
        #expect(PlaybookStore(url: url).playbook(day: job(rig, url: url).day())?.burst.isEmpty ?? true)
    }

    @Test func itRunsAtMostThreeTimesADay() async throws {
        let url = try tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let haiku = FakeBrain(.haiku)
        haiku.toolInput = toolInput()
        let rig = try DoorRig(brains: [.haiku: haiku])
        let job = job(rig, url: url)
        for _ in 0 ..< 3 {
            _ = await job.fill(inputs)
        }
        #expect(await job.fill(inputs) == .skipped("three runs today") && haiku.streamCount == 3)
    }

    @Test func aGarbledToolCallMakesNoPlaybook() async throws {
        let url = try tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let haiku = FakeBrain(.haiku)
        haiku.toolInput = Data(#"{"palette":"nope"}"#.utf8)
        let rig = try DoorRig(brains: [.haiku: haiku])
        #expect(await job(rig, url: url).fill(inputs) == .skipped("no playbook"))
    }

    @Test func theSchemaIsBuiltFromTheDirectorsEnums() {
        let text = String(decoding: PlaybookJob.schema, as: UTF8.self)
        for shape in BurstShape.allCases {
            #expect(text.contains("\"\(shape.rawValue)\""), "\(shape)")
        }
        for kind in OpenReactionKind.allCases {
            #expect(text.contains("\"\(kind.rawValue)\""), "\(kind)")
        }
        for bucket in AwayBucket.allCases {
            #expect(text.contains("\"\(bucket.rawValue)\""))
        }
    }

    // MARK: Review notes from #1365

    @Test func theMoneyToolListIsTheMoneyActionDescriptors() throws {
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/TesseraCore/Money")
        let registered = Set(ActionRegistry.descriptors.map(\.name))
        var declared = Set<String>()
        for file in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            where file.pathExtension == "swift"
        {
            let text = try String(contentsOf: file, encoding: .utf8)
            for match in text.matches(of: /ActionDescriptor\(\s*name: "([A-Za-z]+)"/) {
                declared.insert(String(match.1))
            }
        }
        #expect(!declared.isEmpty)
        #expect(
            declared.intersection(registered) == Door.moneyActions,
            "\(declared.symmetricDifference(Door.moneyActions))"
        )
    }

    @Test func strictKeepsCalendarFragmentsOffClaudeWhenTheyAreTaggedDeviceOnly() async throws {
        // Callers must tag calendar text deviceOnly: the Door's strict scan judges words, and a title like "Dentist at
        // 3 pm" is not a wall word. Tagged, it never reaches a Claude rung under strict.
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain], policy: .strict)
        let job = DoorJob(name: "t", ladder: [.haiku], request: DoorTests.ask,
                          fragments: [PackFragment("Dentist at 3 pm", taint: .deviceOnly), PackFragment("Sunny")],
                          estimateNano: 1000)
        _ = await rig.events(job)
        let sent = try Door.words(#require(brain.lastRequest))
        #expect(!sent.contains("Dentist") && sent.contains("Sunny"))
    }

    // MARK: Review notes from #1367

    @Test func aWhyThatFailsTheLineCheckOrTheWallsIsReplacedAndTheChoiceStands() {
        let bad = [
            "Weight is 82.4 kg today so go calm", // body fact
            "Rent 1450 is due so keep it calm", // money
            "Lunch 650 kcal means a big burst", // calories
            "sk-" + "ant-" + "api03-" + String(repeating: "Ab3x", count: 8) + ".", // key-shaped
            "Two sentences. Too many", // not one sentence
<<<<<<< HEAD
            "This sentence runs on far too long for the small space it has to fit into today", // too long
=======
            "This sentence runs on far too long for the small space it has to fit into today.", // too long
>>>>>>> origin/master
        ]
        for why in bad {
            var book = DirectorPlaybook(day: "d")
            book.burst[.done] = PlaybookEntry(PlaybookBurst(shape: .ring, count: 10, seconds: 1), why: why)
            let entry = book.clamped().burst[.done]
            #expect(entry?.why == DirectorPlaybook.neutralWhy && entry?.choice.shape == .ring, "\(why)")
        }
        var good = DirectorPlaybook(day: "d")
        good.burst[.done] = PlaybookEntry(
            PlaybookBurst(shape: .ring, count: 10, seconds: 1),
            why: "A calm ring suits the morning"
        )
        // Shown with no closing stop (Kaushik, Oct 26), and a why with none passes.
        #expect(good.clamped().burst[.done]?.why == "A calm ring suits the morning")
    }

    @Test func theInstructionsSayThePersonAndAskForALineTheCheckPasses() {
        #expect(!PlaybookJob.instructions.contains(" he ") && PlaybookJob.instructions.contains("the person"))
        #expect(PlaybookJob.instructions.contains("14 words"))
    }
}
