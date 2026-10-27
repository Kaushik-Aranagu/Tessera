import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

@MainActor
struct CaptureTasksAndNotesTests {
    @Test func tasksAndNotesFromTheBar() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let tess = TessCaptureEngine(engine: engine)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let wednesday = Date(timeIntervalSince1970: 1_791_986_400) // Wed 14 Oct 2026, 14:00 GMT
        let context = TessContext(now: wednesday, calendar: calendar)

        let call = await tess.capture("call mum thu", context: context)
        #expect(call.line == "Call mum, tomorrow 9 am")
        let dentist = await tess.capture("dentist thu 3pm", context: context)
        #expect(dentist.line == "Dentist, tomorrow 3 pm")
        let later = await tess.capture("todo sort the garage", context: context)
        #expect(later.line == "Sort the garage, in Later")
        #expect(TaskList(store: store, classes: classes).later().map(\.title) == ["Sort the garage"])

        let note = await tess.capture("note: bar felt heavy on Bench Press", context: context)
        #expect(note.line == "Noted")
        let linked = await tess.capture("Note @Bench Press felt heavy", context: context)
        #expect(linked.line == "Noted, linked")
        #expect(try NoteList(store: store, classes: classes).notes(about: #require(classes[.benchPress])).count == 1)

        // All of them are ghost rows until they commit.
        let records = [call, dentist, later, note, linked].flatMap(\.records)
        #expect(records.count == 5 && records.allSatisfy { $0.state == .pending })
        for line in [call, dentist, later, note, linked].map(\.line) {
            #expect(TessVoice.violations(in: line).isEmpty)
        }
    }
}
