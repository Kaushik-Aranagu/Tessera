import Foundation
@testable import TesseraCore
import Testing

/// Sheet 203: every approved flag ships On; conflicts are one choice; Developer mode only turns things off.
struct FeatureFlagsTests {
    /// The app's ReviewChoices ids with their values, read from the source so the two lists cannot drift apart.
    private func reviewChoices() throws -> [(id: String, onOff: Bool)] {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        let file = package.appending(path: "../Features/Settings/ReviewChoices.swift")
        let text = try String(contentsOf: file, encoding: .utf8)
        let pattern = /Choice\(\s*id: "([A-Za-z0-9]+)",\s*name: "[^"]+",\s*values: \[([^\]]*)\]/
        return text.matches(of: pattern).map { match in
            let values = Set(match.2.replacingOccurrences(of: "\"", with: "").split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) })
            return (String(match.1), values == ["On", "Off"])
        }
    }

    @Test func theFlagListIsTheAppsSwitchesExactly() throws {
        let choices = try reviewChoices()
        #expect(choices.count > 60)
        let ids = Set(choices.map(\.id))
        let flagIDs = Set(FeatureFlags.all.map(\.id))
        #expect(flagIDs.count == FeatureFlags.all.count)
        // Every flag is a switch the app has, and every two-valued switch is a flag or named as not one.
        #expect(flagIDs.isSubset(of: ids), "\(flagIDs.subtracting(ids))")
        let twoValued = Set(choices.filter(\.onOff).map(\.id))
        #expect(twoValued.subtracting(flagIDs).subtracting(FeatureFlags.notFlags).isEmpty,
                "\(twoValued.subtracting(flagIDs).subtracting(FeatureFlags.notFlags))")
        #expect(FeatureFlags.notFlags.isSubset(of: ids))
    }

    /// The ids ReviewChoices marks `needsClaude: true`, read from the source.
    private func claudeChoices() throws -> Set<String> {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        let text = try String(contentsOf: package.appending(path: "../Features/Settings/ReviewChoices.swift"),
                              encoding: .utf8)
        var found = Set<String>()
        for block in text.components(separatedBy: "Choice(").dropFirst() {
            // A choice's own text ends where the next one starts; its id is the first thing in it.
            guard let id = block.firstMatch(of: /^\s*id: "([A-Za-z0-9]+)"/)?.1, block.contains("needsClaude: true")
            else { continue }
            found.insert(String(id))
        }
        return found
    }

    @Test func theClaudeFlagsAreExactlyTheSwitchesThatSendSomethingToClaude() throws {
        let fromApp = try claudeChoices()
        #expect(!fromApp.isEmpty)
        let flagged = Set(FeatureFlags.all.filter(\.needsClaude).map(\.id))
        // Every Claude switch is a flag here and marked, and nothing else is: a feature that sends nothing to Claude is
        // never held Off by the Claude switch.
        #expect(flagged == fromApp.subtracting(FeatureFlags.notFlags), "\(flagged.symmetricDifference(fromApp))")
        #expect(!flagged.contains("aisleOrder"))
    }

    @Test func everythingShipsOnAndAClaudeFlagNeedsTheClaudeSwitchToo() {
        let state = FeatureChoices.shipped
        for flag in FeatureFlags.all where !flag.needsClaude && flag.id != "homeV2" {
            #expect(FeatureFlags.isOn(flag.id, off: state.off, asksClaude: false), "\(flag.id)")
        }
        #expect(!FeatureFlags.isOn("planMyDay", off: state.off, asksClaude: false))
        #expect(FeatureFlags.isOn("planMyDay", off: state.off, asksClaude: true))
        #expect(!FeatureFlags.isOn("sampleData", off: [], asksClaude: true))
        #expect(!FeatureFlags.isOn("nonsense", off: [], asksClaude: true))
    }

    @Test func aFreshInstallPicksTheDefaultOfEachConflict() {
        let state = FeatureChoices.shipped
        #expect(FeatureChoices.selected("homeIs", in: state)?.id == "mosaic")
        #expect(FeatureChoices.selected("pagesTurnBy", in: state)?.id == "today")
        #expect(!FeatureFlags.isOn("homeV2", off: state.off, asksClaude: false))
        #expect(FeatureFlags.isOn("homeMosaic", off: state.off, asksClaude: false))
        #expect(state.values["pageTurn"] == "Today" && state.values["readingLayout"] == "Today")
    }

    @Test func choosingOneTurnsTheOtherOffAndBackAgain() {
        var state = FeatureChoices.shipped
        state = FeatureChoices.choosing("homeV2", in: "homeIs", state: state)
        #expect(FeatureChoices.selected("homeIs", in: state)?.id == "homeV2")
        for off in ["homeMosaic", "homeMosaicMoods", "homeMosaicMoments"] {
            #expect(!FeatureFlags.isOn(off, off: state.off, asksClaude: false))
        }
        #expect(FeatureFlags.isOn("homeV2", off: state.off, asksClaude: false))
        state = FeatureChoices.choosing("mosaic", in: "homeIs", state: state)
        #expect(FeatureChoices.selected("homeIs", in: state)?.id == "mosaic")
        #expect(!FeatureFlags.isOn("homeV2", off: state.off, asksClaude: false))
        #expect(FeatureFlags.isOn("homeMosaicMoods", off: state.off, asksClaude: false))
    }

    @Test func pagesTurnByCarriesTheReadingLayout() {
        var state = FeatureChoices.shipped
        for (option, turn, layout) in [("slide", "Slide", "Sheet 99"), ("turn", "Turn", "Sheet 99"),
                                       ("rotate", "Rotate", "Sheet 99"), ("today", "Today", "Today")]
        {
            state = FeatureChoices.choosing(option, in: "pagesTurnBy", state: state)
            #expect(state.values["pageTurn"] == turn && state.values["readingLayout"] == layout)
            #expect(FeatureChoices.selected("pagesTurnBy", in: state)?.id == option)
        }
        // A state that matches none (set by hand) reads as the default; nonsense changes nothing.
        let odd = FeatureState(off: [], values: ["pageTurn": "Soften", "readingLayout": "Today"])
        #expect(FeatureChoices.selected("pagesTurnBy", in: odd)?.id == "today")
        #expect(FeatureChoices.choosing("nope", in: "pagesTurnBy", state: state) == state)
        #expect(FeatureChoices.choosing("slide", in: "nope", state: state) == state)
    }

    @Test func developerModeListsEveryFlagOnceByAppAndOnlyTurnsThingsOff() {
        let groups = FeatureFlags.developerGroups(off: ["restTimer"])
        #expect(groups.flatMap { $0.flags.map(\.flag.id) }.sorted() == FeatureFlags.all.map(\.id).sorted())
        #expect(groups.map(\.group.rawValue) == ["Home", "Training", "Kitchen", "Notes and lists",
                                                 "Tasks and routines", "Money", "Everywhere"])
        #expect(groups.flatMap(\.flags).first { $0.flag.id == "restTimer" }?.isOn == false)
        #expect(groups.flatMap(\.flags).filter { !$0.isOn }.count == 1)
        var off = FeatureFlags.setting("restTimer", on: false, off: [])
        #expect(off == ["restTimer"])
        off = FeatureFlags.setting("restTimer", on: true, off: off)
        #expect(off.isEmpty)
        #expect(FeatureFlags.setting("sampleData", on: false, off: []).isEmpty)
    }

    @Test func theStoredFormIsTheFewTurnedOffAndForgetsWhatIsGone() {
        #expect(FeatureFlags.encoded(off: []) == nil)
        let text = FeatureFlags.encoded(off: ["restTimer", "homeV2", "removedLongAgo"])
        #expect(text == "homeV2;restTimer")
        #expect(FeatureFlags.off(encoded: "restTimer;removedLongAgo;homeV2") == ["restTimer", "homeV2"])
        #expect(FeatureFlags.off(encoded: nil).isEmpty)
    }
}
