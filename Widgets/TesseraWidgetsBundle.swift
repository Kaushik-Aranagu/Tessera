import SwiftUI
import WidgetKit

@main
struct TesseraWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RestLiveActivity()
        // Surfaces v2 (Design 142). They draw nothing of their own while the Review switch is Off.
        DaySentenceWidget()
        CookLiveActivity()
        RoutineLiveActivity()
    }
}
