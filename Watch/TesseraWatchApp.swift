import CoreText
import SwiftUI

@main
struct TesseraWatchApp: App {
    @State private var store = WatchStore()

    init() {
        // Inter Tight, bundled; registered at launch as the phone does (no italics, no system face).
        if let url = Bundle.main.url(forResource: "InterTight-Variable", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchRoot()
                .environment(store)
                .task { store.start() }
        }
    }
}
