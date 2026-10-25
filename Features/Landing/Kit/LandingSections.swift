import SwiftUI

/// The fixed, named sections every landing is built from (landing contract §1, §5). A section persists across
/// screens: the frame draws all of them in the same place, each owns its touch zone and gestures, and a room only
/// supplies content. `order` is the arrival order of the Home opening effect.
enum LandingSection: Int, CaseIterable {
    /// 0 - 44: the system status bar.
    case statusBar
    /// 44 - 182: title, nav word, the optional switcher and the room's needs. The left edge (x 0 - 24) goes back.
    case masthead
    /// 196 - 378: the room's one centrepiece, its own touches and swipes, integrated with the page ground.
    case keystone
    /// y 388: one line on how to touch the keystone.
    case caption
    /// 400 - 612: Bridge's one-thing box (header, big, middle, small, glyph); swipes, hold to strike, tap opens.
    case widget
    /// 640 - 760: the doors dial (left) and the door summary (right). On Bridge the doors are apps.
    case doors
    /// Bottom: the one action word on the left, Tess on the right.
    case foot

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
