import SwiftData
import SwiftUI

@main
struct TesseraApp: App {
    private let container: ModelContainer
    @State private var model: AppModel

    init() {
        FontRegistry.registerAll()
        AppClock.configure()
        let container = TesseraSchema.makeContainer()
        self.container = container
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
        _model = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        .modelContainer(container)
    }
}
