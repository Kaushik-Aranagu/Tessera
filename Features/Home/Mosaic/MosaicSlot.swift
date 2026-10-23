import SwiftUI
import TesseraCore

/// The mosaic's place on Home. With the moods On (sheet 202) Builder A's layer draws behind the whole page, edge to
/// edge, and this only reserves the core's 248x160 frame, right-aligned, so the text sits clear of it; it reports where
/// the core's top is. Otherwise a full-width 250 pt gap, as before.
struct MosaicSlot: View {
    /// Points from the top of the screen to this frame's top, for the layer.
    @Binding var coreTop: CGFloat

    var body: some View {
        Group {
            if HomeMosaic.moodsIsOn {
                Color.clear
                    .frame(width: HomeMosaic.moodsMosaicSize.width, height: HomeMosaic.moodsMosaicSize.height)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { coreTop = $0 }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Color.clear.frame(height: HomeMosaic.mosaicHeight)
            }
        }
        .accessibilityHidden(true)
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
