import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Harness H3: the Tess loop. Fake brains only; no network, no real clock deciding order.
@MainActor
struct TessRunTests {
    func tempURL() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(TessRunStore.fileName)
    }

    @MainActor struct Rig {
        let rig: DoorRig
        let run: TessRun
        let conversation: TessConversation
        let url: URL
        var engine: ActionEngine {
            run.engine
        }
    }

    func rig(_ brains: [BrainID: any Brain], asks: Bool = true, policy: DoorPolicy = .lab,
             flag: Bool = true) throws -> Rig
    {
        let url = try tempURL()
        let rig = try DoorRig(brains: brains, asks: asks, policy: policy)
        let engine = ActionEngine(store: rig.store, classes: rig.classes)
        let conversation = TessConversation(store: rig.store, classes: rig.classes)
        let run = TessRun(door: rig.door, engine: engine, conversation: conversation, runs: TessRunStore(url: url))
        run.flagOn = { flag }
        return Rig(rig: rig, run: run, conversation: conversation, url: url)
    }

    func collect(_ stream: AsyncStream<TessRunEvent>) async -> [TessRunEvent] {
        var events: [TessRunEvent] = []
        for await event in stream {
            events.append(event)
        }
        return events
    }

    func use(_ id: String, _ name: String, _ json: String) -> BrainEvent {
        .toolUse(id: id, name: name, input: Data(json.utf8))
    }

    // MARK: Words and rungs

    @Test func wordsStreamInOrderAndFinishedIsTheirJoin() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Hello "), .text("there.")]])
        let r = try rig([.haiku: haiku])
        let events = await collect(r.run.ask("how many sets today"))
        #expect(events.first == .waiting)
        let words = events.compactMap {
            if case let .words(piece) = $0 {
                piece
            } else {
                nil
            }
        }
        #expect(words == ["Hello ", "there."])
        #expect(events.last == .finished("Hello there."))
    }

    @Test func pickRungSendsOpenQuestionsToSonnetAndLookupsToHaiku() {
        #expect(pickRung("how am I doing on legs?").ladder == [.sonnet, .opus, .appleOnDevice])
        #expect(!pickRung("how am I doing on legs?").hedge)
        #expect(pickRung("how many sets today").ladder == [.haiku, .sonnet, .appleOnDevice])
        #expect(!pickRung("how many sets today").hedge && pickRung("how many sets today").toolChoice == .auto)
        for open in ["why is my bench stuck", "should I deload", "plan my week", "compare this week to last",
                     "what do you think about my split"]
        {
            #expect(pickRung(open) == .open, "\(open)")
        }
        let long = Array(repeating: "word", count: 19).joined(separator: " ")
        #expect(pickRung(long) == .open && pickRung("add milk to groceries") == .plain)
        #expect(RungPlan.open.maxTokens == 12000 && RungPlan.plain.maxTokens == 4096 && RungPlan.open.effort == .medium)
        // Opus is never a first rung, in any plan.
        #expect(![RungPlan.open, .plain, .deviceOnly].contains { $0.ladder.first == .opus })
    }

    // MARK: Tools

    @Test func twoReadsReturnInOneToolResultMessage() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [
            [use("t1", "query", #"{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#),
             use("t2", "query", #"{"from":["notes"],"during":{"range":"today","field":null},"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#)],
            [.text("Two answers.")],
        ])
        let r = try rig([.haiku: haiku])
        let events = await collect(r.run.ask("how many tasks and notes"))
        #expect(events.last == .finished("Two answers."))
        let second = try #require(haiku.requestsSeen.last)
        let lastMessage = try #require(second.messages.last)
        let results = lastMessage.content.compactMap { piece -> String? in
            if case let .toolResult(id, _, _) = piece {
                id
            } else {
                nil
            }
        }
        #expect(lastMessage.role == .user && results == ["t1", "t2"])
        #expect(haiku.streamCount == 2)
    }

    @Test func twoWritesRunInOrderAndEachLeavesAGhost() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [
            [use("t1", "createTask", #"{"title":"Call mom","startsAt":null,"about":[]}"#),
             use("t2", "createTask", #"{"title":"Buy stamps","startsAt":null,"about":[]}"#)],
            [.text("Added both.")],
        ])
        let r = try rig([.haiku: haiku])
        let events = await collect(r.run.ask("add two tasks"))
        let ghosts = events.compactMap {
            if case let .ghost(id) = $0 {
                id
            } else {
                nil
            }
        }
        #expect(ghosts.count == 2)
        let pending = r.engine.history(limit: 20).filter { $0.state == .pending }
        // Oldest first: the first write is the first ghost.
        #expect(ghosts == pending.reversed().map(\.id))
        #expect(events.last == .finished("Added both."))
    }

    @Test func anEleventhRoundIsNeverSentAndThePhoneLineComesBack() async throws {
        let call = [use("t", "query", #"{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#)]
        let haiku = ScriptedBrain(.haiku, rounds: Array(repeating: call, count: 12) + [[.text("never")]])
        let r = try rig([.haiku: haiku])
        let events = await collect(r.run.ask("keep looking"))
        #expect(haiku.streamCount == 10 && TessRun.maxRounds == 10)
        #expect(events.last == .failed(TessRun.tooManySteps))
        #expect(!events.contains(.words("never")))
    }

    // MARK: M0 in the loop

    @Test func aPausedTurnIsSentBackUnchangedAndDoesNotUseARound() async throws {
        let block = Data(#"{"type":"thinking","signature":"s==","thinking":"hm"}"#.utf8)
        let search = Data(SearchBlocks.result.utf8)
        // Two paused turns, then three tool rounds' worth of room is still left: the final answer arrives on stream 3.
        let haiku = ScriptedBrain(.haiku, rounds: [
            [.assistant([block, search]), .done(BrainUsage(), stop: "pause_turn")],
            [.assistant([block]), .done(BrainUsage(), stop: "pause_turn")],
            [.text("Found it.")],
        ])
        let r = try rig([.haiku: haiku])
        let events = await collect(r.run.ask("how many sets"))
        #expect(events.last == .finished("Found it.") && haiku.streamCount == 3)
        let third = try #require(haiku.requestsSeen.last)
        let assistant = third.messages.filter { $0.role == .assistant }
        #expect(assistant.count == 2)
        #expect(assistant[0].content == [.raw(block), .raw(search)])
        #expect(assistant[1].content == [.raw(block)])
    }

    @Test func aToolRoundReplaysTheAssistantMessageVerbatim() async throws {
        let thinking = Data(#"{"type":"thinking","signature":"sig==","thinking":"let me count"}"#.utf8)
        let use = Data(#"{"type":"tool_use","id":"t1","name":"query","input":{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}}"#
            .utf8)
        let haiku = ScriptedBrain(.haiku, rounds: [
            [.assistant([thinking, use]), self.use("t1", "query", #"{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#)],
            [.text("Three.")],
        ])
        let r = try rig([.haiku: haiku])
        _ = await collect(r.run.ask("how many tasks"))
        let second = try #require(haiku.requestsSeen.last)
        let assistant = try #require(second.messages.first { $0.role == .assistant })
        #expect(assistant.content == [.raw(thinking), .raw(use)])
    }

    @Test func aRunStopsAtFivePauses() async throws {
        let pause: [BrainEvent] = [.assistant([Data(#"{"type":"text","text":"."}"#.utf8)]),
                                   .done(BrainUsage(), stop: "pause_turn")]
        let haiku = ScriptedBrain(.haiku, rounds: Array(repeating: pause, count: 8))
        let r = try rig([.haiku: haiku])
        let events = await collect(r.run.ask("how many sets"))
        // Five paused turns are sent back; the sixth stream's pause is the last thing she takes.
        #expect(haiku.streamCount == 6 && events.last?.isTerminal == true)
    }

    // MARK: Review notes from #1380

    @Test func theDayDigestIsDeviceOnlyAndTheRequestThinks() async throws {
        for policy in [DoorPolicy.lab, .strict] {
            let haiku = ScriptedBrain(.haiku, rounds: [[.text("ok")]])
            let r = try rig([.haiku: haiku], policy: policy)
            r.run.dayDigest = { "Dentist at 3 pm, slept 5 hours" }
            _ = await collect(r.run.ask("how many sets"))
            let request = try #require(haiku.requestsSeen.first)
            #expect(Door.words(request).contains("Dentist") == (policy == .lab), "\(policy)")
            // Adaptive thinking is on for a Tess turn.
            #expect(request.thinking)
        }
    }

    @Test func aSettledCheckpointKeepsNoWordsOfTheConversation() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Four sets.")]])
        let r = try rig([.haiku: haiku])
        _ = await collect(r.run.ask("how many sets today"))
        let state = try #require(TessRunStore(url: r.url).all().first)
        #expect(state.status == .finished && state.messages.isEmpty && state.words.isEmpty)
        #expect(state.toolResults.isEmpty && state.askText.isEmpty && state.aboutIDs.isEmpty)
        let text = try String(decoding: Data(contentsOf: r.url), as: UTF8.self)
        #expect(!text.contains("how many sets today") && !text.contains("Four sets."))
    }

    @Test func aRunOlderThanTenMinutesIsDroppedNotResumed() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("never")]])
        let r = try rig([.haiku: haiku])
        let input = Data(#"{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#.utf8)
        var state = TessRunState(startedAt: Date().addingTimeInterval(-11 * 60), askText: "how many", aboutIDs: [],
                                 messages: [BrainMessage(.user, text: "how many"),
                                            BrainMessage(
                                                .assistant,
                                                [.toolUse(id: "t1", name: "query", input: input)]
                                            )])
        state.doneToolIDs = ["t1"]
        state.toolResults = ["t1": "3 tasks."]
        TessRunStore(url: r.url).save(state)
        await r.run.resumeInterrupted()
        #expect(TessRunStore(url: r.url).all().first?.status == .dropped && haiku.streamCount == 0)
    }

    @Test func theHoldCoversTheDearestRungOnTheLadder() async throws {
        let sonnet = FakeBrain(.sonnet)
        let rig = try rig([.sonnet: sonnet])
        let held = HeldDuringSend()
        let ledger = rig.rig.ledger
        sonnet.onStream = { _ in Task { @MainActor in held.value = ledger.pendingNano } }
        _ = await collect(rig.run.ask("why is my bench stuck"))
        try await Task.sleep(for: .milliseconds(50))
        // Output alone at Opus's price for the 12K reserve is 240M nano-dollars; Sonnet's would be 120M.
        #expect(held.value >= 12000 * 20000, "\(held.value)")
        #expect(TessRun.claudeModel(for: .opus) == .opus && TessRun.claudeModel(for: .appleOnDevice) == nil)
    }

    // MARK: Checkpoints

    @Test func aKillAfterAFinishedToolResumesWithoutRunningItAgain() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Added.")]])
        let r = try rig([.haiku: haiku])
        // The run was killed after createTask finished: its ghost is in the op log, the result is stored.
        let input = Data(#"{"title":"Call mom","startsAt":null,"about":[]}"#.utf8)
        try TessTools.run("createTask", arguments: input, engine: r.engine)
        let before = r.engine.history(limit: 50).count
        var state = TessRunState(startedAt: .now, askText: "add call mom", aboutIDs: [],
                                 messages: [BrainMessage(.user, text: "add call mom"),
                                            BrainMessage(
                                                .assistant,
                                                [.toolUse(id: "t1", name: "createTask", input: input)]
                                            )])
        state.doneToolIDs = ["t1"]
        state.toolResults = ["t1": "Done: 1 waiting for approval."]
        TessRunStore(url: r.url).save(state)
        await r.run.resumeInterrupted()
        #expect(r.engine.history(limit: 50).count == before)
        let sent = try #require(haiku.requestsSeen.first)
        #expect(sent.messages.last?.content.contains {
            if case let .toolResult(id, content, false) = $0 {
                id == "t1" && content.hasPrefix("Done")
            } else {
                false
            }
        } == true)
        #expect(TessRunStore(url: r.url).all().first?.status == .finished)
        // Her reply is stored.
        #expect(r.conversation.turns().contains { r.conversation.text(of: $0) == "Added." })
    }

    @Test func aKillMidStreamDropsTheRunAndStoresNoTurn() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("never")]])
        let r = try rig([.haiku: haiku])
        let state = TessRunState(startedAt: .now, askText: "how many sets", aboutIDs: [],
                                 messages: [BrainMessage(.user, text: "how many sets")])
        TessRunStore(url: r.url).save(state)
        await r.run.resumeInterrupted()
        #expect(TessRunStore(url: r.url).all().first?.status == .dropped)
        #expect(haiku.streamCount == 0 && r.conversation.turns().isEmpty)
    }

    @Test func aWriteThatNeverFinishedIsNotRunOnResume() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Sorry about that.")]])
        let r = try rig([.haiku: haiku])
        let write = Data(#"{"title":"Call mom","startsAt":null,"about":[]}"#.utf8)
        let read = Data(#"{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#.utf8)
        var state = TessRunState(startedAt: .now, askText: "do it", aboutIDs: [], messages: [
            BrainMessage(.user, text: "do it"),
            BrainMessage(.assistant, [.toolUse(id: "r1", name: "query", input: read),
                                      .toolUse(id: "w1", name: "createTask", input: write)]),
        ])
        state.doneToolIDs = ["r1"]
        state.toolResults = ["r1": "3 tasks."]
        TessRunStore(url: r.url).save(state)
        let before = r.engine.history(limit: 50).count
        await r.run.resumeInterrupted()
        #expect(r.engine.history(limit: 50).count == before)
        let results = haiku.requestsSeen.first?.messages.last?.content ?? []
        #expect(results.count == 2)
        #expect(results.contains {
            if case let .toolResult("w1", _, true) = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func checkpointsStayUnderTwentyRunsAndADay() throws {
        let url = try tempURL()
        let store = TessRunStore(url: url)
        for index in 0 ..< 25 {
            store.save(TessRunState(startedAt: Date(timeIntervalSince1970: 1_000_000 + Double(index)), askText: "t",
                                    aboutIDs: [], messages: []), now: Date(timeIntervalSince1970: 1_000_100))
        }
        #expect(store.all(now: Date(timeIntervalSince1970: 1_000_100)).count == 20)
        #expect(store.all(now: Date(timeIntervalSince1970: 1_000_000 + 2 * 86400)).isEmpty)
        let excluded = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        #expect(excluded == true)
    }

    // MARK: Traces and runs

    @Test func everySpanOfARunCarriesItsRunIDAndNoSpanHoldsTheAsk() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [
            [use("t1", "query", #"{"from":["tasks"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#)], [.text("Fine.")],
        ])
        let r = try rig([.haiku: haiku])
        let secret = "zebra-lantern-question"
        _ = await collect(r.run.ask("how many tasks \(secret)"))
        let spans = await r.rig.trace.all()
        let runID = try #require(TessRunStore(url: r.url).all().first?.id)
        #expect(spans.count >= 3 && spans.allSatisfy { $0.runID == runID })
        #expect(spans.contains { $0.kind == .tool && $0.name == "query" })
        let json = try String(decoding: JSONEncoder().encode(spans), as: UTF8.self)
        #expect(!json.contains(secret) && !json.contains("tasks\\\":"))
    }

    @Test func aNewAskCancelsTheOldRunAndTheSameAskJoinsIt() async throws {
        let slow = ScriptedBrain(.haiku, rounds: [[.text("first")], [.text("second")]])
        slow.delay = .seconds(3600)
        let r = try rig([.haiku: slow])
        let first = r.run.ask("how many tasks")
        let joined = r.run.ask("how many tasks")
        // The same text within 10 s is one Door call.
        for _ in 0 ..< 1000 where slow.streamCount < 1 {
            try await Task.sleep(for: .milliseconds(10))
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(slow.streamCount == 1, "\(slow.streamCount)")
        slow.delay = .zero
        let second = r.run.ask("something else entirely")
        let events = await collect(second)
        #expect(events.last == .finished("first") || events.last == .finished("second"))
        // The cancelled run's streams end without a terminal event.
        let old = await collect(first), alsoOld = await collect(joined)
        #expect(!old.contains { $0.isTerminal } && !alsoOld.contains { $0.isTerminal })
    }

    // MARK: Gates

    @Test func withClaudeOffNothingReachesAClaudeBrainAndOnlyThePhoneAnswers() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("claude")]])
        let apple = ScriptedBrain(.appleOnDevice, rounds: [[.text("phone")]])
        let r = try rig([.haiku: haiku, .appleOnDevice: apple], asks: false)
        let events = await collect(r.run.ask("why is my bench stuck"))
        #expect(events.last == .finished("phone") && haiku.streamCount == 0)
        #expect(apple.requestsSeen.first?.tools.isEmpty == true)
        // The flag Off is the same.
        let flagged = try rig([.haiku: haiku, .appleOnDevice: apple], flag: false)
        _ = await collect(flagged.run.ask("how many sets"))
        #expect(haiku.streamCount == 0)
        // And with the phone's model unavailable too she says so, and nothing is sent.
        apple.available = false
        let none = try rig([.haiku: haiku, .appleOnDevice: apple], asks: false)
        let down = await collect(none.run.ask("how many sets"))
        #expect(down.last == .failed(TessRun.cannotThink) && haiku.streamCount == 0)
    }

    @Test func aMoneyObjectsFragmentReachesTheRequestUnderLabAndNotUnderStrict() async throws {
        for policy in [DoorPolicy.lab, .strict] {
            let haiku = ScriptedBrain(.haiku, rounds: [[.text("ok")]])
            let r = try rig([.haiku: haiku], policy: policy)
            let spend = try r.rig.store.create(#require(r.rig.classes[.spend]), title: "Groceries 41.20")
            _ = await collect(r.run.ask("how many sets", about: [spend]))
            let sentText = try Door.words(#require(haiku.requestsSeen.first))
            if policy == .lab {
                #expect(sentText.contains("[o1]"))
                #expect(r.rig.sent.entries().count == 1)
            } else {
                #expect(!sentText.contains("[o1]"))
            }
        }
    }

    @Test func aKeyShapedAskMakesNoDoorCallAndStoresNoTurn() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("never")]])
        let r = try rig([.haiku: haiku])
        let key = "sk-" + "ant-" + "api03-" + String(repeating: "Ab3x", count: 8)
        let events = await collect(r.run.ask("my key is \(key)"))
        #expect(events.last == .failed(TessRun.keyLine) && haiku.streamCount == 0)
        #expect(r.conversation.turns().isEmpty && r.rig.sent.entries().isEmpty)
    }

    // MARK: Conversation

    @Test func theAskAndHerReplyAreStoredAndAFailureStoresNothingOfHers() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Four sets.")]])
        let r = try rig([.haiku: haiku])
        _ = await collect(r.run.ask("how many sets today"))
        let texts = r.conversation.turns().map { r.conversation.text(of: $0) }
        #expect(texts == ["how many sets today", "Four sets."])
        let failing = FakeBrain(.haiku)
        failing.outcome = .busy
        let f = try rig([.haiku: failing])
        let events = await collect(f.run.ask("how many sets today"))
        #expect(events.last == .failed(TessRun.noAnswer))
        #expect(f.conversation.turns().map { f.conversation.text(of: $0) } == ["how many sets today"])
    }

    // MARK: Warm-ups

    @Test func theWarmUpRunsAtMostOncePerFourMinutesPerModel() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("ok")]])
        let r = try rig([.haiku: haiku])
        var clock = Date(timeIntervalSince1970: 1_800_000_000)
        r.run.now = { clock }
        _ = await collect(r.run.ask("how many sets"))
        #expect(await r.run.warmUp(.layerOpened, lowPower: false) != nil && haiku.warmCount == 1)
        #expect(await r.run.warmUp(.layerOpened, lowPower: false) == nil && haiku.warmCount == 1)
        clock.addTimeInterval(5 * 60)
        #expect(await r.run.warmUp(.foreground, lowPower: false) != nil && haiku.warmCount == 2)
        // Never in Low Power, and on foreground only within two hours of an ask.
        clock.addTimeInterval(10 * 60)
        #expect(await r.run.warmUp(.layerOpened, lowPower: true) == nil)
        clock.addTimeInterval(3 * 3600)
        #expect(await r.run.warmUp(.foreground, lowPower: false) == nil && haiku.warmCount == 2)
        // Through the ledger like any call.
        #expect(r.rig.ledger.calls().count >= 3)
    }

    @Test func noWarmUpWithTessAsksClaudeOff() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [])
        let r = try rig([.haiku: haiku], asks: false)
        #expect(await r.run.warmUp(.layerOpened, lowPower: false) == nil && haiku.warmCount == 0)
    }

    // MARK: Open tool

    @Test func openReadsAHandleAndCapsItsAnswer() throws {
        let r = try rig([.haiku: ScriptedBrain(.haiku, rounds: [])])
        let task = try r.engine.perform(CreateTask(title: "Water the plants"), by: .user).output
        let ok = TessOpenTool.run(arguments: Data(#"{"handle":"o1","depth":1}"#.utf8), handles: ["o1": task.id],
                                  engine: r.engine, policy: .lab)
        #expect(!ok.isError && ok.text.contains("Water the plants"))
        let bad = TessOpenTool.run(arguments: Data(#"{"handle":"zz","depth":1}"#.utf8), handles: ["o1": task.id],
                                   engine: r.engine, policy: .lab)
        #expect(bad.isError)
        let uuid = TessOpenTool.run(arguments: Data("{\"handle\":\"\(task.id.uuidString)\",\"depth\":1}".utf8),
                                    handles: ["o1": task.id], engine: r.engine, policy: .lab)
        #expect(uuid.isError)
        #expect(ok.text.count <= TessOpenTool.maxCharacters)
    }
}

enum SearchBlocks {
    static let result = #"{"type":"web_search_tool_result","tool_use_id":"srvtoolu_1","content":[{"type":"web_search_result","url":"https://x.test/a","title":"A","encrypted_content":"EqgfCioIAhgB/+=="}]}"#
}
