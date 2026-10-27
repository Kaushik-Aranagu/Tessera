import Foundation
@testable import Tessera
import Testing

/// The visibility rule (docs/design/live-visibility.md): UI work runs only while seen; the switch can force either way.
@MainActor
struct LiveGateTests {
    private let seen = LiveGate.Inputs(sceneActive: true, visible: true, scopeOn: true)

    @Test func uiReadIsLiveOnlyWhenEverythingIsOn() {
        #expect(LiveGate.isLive(mode: .uiRead, switchState: .auto, inputs: seen))
        for off in [
            LiveGate.Inputs(sceneActive: false, visible: true, scopeOn: true),
            LiveGate.Inputs(sceneActive: true, visible: false, scopeOn: true),
            LiveGate.Inputs(sceneActive: true, visible: true, scopeOn: false),
        ] {
            #expect(!LiveGate.isLive(mode: .uiRead, switchState: .auto, inputs: off))
        }
    }

    @Test func backgroundOnlyIsNeverLive() {
        #expect(!LiveGate.isLive(mode: .backgroundOnly, switchState: .auto, inputs: seen))
    }

    @Test func switchOverridesTheDeclaration() {
        let hidden = LiveGate.Inputs(sceneActive: false, visible: false, scopeOn: false)
        #expect(LiveGate.isLive(mode: .backgroundOnly, switchState: .alwaysLive, inputs: hidden))
        #expect(!LiveGate.isLive(mode: .uiRead, switchState: .dataOnly, inputs: seen))
    }

    @Test func registryPersistsSwitchesAndMeters() throws {
        let suite = try #require(UserDefaults(suiteName: "LiveGateTests.\(UUID().uuidString)"))
        let registry = LiveRegistry(defaults: suite)
        let feature = LiveFeatures.lookoutSky
        #expect(registry.switchState(for: feature) == .auto)
        registry.set(.dataOnly, for: feature)
        #expect(LiveRegistry(defaults: suite).switchState(for: feature) == .dataOnly)
        registry.set(.auto, for: feature)
        #expect(LiveRegistry(defaults: suite).switchState(for: feature) == .auto)

        let start = Date(timeIntervalSince1970: 1000)
        registry.record(feature, live: true, at: start)
        registry.record(feature, live: true, at: start.addingTimeInterval(5))
        registry.record(feature, live: false, at: start.addingTimeInterval(10))
        #expect(registry.liveSeconds[feature.id] == 10)
        #expect(registry.flips[feature.id] == 1)
    }

    @Test func featureIdsAreUnique() {
        #expect(Set(LiveFeatures.all.map(\.id)).count == LiveFeatures.all.count)
    }

    @Test func quietStillDrawsWhenSeenButHasNoIdle() {
        #expect(LiveGate.isLive(mode: .uiRead, switchState: .quiet, inputs: seen))
        #expect(!LiveGate.runsIdle(live: true, switchState: .quiet))
        #expect(LiveGate.runsIdle(live: true, switchState: .auto))
        let hidden = LiveGate.Inputs(sceneActive: true, visible: false, scopeOn: true)
        #expect(!LiveGate.isLive(mode: .uiRead, switchState: .quiet, inputs: hidden))
    }

    @Test func returnPlaysOnlyTheDifferencesOnce() {
        let before: LiveSnapshot = ["a": "1", "b": "1", "c": "1"]
        let now: LiveSnapshot = ["a": "1", "b": "2", "d": "1"]
        let diff = LiveReturn.diff(seen: before, now: now)
        #expect(diff == LiveDiff(added: ["d"], changed: ["b"], removed: ["c"]))
        #expect(LiveReturn.plan(seen: before, now: now, away: 60)
            == .play(diff: diff, delay: 0.65, window: 0.6))
        #expect(LiveReturn.plan(seen: before, now: before, away: 60) == .showNow)
    }

    @Test func tooManyChangesOrTooLongAwayJustShowsNow() {
        let before: LiveSnapshot = [:]
        let many = Dictionary(uniqueKeysWithValues: (0 ..< 7).map { ("t\($0)", "x") })
        #expect(LiveReturn.plan(seen: before, now: many, away: 10) == .showNow)
        let few = Dictionary(uniqueKeysWithValues: (0 ..< 6).map { ("t\($0)", "x") })
        #expect(LiveReturn.plan(seen: before, now: few, away: 10) != .showNow)
        #expect(LiveReturn.plan(seen: before, now: few, away: 3601) == .showNow)
    }
}
