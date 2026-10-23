import Foundation
@testable import Tessera
import Testing

/// The Tasks app (sheet 140): the carried word and the switch.
@MainActor
struct TasksAppTests {
    @Test func aCarriedTaskNamesItsWeekday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let date = DateComponents(calendar: calendar, year: 2026, month: 10, day: 20, hour: 12).date ?? .now
        #expect(TasksApp.fromWord(date, calendar: calendar) == "from Tuesday")
    }

    @Test func theSwitchSitsOnShownAndStartsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == TasksApp.choiceID })
        #expect(choice.defaultValue == "Off")
        let shown = try #require(ReviewChoices.facets.first { $0.word == "Shown" })
        #expect(shown.ids.contains(TasksApp.choiceID))
        #expect(shown.ids.count <= 6)
    }

    @Test func aRowReadsTheTimeOrNothing() {
        let line = TasksFront.Line(id: UUID(), title: "Call Sam", when: nil, carried: false)
        #expect(line.value().isEmpty)
    }
}
