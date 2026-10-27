import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess's guide (docs/ai/harness/guide.md): a page for everything the app offers her, built from the catalogs, so a
/// new call, place, form, trait or tool without a page fails here.
@MainActor
struct TessGuideTests {
    func read(_ path: String) -> (text: String, isError: Bool) {
        let json = try? JSONSerialization.data(withJSONObject: ["path": path])
        return TessGuide.run(arguments: json ?? Data())
    }

    // MARK: In sync with the app

    @Test func everythingTheAppOffersHasAPage() {
        let book = TessGuide.book
        #expect(Set(TessGuide.roomNames.keys) == Set(ElementCatalog.rooms.keys))
        for room in ElementCatalog.rooms.keys {
            #expect(book["/rooms/\(room)"] != nil, "room \(room)")
        }
        for place in ElementPlace.allCases {
            #expect(book["/places/\(place.rawValue)"] != nil, "place \(place)")
        }
        for call in ElementCatalog.everyCall {
            #expect(book["/calls/\(call.name)"] != nil, "call \(call.name)")
        }
        for form in ElementForms.all {
            #expect(book["/looks/forms/\(form.name)"] != nil, "form \(form.name)")
        }
        let traits = ElementForms.all.flatMap(\.traits) + LookCatalog.places.values.flatMap(\.traits)
        for trait in traits {
            #expect(book["/looks/traits/\(trait.name)"] != nil, "trait \(trait.name)")
        }
        let tools = (TessRun.toolSpecs() + TessRun.shellSpecs()).map(\.name) + TessTools.all.map(\.name)
        for tool in tools {
            #expect(book["/tools/\(tool)"] != nil, "tool \(tool)")
        }
        #expect(tools.contains(TessGuide.name))
    }

    @Test func everyPathAPageNamesIsAPage() {
        // The guide's own paths; a tool's words may name another tool's paths (the notebook's /memories/).
        let shelves: Set<String> = ["you", "rules", "rooms", "places", "calls", "looks", "tools"]
        for page in TessGuide.book.values {
            let named = page.body.split { $0 == " " || $0 == "\n" || $0 == "," || $0 == ";" }
                .map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: ":.()")) }
                .filter { path in
                    path.hasPrefix("/") && !path.contains("<")
                        && shelves.contains(path.split(separator: "/").first.map(String.init) ?? "")
                }
            for path in named {
                #expect(TessGuide.book[path] != nil, "\(page.path) names \(path)")
            }
        }
    }

    @Test func everyPageFitsInOneAnswer() {
        for page in TessGuide.book.values {
            #expect(page.body.count <= TessGuide.maxCharacters, "\(page.path) is \(page.body.count)")
            #expect(!page.title.isEmpty)
        }
    }

    // MARK: Reading

    @Test func aPathReadsItsPage() {
        let pause = read("/calls/pauseRoutine")
        #expect(!pause.isError && pause.text.contains("pauseRoutine") && pause.text.contains("Watch"))
        #expect(pause.text.contains("the thing he means by this"))
        // Money is the phone's alone, and the page says so.
        #expect(read("/calls/logSpend").text.contains("never Claude"))
        #expect(read("/rooms/").text == read("/rooms").text)
    }

    @Test func aMissingPathPointsToTheNearestPages() {
        let missing = read("/calls/pauseRoutines")
        #expect(missing.isError && missing.text.hasPrefix("No page there.") && missing.text.contains("/calls/pause"))
        #expect(read("").isError)
    }

    @Test func wordsFindTheCall() {
        let found = read("how do I pause a routine")
        #expect(!found.isError && found.text.contains("/calls/pauseRoutine"), "\(found.text)")
        let lines = found.text.split(separator: "\n")
        #expect(lines.count <= TessGuide.maxHits)
    }

    // MARK: Offered and packed

    @Test func anAskAboutTheAppGetsTheGuide() throws {
        let frame = ElementLooksTests().deckFrame()
        #expect(TessGuide.isAbout("How do I start a workout?") && TessGuide.isAbout("what does the dial do"))
        #expect(!TessGuide.isAbout("why is my bench stuck") && !TessGuide.isAbout("start"))
        let about = ToolPicker.pick("how do I start a workout from here", frame: frame)
        let at = try #require(about.tools.firstIndex(of: TessGuide.name))
        #expect(about.tools.prefix(at).allSatisfy { about.matched.contains($0) })
        #expect(about.tools.count <= ToolPicker.maxTools)
        #expect(!ToolPicker.pick("plan my week please", frame: frame).tools.contains(TessGuide.name))
    }

    @Test func theGuideNeverCutsALeadingCall() throws {
        // An ask about a look that is also about the app: the look calls still lead, and the guide comes after them.
        let frame = ElementLooksTests().deckFrame()
        let ask = "how do I make the dial denser and what does an index look like"
        // Longer than a look nudge binds, and about looks: the look calls lead and the guide is offered.
        let pick = ToolPicker.pick(ask, frame: frame)
        #expect(pick.bound == nil && pick.looks)
        let at = try #require(pick.tools.firstIndex(of: TessGuide.name), "\(pick.tools)")
        #expect(pick.tools.prefix(at).allSatisfy { pick.matched.contains($0) || LookWords.calls.contains($0) })
        for call in LookWords.calls {
            #expect(pick.tools.prefix(at).contains(call), "\(call) in \(pick.tools)")
        }
        // Every call the ask named survives the cut.
        let named = ToolPicker.pick("how do I start a workout from here", frame: frame)
        #expect(named.matched.allSatisfy { named.tools.contains($0) })
    }

    @Test func anInterruptedGuideReadRunsAgainOnResume() async throws {
        let helper = TessRunTests()
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Say pause on it")]])
        let sonnet = ScriptedBrain(.sonnet, rounds: [[.text("Say pause on it")]])
        let r = try helper.rig([.haiku: haiku, .sonnet: sonnet])
        // Killed after the first read finished and before the guide ran.
        let input = Data(#"{"path":"/calls/pauseRoutine"}"#.utf8)
        let first = Data(#"{"path":"/rooms/watch"}"#.utf8)
        var state = TessRunState(startedAt: .now, askText: "pause routine", aboutIDs: [],
                                 messages: [BrainMessage(.user, text: "pause routine"),
                                            BrainMessage(.assistant,
                                                         [.toolUse(id: "t0", name: TessGuide.name, input: first),
                                                          .toolUse(id: "t1", name: TessGuide.name, input: input)])])
        state.doneToolIDs = ["t0"]
        state.toolResults = ["t0": "Watch (Routines): what each place offers you"]
        TessRunStore(url: r.url).save(state)
        await r.run.resumeInterrupted()
        let sent = try #require((haiku.requestsSeen + sonnet.requestsSeen).first)
        // A pure read: the page itself, not "interrupted".
        #expect(sent.messages.last?.content.contains {
            if case let .toolResult(id, content, false) = $0 {
                id == "t1" && content.hasPrefix("pauseRoutine:")
            } else {
                false
            }
        } == true)
    }

    @Test func thePackCarriesTheContentsOnlyWithTheGuide() throws {
        let helper = TessRunTests()
        let r = try helper.rig([:], policy: .strict)
        let frame = ElementLooksTests().deckFrame()
        let about = ToolPicker.pick("how do I start a workout from here", frame: frame)
        let pack = r.run.pack(about: [], screen: nil, withTools: true, frame: frame, pick: about)
        #expect(pack.tools.contains { $0.name == TessGuide.name })
        // The guide is what the app is, never his data: safe under strict.
        #expect(pack.fragments.contains(PackFragment(TessGuide.contentsLine)))
        let plain = ToolPicker.pick("plan my week please", frame: frame)
        let other = r.run.pack(about: [], screen: nil, withTools: true, frame: frame, pick: plain)
        #expect(!other.fragments.contains { $0.text == TessGuide.contentsLine })
    }

    @Test func herRungReadsAPageInTheRun() async throws {
        let helper = TessRunTests()
        let frame = ElementLooksTests().deckFrame()
        let ask = "how do I start a workout from here"
        let pick = ToolPicker.pick(ask, frame: frame)
        let use = helper.use("t1", TessGuide.name, #"{"path":"/calls/startWorkout"}"#)
        var brains: [BrainID: any Brain] = [:]
        var scripted: [ScriptedBrain] = []
        for id in pick.plan.ladder {
            let brain = ScriptedBrain(id, rounds: [[use], [.text("Say start on the routine")]])
            brains[id] = brain
            scripted.append(brain)
        }
        let r = try helper.rig(brains)
        _ = await helper.collect(r.run.ask(ask, frame: frame))
        let results = scripted.flatMap(\.requestsSeen).flatMap { $0.messages.last?.content ?? [] }
            .compactMap { piece -> String? in
                if case let .toolResult(_, content, false) = piece { content } else { nil }
            }
        #expect(results.contains { $0.hasPrefix("startWorkout:") }, "\(results)")
    }
}
