import SwiftUI

/// The fixed, named sections every landing is built from (landing contract §1, §5). A section persists across
/// screens: the frame draws all of them in the same place, each owns its touch zone and gestures, and a room only
/// supplies content. `order` is the arrival order of the Home opening effect.
enum LandingSection: Int, CaseIterable {
    /// Title (tap opens the index) and the summary lines; the left edge (x 0 - 24) goes back.
    case topBar
    /// The room's one centrepiece, its own touches and swipes, integrated with the page ground.
    case keystone
    /// The caption line and the two update rows (tap opens, swipe right Done, swipe left Not now).
    case rows
    /// The doors: the 3-place dial on the Log, door words elsewhere. On Bridge the doors are apps.
    case doors
    /// The one action word, bottom left (tap, or drag left or right for options).
    case action

    var order: Int { rawValue }
}

/// The Home arrival effect on a section (sheet 213, Home 236): the section rises 10 pt out of a slightly smaller size, sections 80 ms apart, 0.5 s on the ease-out. Reduce Motion: a 150 ms cross-fade, no blur,
/// no rise, no scale. Never blocks a tap.
struct LandingArrival: ViewModifier {
    let section: LandingSection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// Blur lives only in the doors dial's depth blur (Kaushik, Oct 25): sections do not blur on arrival.
    static let blur: CGFloat = 0
    static let scale: CGFloat = 0.95

    func body(content: Content) -> some View {
        content
            .opacity(shown || !reduceMotion ? 1 : 0)
            .blur(radius: shown || reduceMotion ? 0 : Self.blur)
            .scaleEffect(shown || reduceMotion ? 1 : Self.scale, anchor: .topLeading)
            .offset(y: shown || reduceMotion ? 0 : ThingEntrance.tierRise)
            .task {
                // After the first frame is on screen, so a busy first frame cannot swallow the animation.
                try? await Task.sleep(for: .milliseconds(60))
                let delay = Double(section.order) * ThingEntrance.tierStagger
                withAnimation(reduceMotion ? .easeOut(duration: 0.15)
                    : .timingCurve(0.215, 0.61, 0.355, 1, duration: ThingEntrance.tierSeconds).delay(delay))
                {
                    shown = true
                }
            }
    }
}

extension View {
    /// Gives a landing section the Home arrival effect.
    func landingSection(_ section: LandingSection) -> some View {
        modifier(LandingArrival(section: section))
    }
}
