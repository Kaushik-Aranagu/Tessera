import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct PerformanceProbeTests {
    @Test func todayQueriesAreCheap() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let start = Date()
        for _ in 0 ..< 20 {
            _ = model.schedule()
            _ = model.currentTask()
            _ = model.tonightWorkout()
        }
        let perFrame = Date().timeIntervalSince(start) / 20
        print("PERF today queries per refresh: \(Int(perFrame * 1000)) ms")
        #expect(perFrame < 0.05)
    }
}
