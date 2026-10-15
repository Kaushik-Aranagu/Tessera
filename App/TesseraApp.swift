import SwiftData
import SwiftUI
import TesseraCore

@main
struct TesseraApp: App {
    private let container: ModelContainer
    @State private var model: AppModel

    init() {
        FontRegistry.registerAll()
        Theme.configure()
        AppClock.configure()
        let container = TesseraSchema.makeContainer()
        self.container = container
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
        _model = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-soulGallery") {
                        SoulGallery()
                    } else {
                        RootView()
                    }
                #else
                    RootView()
                #endif
            }
            .environment(model)
        }
        .modelContainer(container)
    }
}
