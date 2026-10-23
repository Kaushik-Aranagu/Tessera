import SwiftUI
import TesseraCore

/// The mosaic's place on Home: full width, 250 pt tall.
/// TODO: swap for A's MosaicView(facts: MosaicFacts, scene: Binding<MosaicScene>). It will set `lay` to
/// `{ rowFrame in mosaic.lay(from: rowFrame, tone: .glaze) }` and write its one caption line into `caption`.
struct MosaicSlot: View {
    @Binding var lay: ((CGRect) -> Void)?
    @Binding var caption: String
    /// Sheet 200: with the moods On, A's view draws the picked mood inside the frame and writes the one caption line.
    var facts: MosaicFacts?
    var mood: MosaicMood?
    /// Sheet 201: a moment to play over the mood.
    var moment: MosaicMomentEvent?
    @State private var scene: MosaicScene = .day

    var body: some View {
        // Sheet 200 (mosaic moods On): 248x160 pt, right-aligned to the gutter; A's picture draws inside this frame.
        // Otherwise full width, 250 pt tall as before.
        Group {
            if HomeMosaic.moodsIsOn {
                Group {
                    if let facts, let mood {
                        MosaicView(facts: facts, scene: $scene, mood: mood, moment: moment, caption: $caption)
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

/// The knob beside the Settings word (sheet 203): nine of the screen's own pixels, Builder A's `PixelKnob`. A press
/// turns it and opens Settings.
struct SettingsKnob: View {
    var open: () -> Void = {}

    var body: some View {
        PixelKnob(action: open)
            .accessibilityLabel("Settings")
    }
}

/// "Settings" at the top right of a page, in ink 2, beside the knob (sheet 203). A 44 pt target each.
struct SettingsEntry: View {
    var open: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: open) {
                Text("Settings")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens Settings")
            SettingsKnob(open: open)
        }
    }
}

/// Sheet 197's three-row snapping apps list, under Next, when Settings › Home › Apps list is On. Draws nothing yet.
/// TODO: sheet 197: the 3-row snapping apps list.
struct AppsListSlot: View {
    var body: some View {
        EmptyView()
    }
}
