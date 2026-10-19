import Foundation
@testable import TesseraCore
import Testing

/// A task title is judged by the one shared title check (G105), like a routine or recipe title: title words and the
/// "Dr Name" rule count for a task too.
@MainActor
struct TaskTitleCheckTests {
    let store = ObjectStore.open(inMemory: true)

    @Test(arguments: ["Pay Dr Lin rent 1200", "Call Dr Lin", "Pay the therapist", "Book the dentist"])
    func aTaskTitleUsesTheOneSharedCheck(_ title: String) throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let task = try engine.perform(CreateTask(title: title), by: .user).output
        #expect(ObjectPrivacy.isPrivateTitle(title, lastWeightKg: nil))
        #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == "Private task", "\(title)")
    }

    @Test func aPlainTaskTitleStaysPlain() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        for title in ["Buy lemons", "Call mom", "Dr Pepper run"] {
            let task = try engine.perform(CreateTask(title: title), by: .user).output
            #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == nil, "\(title)")
        }
    }
}
