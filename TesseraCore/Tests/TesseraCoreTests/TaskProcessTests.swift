import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct TaskProcessTests {
    @Test func startedTasksAreNowAndWaitingOnesComeBack() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let table = ProcessTable(engine: engine)
        let write = try engine.perform(CreateTask(title: "Write the brief"), by: .user).output
        let invoice = try engine.perform(CreateTask(title: "Chase the invoice"), by: .user).output

        try engine.perform(StartTask(task: write.id, nextStep: "Outline section 2"), by: .user)
        #expect(table.running()?.subject?.id == write.id)
        #expect(table.running()?.nextStep == "Outline section 2")

        // Starting another suspends the first; it waits in the ledger with its next step.
        try engine.perform(StartTask(task: invoice.id), by: .user)
        #expect(table.running()?.subject?.id == invoice.id)
        #expect(table.ledger().first?.subject?.id == write.id)

        // Waiting on someone until Thursday.
        let thursday = Date.now.addingTimeInterval(2 * 86400)
        try engine.perform(WaitOnTask(task: invoice.id, waitingOn: "Arjun's reply", checkAt: thursday), by: .user)
        #expect(table.running() == nil)
        #expect(table.all().first { $0.subject?.id == invoice.id }?.state == .waiting)
        #expect(table.wakeWaiting(now: .now).isEmpty)
        #expect(table.wakeWaiting(now: thursday.addingTimeInterval(60)).count == 1)
        #expect(table.all().first { $0.subject?.id == invoice.id }?.state == .suspended)

        // Finishing a task ends its process.
        try engine.perform(SetTaskDone(task: write.id), by: .user)
        #expect(table.process(for: write) == nil)
    }
}
