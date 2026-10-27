import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Unnameable blocks reading a thing's data to Claude, never going to it: "open settings" or "show Tess's memory" still
/// opens the page on the phone, by id, with no model and no write.
@MainActor
struct UnnameableNavigationTests {
    let helper = TessRunTests()

    func frame(_ item: ElementItem) -> TessFrame {
        var elements = [ElementMeaning(place: .widget, items: [item], focus: 0,
                                       calls: ElementCatalog.calls(room: "bridge", place: .widget))]
        elements.append(ElementMeaning(place: .navWord, calls: ElementCatalog.calls(room: "bridge", place: .navWord)))
        return TessFrame(room: "bridge", elements: elements, now: .now)
    }

    @Test func openingSettingsHerMemoryOrAnAgentStillWorksAndNothingReachesClaude() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [])
        let sonnet = ScriptedBrain(.sonnet, rounds: [])
        let r = try helper.rig([.haiku: haiku, .sonnet: sonnet])
        try SettingsStore(engine: r.engine).update(by: .system) { $0.restWeekday = 3 }
        let settings = try #require(r.engine.store.object(id: SettingsStore.objectID))
        let memory = try r.engine.store.create(
            #require(r.engine.classes[.tessMemory]),
            title: "He trains in the evening"
        )
        let agent = try r.engine.store.create(#require(r.engine.classes[.tessAgent]), title: "Deck")
        for (object, kind) in [(settings, "settings"), (memory, "memory"), (agent, "agent")] {
            #expect(TessAskRouter.isUnnameable(object, classes: r.engine.classes), "\(kind)")
            let item = ElementItem(id: object.id, kind: kind, name: object.title)
            let events = await helper.collect(r.run.ask("open this", frame: frame(item)))
            let shells = events.compactMap { event -> ShellIntent? in
                if case let .shell(intent) = event {
                    intent
                } else {
                    nil
                }
            }
            #expect(shells.first?.call == "openItem" && shells.first?.object == object.id, "\(kind): \(events)")
        }
        #expect(haiku.streamCount == 0 && sonnet.streamCount == 0)
    }

    @Test func theRouterStillAnswersAnUnnameableThingOnThePhoneOnly() throws {
        let r = try helper.rig([:])
        let memory = try r.engine.store.create(
            #require(r.engine.classes[.tessMemory]),
            title: "He trains in the evening"
        )
        let ask = TessAskRouter.route(memory, engine: r.engine, asksClaude: true)
        #expect(ask.claudeText == nil && ask.actions.isEmpty)
    }
}
