import SwiftUI
import TesseraCore

/// The mosaic's place on Home. With the moods On (sheet 202) Builder A's layer draws behind the whole page, edge to
/// edge, and this only reserves the core's 248x160 frame, right-aligned, so the text sits clear of it; it reports where
/// the core's top is in the page's own (content) space, so scrolling never moves the field. With the moods Off the
/// plain
/// 199 mosaic (A's `MosaicView`) draws here, full width and 250 pt tall, as before.
struct MosaicSlot: View {
    /// Points from the top of the page's content to this frame's top, for the layer.
    @Binding var coreTop: CGFloat
    var facts: MosaicFacts?
    @Binding var scene: MosaicScene
    @Binding var caption: String
    /// Home 236: the stack of faces. The swipe and the tap live here, on the core's own frame, and nowhere else.
    var faces: MosaicFaceModel?

    @Environment(\.openHomeLink) private var openLink

    /// The core's frame: the current face's width in tiles from the right margin, and 160 pt tall. The mosaic itself
    /// bleeds past it (the rim); a touch counts only inside.
    private var zone: CGFloat {
        CGFloat(faces?.current?.width ?? MosaicFaceKind.widest) * MosaicScreenGrid.step
    }

    var body: some View {
        if HomeMosaic.moodsIsOn {
            frame
                .frame(maxWidth: .infinity, alignment: .trailing)
                .modifier(MosaicWords(words: caption, face: faces?.current, turn: { faces?.turn(forward: $0) },
                                      open: openRoom))
        } else if let facts {
            // With the moods off the mosaic keeps its own accessibility element and scrub; no outer label over it.
            MosaicView(facts: facts, scene: $scene, caption: $caption)
                .frame(height: HomeMosaic.mosaicHeight)
        } else {
            Color.clear.frame(height: HomeMosaic.mosaicHeight).accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var frame: some View {
        let clear = Color.clear
            .frame(maxWidth: zone)
            .frame(height: HomeMosaic.moodsMosaicSize.height)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(HomeMosaicPage.space)).minY } action: {
                coreTop = $0
            }
        if let faces {
            clear
                .contentShape(Rectangle())
                .onTapGesture { openRoom() }
                .mosaicFaceSwipe(faces)
                .tesseraFeedback(.pageTurn, trigger: faces.impacts)
        } else {
            clear
        }
    }

    /// A tap opens the face's room, and counts as a touch for the pause.
    private func openRoom() {
        guard let faces, let face = faces.current else { return }
        faces.touched()
        openLink(face.room)
    }
}

/// The mosaic speaks for itself, so its words ride in its accessibility label (sheet 211), never as text on its edge.
/// The face is a button that opens its room; swiping turns it.
private struct MosaicWords: ViewModifier {
    let words: String
    var face: MosaicFace?
    var turn: (Bool) -> Void = { _ in }
    var open: () -> Void = {}

    func body(content: Content) -> some View {
        if words.isEmpty, face == nil {
            content.accessibilityHidden(true)
        } else if let face {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(face.spoken)
                .accessibilityValue(words)
                .accessibilityIdentifier("mosaicFace")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { open() }
                .accessibilityAdjustableAction { direction in
                    turn(direction == .increment)
                }
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(words)
        }
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
