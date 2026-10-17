import SwiftUI

/// The plate (sheet 88): 56 pt at the top edge of an object page, full bleed, opaque to 34 and melting into the
/// ground by 56. A generative wash in the object's pigments is there at first paint; a photo, when there is one,
/// dries in over it in 380 ms (Reduce Motion: a 150 ms crossfade). A private object gets plain ground: no photo and
/// no pigment. No text ever sits on it, and it scrolls away with the page.
struct ObjectPlate: View {
    /// The wash's pigments (hex); Kitchen green until Core's colour table lands.
    var pigments: [UInt32] = [PlateWash.kitchenGreen]
    /// Seeds the wash so the same object draws the same plate every time.
    var seed: UInt64
    var photo: Image?
    /// VoiceOver for a photo: "Photo of Sheet-pan paprika chicken, from budgetbytes.com".
    var photoLabel: String?
    var isPrivate = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dried = false

    static let height: CGFloat = 56

    var body: some View {
        ZStack {
            if !isPrivate {
                wash
                if let photo {
                    photo
                        .resizable()
                        .scaledToFill()
                        .opacity(dried ? 1 : 0)
                        .blur(radius: dried || reduceMotion ? 0 : 5)
                        .saturation(dried || reduceMotion ? 1 : 0.6)
                        .accessibilityLabel(photoLabel ?? "Photo")
                        .onAppear {
                            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : Theme.Motion.house
                                .speed(0.36 / 0.38))
                            {
                                dried = true
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .clipped()
        // Opaque to 34, melting into the ground by 56.
        .mask(LinearGradient(stops: [.init(color: .black, location: 34 / 56), .init(color: .clear, location: 1)],
                             startPoint: .top, endPoint: .bottom))
    }

    private var wash: some View {
        let dark = ThemeStore.shared.paintLook.isDark
        let colours = PlateWash.pigments(pigments).map { Color(hex: $0) }
        return GeometryReader { proxy in
            ZStack {
                ForEach(Array(PlateWash.blobs(seed: seed, pigments: colours.count).enumerated()),
                        id: \.offset)
                { _, blob in
                    Ellipse()
                        .fill(colours[blob.pigment])
                        .frame(width: proxy.size.width * blob.width, height: proxy.size.height * blob.height)
                        .position(x: proxy.size.width * blob.x, y: proxy.size.height * blob.y)
                }
            }
            .opacity(dark ? 0.26 : 0.34)
            .blendMode(dark ? .screen : .normal)
            .blur(radius: 5)
            .overlay { PaperGrain().opacity(0.55) }
        }
        .accessibilityHidden(true)
    }
}
