// swiftlint:disable identifier_name
import CoreGraphics
import Foundation
import SwiftUI
@testable import Tessera
import Testing

/// The Watch landing (268 woodland, 283 scaffold): the light keyed to the hour, the three rows, the switcher's parts
/// of the day, the needs lines, the widget items, and private routines.
struct WatchLandingTests {
    private static func tree(_ name: String = "Walk", days: Int = 10, marks: [WoodlandMark] = [],
                             done: Bool = false, due: Bool = false, steps: Int = 0) -> WoodlandTree
    {
        WoodlandTree(id: UUID(), name: name, isPrivate: name == "Private routine", days: days, marks: marks,
                     doneToday: done, dueToday: due, cap: 104, species: .oak, steps: steps)
    }

    @Test func noonSunStandsHighAndMidnightIsNight() {
        let noon = WoodlandLight.at(hour: 13)
        #expect(noon.sun != nil)
        #expect((noon.sun?.y ?? 99) < 25)
        #expect(noon.dim < 0.05)
        let midnight = WoodlandLight.at(hour: 0.5)
        #expect(midnight.sun == nil)
        #expect(midnight.moon != nil)
        #expect(midnight.isNight)
        #expect(WoodlandLight.at(hour: 18.5).warmth > 0.3)
    }

    @Test func morningLightComesFromTheLeft() {
        #expect(WoodlandLight.at(hour: 8).side == -1)
        #expect(WoodlandLight.at(hour: 17).side == 1)
    }

    @Test func threeRowsAndNothingInTheOuterFade() {
        let places = WoodlandLayout.places(count: 12)
        let scales = Set(places.map(\.scale))
        #expect(scales.contains(0.5) && scales.contains(0.72) && scales.contains(1))
        // 11% of the width fades at each side: no tree stands there.
        #expect(places.allSatisfy { $0.x > 354 * 0.11 && $0.x < 354 * 0.89 })
    }

    @Test func partsOfTheDay() {
        #expect(WatchTime.of(minute: 7 * 60) == .morning)
        #expect(WatchTime.of(minute: 18 * 60) == .evening)
        #expect(WatchTime.of(minute: 22 * 60) == .night)
        #expect(WatchTime.of(minute: 2 * 60) == .night)
        #expect(WatchTime.allCases.map(\.word) == ["Evening", "Night", "Morning"])
    }

    @Test func needsNameTheNextAndNeverCountNofM() {
        let entries = [WatchWords.Entry(name: "Walk", minute: 18 * 60 + 30, done: false),
                       WatchWords.Entry(name: "Journal", minute: 20 * 60, done: false),
                       WatchWords.Entry(name: "Stretch", minute: 13 * 60, done: true),
                       WatchWords.Entry(name: "Read", minute: 22 * 60, done: false),
                       WatchWords.Entry(name: "Swim", minute: 19 * 60, done: false, due: false)]
        let evening = WatchWords.needs(.evening, entries)
        #expect(evening[0].hasPrefix("Walk"))
        #expect(evening[1] == "2 to tend, 1 done")
        #expect(WatchWords.needs(.morning, entries) == ["Nothing this morning", "A quiet morning"])
        #expect(WatchWords.needs(.night, entries)[0].hasPrefix("Read"))
        for line in WatchWords.needs(.evening, entries) {
            #expect(line.range(of: #"\d+ of \d+"#, options: .regularExpression) == nil)
        }
    }

    @Test func widgetHasNextThirstyAndTallyWithNoStrike() {
        let walk = Self.tree("Walk", due: true, steps: 3)
        let journal = Self.tree("Journal", marks: [.kept, .slipped, .slipped, .slipped])
        let swim = Self.tree("Swim", done: true)
        let facts = RoutinesWoodlandFacts(trees: [walk, journal, swim])
        let items = WatchWords.widget(facts, wine: .red)
        #expect(items.map(\.header) == ["Next", "Thirsty", "Today"])
        #expect(items[1].big == "Journal")
        #expect(items[2].big == "1" && items[2].bigIsNumber)
        #expect(items.allSatisfy { !$0.strikeable })
        #expect(items.allSatisfy { !$0.middle.contains(" of ") && !$0.small.contains(" of ") })
    }

    @Test func emptyWoodlandIsAQuietDay() {
        let items = WatchWords.widget(RoutinesWoodlandFacts(trees: []), wine: .red)
        #expect(items.map(\.big) == ["Quiet day"])
        #expect(WatchWords.restCaption(hasTrees: false).last == "Nothing planted yet.")
    }

    @Test func privateRoutinesStayPrivateInTheWidget() {
        let hidden = Self.tree("Private routine", marks: [.slipped, .slipped, .slipped])
        let items = WatchWords.widget(RoutinesWoodlandFacts(trees: [hidden]), wine: .red)
        #expect(items.allSatisfy { $0.big == "Private routine" || $0.bigIsNumber || $0.big == "Quiet day" })
    }

    @Test func tapTargetsWorkAcrossTheThreeRows() {
        let trees = (0 ..< 12).map { Self.tree("R\($0)", days: 5 + $0 * 4) }
        let places = WoodlandLayout.places(count: trees.count)
        for (tree, place) in zip(trees, places) {
            let point = CGPoint(x: place.x, y: place.base - tree.height * place.scale / 2)
            #expect(RoutinesWoodlandScene.hit(point, trees: trees, places: places) == tree.id)
        }
        // View points map back to scene points.
        let back = RoutinesWoodlandScene.scene(CGPoint(x: 402, y: 182))
        #expect(abs(back.x - 354) < 0.5 && abs(back.y - 160.3) < 0.5)
    }

    @Test func bigLineCutsOnWholeWords() {
        let cut = WatchWords.bigFit("Chest and shoulders with arms")
        #expect(!cut.contains("..."))
        #expect("Chest and shoulders with arms".hasPrefix(cut))
        #expect(!cut.hasSuffix(" and") && !cut.hasSuffix(" with"))
        #expect(WatchWords.bigFit("Walk") == "Walk")
    }
}
