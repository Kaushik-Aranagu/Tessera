import SwiftUI

/// The mosaic's place on Home: full width, 250 pt tall.
/// TODO: swap for A's MosaicView(facts: MosaicFacts, scene: Binding<MosaicScene>). It will set `lay` to
/// `{ rowFrame in mosaic.lay(from: rowFrame, tone: .glaze) }` and write its one caption line into `caption`.
struct MosaicSlot: View {
    @Binding var lay: ((CGRect) -> Void)?
    @Binding var caption: String

    var body: some View {
        Color.clear.frame(height: HomeMosaic.mosaicHeight)
            .accessibilityHidden(true)
    }
}

/// The line knob beside the Settings word (a later piece). Draws nothing yet.
struct SettingsKnob: View {
    var body: some View {
        EmptyView()
    }
}

/// Sheet 197's three-row snapping apps list, under Next, when Settings › Home › Apps list is On. Draws nothing yet.
/// TODO: sheet 197: the 3-row snapping apps list.
struct AppsListSlot: View {
    var body: some View {
        EmptyView()
    }
}
