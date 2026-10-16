@testable import Tessera
import TesseraCore
import Testing

/// Settings-object.md: demo data and -resetDemo can never run on the phone (device builds compile them out).
@MainActor
struct DemoGuardTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func offTheSimulatorNothingIsSeededOrWiped() throws {
        let task = try model.engine.perform(CreateTask(title: "Call the bank"), by: .user).output
        DemoData.prepare(model, arguments: ["-demo", "-resetDemo"], allowed: false)
        #expect(model.object(task.id) != nil)
        #expect(!model.objects(of: .routine).contains { $0.title == "Push Day A" })
    }

    @Test func theTestsRunWhereDemoDataIsAllowed() {
        #expect(DemoData.isAllowed) // unit tests run on the simulator
    }
}
