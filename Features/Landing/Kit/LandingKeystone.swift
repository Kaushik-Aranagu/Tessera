import SwiftUI

/// The one keystone container every landing uses (landing contract §2): 354 x 182 pt on the 402 x 874 frame, the
/// page colour behind it, no border, fill or shadow. Rooms supply only the content. A drag that starts here belongs
/// here until lift, so the page, the dial and the edge zones never take it.
struct LandingKeystone<Content: View>: View {
    let content: Content
    var caption: String?
    var label: String

    init(caption: String? = nil, label: String = "Keystone", @ViewBuilder content: () -> Content) {
        self.content = content()
        self.caption = caption
        self.label = label
    }

    /// One slot on every landing (Kaushik, Oct 25): 354 x 182 pt at top 196. More content pages inside it; it never
    /// grows.
    static var size: CGSize {
        CGSize(width: 354, height: 182)
    }

    static var top: CGFloat {
        196
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        content
            .frame(width: Self.size.width, height: Self.size.height)
            .clipShape(Rectangle())
            .scaleEffect(y: arrived || reduceMotion ? 1 : 0.94, anchor: .bottom)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            // The caption line at y 390 (12 pt under the slot): Figtree 15, ink 2, one line.
            .overlay(alignment: .topLeading) {
                if let caption {
                    FitLine(forms: [caption], size: 15)
                        .frame(width: Self.size.width, alignment: .leading)
                        .offset(y: Self.size.height + 12)
                }
            }
            .onAppear {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { arrived = true }
            }
    }
}
