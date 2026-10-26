import SwiftUI
@testable import Tessera
import Testing

/// Lookout's door rows open what they name and its dial carries a fact beside each door; Lookout's steady sky draws
/// the sun, never the word cover; Settings' door pages read the room's facts; Watch's woods may bleed past the slot.
@MainActor
struct LookoutRowsTests {
    private let facts = LookoutRoomContent.Facts(snapshot: WeatherSample.make(now: Date(), fahrenheit: true))

    @Test func everyHoursRowOpensItsHour() {
        let page = LookoutRoomContent(facts: facts).screen(for: .door("lookout", "hours"), state: RoomState())
        guard case let .list(rows) = page[.page]?.payload else {
            Issue.record("no page")
            return
        }
        #expect(!rows.isEmpty)
        for (index, row) in rows.enumerated() {
            let detail = facts.detail(forRow: row.id)
            #expect(detail != nil, "row \(row.id) opens")
            #expect(detail?.title == WeatherWords.hour(facts.snapshot.hours[index].date))
            #expect(detail?.lines.first?
                .hasPrefix(WeatherWords.degrees(facts.snapshot.hours[index].temperature)) == true)
        }
    }

    @Test func weekRowsOpenTheirDayAndAirRowsTheAir() {
        let week = facts.lines(.week)
        for index in week.indices {
            let detail = facts.detail(forRow: "week.\(index)")
            #expect(detail != nil)
            #expect(week[index].hasPrefix(detail?.title ?? "?"))
        }
        #expect(facts.detail(forRow: "air.0")?.lines == WeatherWords.airLines(facts.snapshot))
        #expect(facts.detail(forRow: "hours.999") == nil)
        #expect(facts.detail(forRow: "coming") == nil)
    }

    @Test func theDialCarriesAFactLineForEachDoor() {
        let doors = facts.doors
        #expect(doors.first { $0.id == "hours" }?
            .label == "Now \(WeatherWords.degrees(facts.snapshot.temperature)), next hours")
        #expect(doors.first { $0.id == "air" }?.label == "Air, sun and wind now")
        #expect(doors.allSatisfy { $0.label != nil && !$0.lines.isEmpty && $0.count == nil })
    }

    @Test func detailsOnlyCarryWeather() {
        let ids = (0 ..< 12).map { "hours.\($0)" } + (0 ..< 7).map { "week.\($0)" } + ["air.0"]
        let all = ids.compactMap { facts.detail(forRow: $0) }
        #expect(!all.isEmpty)
        #expect(all.allSatisfy { $0.lines.count <= 3 && !$0.title.isEmpty })
    }
}

struct LookoutSteadyGlyphTests {
    @Test func aSteadySkyDrawsTheSun() {
        #expect(GlyphKind
            .pick(header: "Coming", big: "Steady", middle: "for the next 12 hours", room: .lookout) == .sun)
        #expect(GlyphKind.pick(header: "Coming", big: "Dry", middle: "by 7 pm", room: .lookout) == .sun)
        #expect(GlyphKind.pick(header: "Coming", big: "Rain", middle: "from 6 pm", room: .lookout) == .rain)
        #expect(GlyphKind.pick(header: "Tonight", big: "54", middle: "Clear", room: .lookout) == .moon)
    }
}

@MainActor
struct SettingsDoorLineTests {
    private func facts(claude: Bool) -> SettingsLandingFacts {
        SettingsLandingFacts(remembers: "12 things", asksClaude: claude, units: ["kg", "km", "°F"],
                             backupLine: "Last backup tonight, 9:14 pm. 4,210 things.", build: "1.0 (42)",
                             privacyLines: ["3 private notes stay on this phone."])
    }

    @Test func theTessDoorReadsTheRoomsFacts() {
        let line = SettingsLandingWords.doorLine(.tess, facts: facts(claude: false))
        #expect(line == "Tess remembers 12 things, all on this phone.")
        #expect(SettingsLandingWords.doorLine(.tess, facts: facts(claude: true)).contains("only with your key"))
    }

    @Test func everyDoorLineIsAFactAndNeverKeyShaped() {
        for area in SettingsArea.doors {
            for claude in [true, false] {
                let line = SettingsLandingWords.doorLine(area, facts: facts(claude: claude))
                #expect(!line.isEmpty)
                #expect(line != "Tess remembers")
                #expect(!line.contains("sk-"))
            }
        }
        #expect(SettingsLandingWords.doorLine(.units, facts: facts(claude: false)) == "Measures in kg, km, and °F.")
        #expect(SettingsLandingWords.doorLine(.backups, facts: facts(claude: false)).hasPrefix("Last backup tonight"))
    }

    @Test func theShellDoorTitleUsesTheLine() {
        let content = SettingsRoomContent(facts: .init(settings: facts(claude: false),
                                                       colors: SettingsLandingWords.colors(.light)))
        let door = content.screen(for: .door("settings", "tess"), state: RoomState())
        guard case let .doorTitle(name, line, _) = door[.doorTitle]?.payload else {
            Issue.record("no door title")
            return
        }
        #expect(name == "Tess")
        #expect(line == "Tess remembers 12 things, all on this phone.")
    }
}

struct WatchWoodsBleedTests {
    @Test func theWoodsAreWiderThanTheSlotAndTheSlotCanBleed() {
        #expect(RoutinesWoodlandScene.size.width == 402)
        #expect(LandingKeystone<EmptyView>.size.width == 354)
        #expect(EnvironmentValues().keystoneBleeds == false)
    }
}
