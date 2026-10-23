import SwiftUI

// Room motion (Design 138, behind the `roomMotion` Review switch, default Off): the small shared motions that make the
// apps feel like rooms of one house. Every one goes through MotionPolicy; Reduce Motion is a 150 ms crossfade or an
// appear. With the switch Off each modifier here is the identity.
//
// - `.opens(id)`: a word that opens a place is the source of its title (the word grows into the title).
// - `RoomTitle`: the landing's title shows the word that was tapped until it settles, then crossfades to the app's
// name.
// - `.receiptTravel`: a receipt travels toward its app's edge and dries (420 ms).
// - `.paperSheet()`: a sheet lifts like paper, no shadow, no blur, on the house spring (bounce 0.12).
// - `.roomShift`: the ground tint and the accent change over 300 ms when the room changes.

enum RoomMotionSwitch {
    nonisolated static let choiceID = "roomMotion"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

enum RoomTiming {
    /// A receipt's travel and drying, together.
    static let receipt: TimeInterval = 0.42
    /// The title's crossfade from the tapped word to the app's name.
    static let titleCrossfade: TimeInterval = 0.2
    /// The room's ground and accent shift.
    static let shift: TimeInterval = 0.3
    /// How long a landing takes to settle before its title takes the app's name.
    static let settle: TimeInterval = 0.35
}

extension View {
    /// The word that opens a place: the source its title grows from. The identity with the switch Off.
    func opens(_ id: some Hashable, namespace: Namespace.ID?) -> some View {
        modifier(OpensWord(id: id, namespace: namespace))
    }

    /// A receipt travels toward its app's edge and dries. `done` flips it on.
    func receiptTravel(toward edge: Edge, done: Bool) -> some View {
        modifier(ReceiptTravel(edge: edge, done: done))
    }

    /// A sheet that lifts like paper: the paper ground, no shadow, no blur.
    func paperSheet() -> some View {
        modifier(PaperSheet())
    }

    /// The room's ground tint and accent; both change over 300 ms.
    func roomShift(ground: Color, accent: Color) -> some View {
        modifier(RoomShift(ground: ground, accent: accent))
    }
}

private struct OpensWord<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if RoomMotionSwitch.isOn, let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct ReceiptTravel: ViewModifier {
    let edge: Edge
    let done: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        guard RoomMotionSwitch.isOn else { return AnyView(content) }
        let travel: CGFloat = reduceMotion ? 0 : 28
        let offset = switch edge {
        case .top: CGSize(width: 0, height: -travel)
        case .bottom: CGSize(width: 0, height: travel)
        case .leading: CGSize(width: -travel, height: 0)
        case .trailing: CGSize(width: travel, height: 0)
        }
        return AnyView(
            content
                .offset(done ? offset : .zero)
                // Dry: the receipt settles to a quieter ink as it lands.
                .opacity(done ? 0.55 : 1)
                .animation(
                    reduceMotion ? MotionPolicy.reducedMotionFade
                        : .timingCurve(0.2, 0.9, 0.25, 1, duration: RoomTiming.receipt),
                    value: done
                )
        )
    }
}

private struct PaperSheet: ViewModifier {
    func body(content: Content) -> some View {
        if RoomMotionSwitch.isOn {
            content
                .presentationBackground(Theme.Colors.paper)
                .presentationCornerRadius(24)
        } else {
            content
        }
    }
}

private struct RoomShift: ViewModifier {
    let ground: Color
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if RoomMotionSwitch.isOn {
            content
                .tint(accent)
                .background(ground.ignoresSafeArea())
                .animation(reduceMotion ? MotionPolicy.reducedMotionFade : .easeInOut(duration: RoomTiming.shift),
                           value: ground)
                .animation(reduceMotion ? MotionPolicy.reducedMotionFade : .easeInOut(duration: RoomTiming.shift),
                           value: accent)
        } else {
            content
        }
    }
}

/// A landing's title: the word that was tapped until the page settles, then the app's name.
struct RoomTitle: View {
    let appName: String
    /// The word that opened the page ("Tacos"), nil when it was opened another way.
    var openedBy: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false

    var body: some View {
        Text(shown)
            .contentTransition(.opacity)
            .accessibilityLabel(appName)
            .task {
                guard RoomMotionSwitch.isOn, openedBy != nil, !reduceMotion else {
                    settled = true
                    return
                }
                try? await Task.sleep(for: .seconds(RoomTiming.settle))
                withTesseraAnimation(.easeOut(duration: RoomTiming.titleCrossfade), reduceMotion: reduceMotion) {
                    settled = true
                }
            }
    }

    private var shown: String {
        guard RoomMotionSwitch.isOn, let openedBy, !settled else { return appName }
        return openedBy
    }
}
