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
    @Environment(\.keystoneBleeds) private var bleeds
    @State private var arrived = false
    /// How far the content asks to draw past the slot (`keystoneBleed(_:)`), e.g. Lookout's glass shadows.
    @State private var asked = EdgeInsets()

    var body: some View {
        content
            .frame(width: Self.size.width, height: Self.size.height)
            .clipShape(KeystoneClip(insets: clipInsets))
            .onPreferenceChange(KeystoneBleedKey.self) { asked = $0 }
            .scaleEffect(y: arrived || reduceMotion ? 1 : 0.94, anchor: .bottom)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .onAppear {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { arrived = true }
            }
    }
}

extension LandingKeystone {
    /// The clip: the slot, widened by the environment's full-width bleed and by what the content asks for.
    private var clipInsets: EdgeInsets {
        let side = bleeds ? (402 - Self.size.width) / 2 : 0
        return EdgeInsets(top: max(asked.top, 0), leading: max(asked.leading, side),
                          bottom: max(asked.bottom, 0), trailing: max(asked.trailing, side))
    }
}

/// The slot's rectangle grown by `insets` on each side.
struct KeystoneClip: Shape {
    var insets: EdgeInsets

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX - insets.leading, y: rect.minY - insets.top,
                    width: rect.width + insets.leading + insets.trailing,
                    height: rect.height + insets.top + insets.bottom))
    }
}

/// What a keystone's content asks to draw past the slot (the largest ask wins).
struct KeystoneBleedKey: PreferenceKey {
    static let defaultValue = EdgeInsets()

    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        let next = nextValue()
        value = EdgeInsets(top: max(value.top, next.top), leading: max(value.leading, next.leading),
                           bottom: max(value.bottom, next.bottom), trailing: max(value.trailing, next.trailing))
    }
}

extension View {
    /// Lets this keystone content draw `insets` past the slot (light and shadow that fall off the glass, woods that
    /// span the phone). The slot keeps its frame and touches; only the clip widens. Works wherever the keystone is
    /// hosted (the scaffold or the shell), with no setting on the host.
    func keystoneBleed(_ insets: EdgeInsets) -> some View {
        preference(key: KeystoneBleedKey.self, value: insets)
    }
}

extension EnvironmentValues {
    /// A keystone drawn wider than the slot (Watch's woods span the phone's 402 pt, 268 v4): the slot keeps its 354 pt
    /// frame and touches, but its clip widens to the phone's width so the drawing's dissolving edges show. Off by
    /// default.
    @Entry var keystoneBleeds = false
}
