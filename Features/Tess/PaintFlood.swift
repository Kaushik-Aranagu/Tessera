import SwiftUI

/// The paint that floods the screen from Tess when you tap her: vermilion → violet → cobalt, blurred,
/// scaling up from the bar (~0.5 s), then fading as the new content enters underneath.
struct PaintFlood: View {
    let isOn: Bool
    let origin: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(RadialGradient(
                // The incoming look's live, context, tess and now.
                colors: [
                    Theme.Colors.live,
                    Theme.Colors.context,
                    Theme.Colors.tess,
                    Theme.Colors.now.opacity(0),
                ],
                center: .center, startRadius: 0, endRadius: 60
            ))
            .frame(width: 120, height: 110)
            .blur(radius: 10)
            .scaleEffect(isOn && !reduceMotion ? 16 : 0.3)
            .opacity(isOn ? 1 : 0)
            .position(origin)
            .animation(.timingCurve(0.6, 0, 0.3, 1, duration: 0.52), value: isOn)
            .animation(.easeOut(duration: 0.42), value: isOn)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
