import Foundation
import SwiftUI
@testable import Tessera
import Testing

/// Kaushik, Oct 26 1:30 PM: no shown line ends in a full stop. Every text a room hands the shell, on the landing and
/// on each of its door pages, is checked, room by room.
enum ShownLines {
    static func of(_ screen: Screen) -> [String] {
        screen.slots.values.flatMap { lines($0.payload) }
    }

    static func lines(_ payload: SlotPayload) -> [String] {
        switch payload {
        case let .title(text, _): [text]
        case let .navWord(word): [word]
        case let .lines(lines): lines
        case let .switcher(across, vertical): across + vertical
        case let .wall(words, label): words.map(\.text) + [label]
        case let .widget(items): items.flatMap(item)
        case let .glyph(glyph, _): item(glyph)
        case let .dial(doors): doors.flatMap(door)
        case let .summary(one): door(one)
        case let .doorTitle(name, line, _): [name, line]
        case let .list(rows): rows.flatMap { [$0.title, $0.detail] }
        case let .action(steps, _): steps.flatMap { [$0.verb, $0.object] }
        case let .scene(_, label): [label]
        }
    }

    private static func item(_ item: WidgetItem) -> [String] {
        [item.header, item.big, item.middle, item.small]
    }

    private static func door(_ door: DialDoor) -> [String] {
        [door.name, door.count ?? "", door.label ?? ""] + door.lines
    }

    /// The landing and every door page of `content`, for the room `room`.
    static func screens(_ content: some RoomContent, room: String) -> [Screen] {
        let landing = content.screen(for: .landing(room), state: RoomState())
        var doors: [String] = []
        if case let .dial(list)? = landing[.dial]?.payload {
            doors = list.map(\.id)
        }
        return [landing] + doors.map { content.screen(for: .door(room, $0), state: RoomState()) }
    }

    static func endingInAFullStop(_ screens: [Screen]) -> [String] {
        screens.flatMap(of).filter { $0.hasSuffix(".") && !$0.hasSuffix("...") }
    }
}

@MainActor
struct NoTrailingPeriodTests {
    @Test func deck() {
        for day in [
            TrainingDay.ready(name: "Push A", minutes: 45, lifts: 4),
            .rest(next: "Pull A", nextDay: Date().addingTimeInterval(86400)),
            .done(name: "Push A", next: "Pull A"),
            .nothing,
        ] {
            let screens = ShownLines.screens(DeckRoomContent(facts: DeckRoomContentTests.facts(day: day)),
                                             room: DeckRoomContent.room)
            let stops = ShownLines.endingInAFullStop(screens)
            #expect(stops.isEmpty, "\(stops)")
            for stop in stops {
                print("FULLSTOP: \(stop)")
            }
        }
    }

    @Test func settings() {
        let screens = ShownLines.screens(SettingsRoomContent(facts: SettingsRoomContentTests.facts),
                                         room: SettingsRoomContent.room)
        let stops = ShownLines.endingInAFullStop(screens)
        #expect(stops.isEmpty, "\(stops)")
        for stop in stops {
            print("FULLSTOP: \(stop)")
        }
    }

    @Test func watch() {
        let screens = ShownLines.screens(WatchRoomContent(facts: WatchRoomContentTests.facts),
                                         room: WatchRoomContent.room)
        let stops = ShownLines.endingInAFullStop(screens)
        #expect(stops.isEmpty, "\(stops)")
        for stop in stops {
            print("FULLSTOP: \(stop)")
        }
    }

    @Test func lookout() {
        for hour in [9, 13, 22] {
            let now = Calendar.current.date(bySettingHour: hour, minute: 10, second: 0, of: Date()) ?? Date()
            let facts = LookoutRoomContent.Facts(snapshot: WeatherSample.make(now: now, fahrenheit: true))
            let screens = ShownLines.screens(LookoutRoomContent(facts: facts), room: LookoutRoomContent.room)
            let stops = ShownLines.endingInAFullStop(screens)
            #expect(stops.isEmpty, "\(stops)")
            for stop in stops {
                print("FULLSTOP: \(stop)")
            }
        }
    }

    @Test func galley() {
        let screens = ShownLines.screens(GalleyRoomContent(facts: GalleyRoomContentTests.facts),
                                         room: GalleyRoomContent.room)
        let stops = ShownLines.endingInAFullStop(screens)
        #expect(stops.isEmpty, "\(stops)")
        for stop in stops {
            print("FULLSTOP: \(stop)")
        }
    }

    @Test func purse() {
        let screens = ShownLines.screens(PurseRoomContent(facts: PurseRoomContentTests.facts),
                                         room: PurseRoomContent.room)
        let stops = ShownLines.endingInAFullStop(screens)
        #expect(stops.isEmpty, "\(stops)")
        for stop in stops {
            print("FULLSTOP: \(stop)")
        }
    }
}
