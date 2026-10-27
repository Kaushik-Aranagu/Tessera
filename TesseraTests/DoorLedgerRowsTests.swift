@testable import Tessera
import Testing

@MainActor
struct DoorLedgerRowsTests {
    @Test func tonightRowsPutTheStartTimeOnTheRight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 26, hour: 18, minute: 30)) ?? Date()
        let day = KitchenFront.Day(id: start, weekday: "Mon", isToday: true,
                                   meal: .init(title: "Tacos", start: start, minutes: 25, recipe: nil), when: nil)
        let empty = KitchenFront.Day(id: start, weekday: "Tue", isToday: false, meal: nil, when: nil)
        let rows = GalleyRoomContent.tonightRows([day, empty])
        #expect(rows.count == 1 && rows[0].name == "Mon Tacos")
        #expect(rows[0].value != nil && rows[0].unit != nil)
    }

    @Test func theQuietLastLineNamesWhatIsLow() {
        #expect(GalleyRoomContent.more(["Milk"], suffix: "low") == "Milk low")
        #expect(GalleyRoomContent.more(["Milk", "Eggs"], suffix: "low") == "Milk and eggs low")
        #expect(GalleyRoomContent.more(["Milk", "Eggs", "Rice"], suffix: "low") == "Milk and 2 more low")
    }

    @Test func noLedgerRowReadsWithAFullStop() {
        let rows = GalleyRoomContent.tonightRows([])
        #expect(rows.isEmpty)
        #expect(GalleyRoomContent.more(["Milk"], suffix: "low").hasSuffix(".") == false)
    }
}
