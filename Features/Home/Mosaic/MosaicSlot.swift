import SwiftUI

/// The mosaic's place on Home: full width, 250 pt tall.
/// TODO: swap for A's MosaicView(facts: MosaicFacts, scene: Binding<MosaicScene>). It will set `lay` to
/// `{ rowFrame in mosaic.lay(from: rowFrame, tone: .glaze) }` and write its one caption line into `caption`.
struct MosaicSlot: View {
    @Binding var lay: ((CGRect) -> Void)?
    @Binding var caption: String
    /// Sheet 200: with the moods On, A's view draws the picked mood inside the frame and writes the one caption line.
    var facts: MosaicFacts?
    var mood: MosaicMood?
    @State private var scene: MosaicScene = .day

    var body: some View {
        // Sheet 200 (mosaic moods On): 248x160 pt, right-aligned to the gutter; A's picture draws inside this frame.
        // Otherwise full width, 250 pt tall as before.
        Group {
            if HomeMosaic.moodsIsOn {
                Group {
                    if let facts, let mood {
                        MosaicView(facts: facts, scene: $scene, mood: mood, caption: $caption)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: HomeMosaic.moodsMosaicSize.width, height: HomeMosaic.moodsMosaicSize.height)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Color.clear.frame(height: HomeMosaic.mosaicHeight)
            }
        }
        .accessibilityHidden(HomeMosaic.moodsIsOn ? false : true)
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
