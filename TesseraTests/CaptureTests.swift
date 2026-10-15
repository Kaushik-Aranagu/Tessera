import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct CaptureTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
    }

    private func taskTitles() -> [String] {
        model.objects(of: .task).map(\.title)
    }

    @Test func aCaptureIsAGhostUntilItDries() throws {
        let id = try #require(model.capture(title: "Call mum", startsAt: AppClock.now.addingTimeInterval(3600)))
        #expect(model.isGhost(id))
        #expect(taskTitles().contains("Call mum"))
        model.commitCapture()
        #expect(!model.isGhost(id))
        #expect(model.lastCapture != nil)
        #expect(taskTitles().contains("Call mum"))
    }

    @Test func droppingAGhostWritesNothing() throws {
        _ = try #require(model.capture(title: "Call mum", startsAt: AppClock.now.addingTimeInterval(3600)))
        model.discardCapture()
        #expect(!taskTitles().contains("Call mum"))
    }

    @Test func undoReversesACommittedCapture() throws {
        _ = try #require(model.capture(title: "Call mum", startsAt: AppClock.now.addingTimeInterval(3600)))
        model.commitCapture()
        model.undoLastCapture()
        #expect(!taskTitles().contains("Call mum"))
    }
}
