import SwiftUI

/// The Cobalt sky wash and cream ink (the Lock Screen's palette, `RestPalette.cobaltSky`), shared by every wrist face.
enum WatchInk {
    static let cream = Color(red: 0xF6 / 255, green: 0xEF / 255, blue: 0xE4 / 255)
    static let ground = Color(red: 0x12 / 255, green: 0x0E / 255, blue: 0x1A / 255)
    static let cobalt = Color(red: 0x3F / 255, green: 0x7F / 255, blue: 0xC0 / 255)

    static func face(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("Inter Tight", size: size).weight(weight)
    }
}

/// One screen, no scroll, no tabs. The side (THIS EXERCISE) slides in over it from the right edge.
struct WatchRoot: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width: CGFloat = 200

    var body: some View {
        ZStack {
            wash
            switch store.snapshot.phase {
            case .idle: IdleFace()
            case .finished: FinishedFace()
            case .set, .rest:
                SetFace()
                    .offset(x: store.sideShown ? -28 : 0)
                    .opacity(store.sideShown ? 0.35 : 1)
            }
            if store.sideShown, store.snapshot.phase == .set || store.snapshot.phase == .rest {
                SideFace()
                    .transition(.move(edge: .trailing))
            }
        }
        .gesture(
            // The side opens from the right edge only (a swipe in from the last 32 pt); a swipe back closes it from
            // anywhere on the screen.
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    let opens = value.translation.width < -30 && value.startLocation.x > width - 32
                    let closes = value.translation.width > 40
                    guard opens || (closes && store.sideShown) else { return }
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) { store.sideShown = opens }
                }
        )
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .foregroundStyle(WatchInk.cream)
    }

    /// Cobalt sky: the ground, with the sky pooling at the top left.
    private var wash: some View {
        ZStack {
            WatchInk.ground
            RadialGradient(colors: [WatchInk.cobalt.opacity(0.55), .clear], center: .init(x: 0.2, y: -0.05),
                           startRadius: 4, endRadius: 190)
        }
        .ignoresSafeArea()
    }
}

struct IdleFace: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No workout running.").font(WatchInk.face(21)).lineLimit(2).minimumScaleFactor(0.8)
            Text("Start one on your iPhone.").font(WatchInk.face(16, .regular)).opacity(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }
}

struct FinishedFace: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.snapshot.isPrivate ? "Private workout, ready to finish" : "Every set is done.")
                .font(WatchInk.face(21)).lineLimit(3).minimumScaleFactor(0.8)
            Text("Finish it on your iPhone.").font(WatchInk.face(16, .regular)).opacity(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }
}

/// THIS EXERCISE: the sets so far, newest on top, up to six.
struct SideFace: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THIS EXERCISE").font(WatchInk.face(16)).tracking(1).opacity(0.7)
            if store.snapshot.sets.isEmpty {
                Text("No sets yet.").font(WatchInk.face(21))
            } else {
                ForEach(Array(store.snapshot.sets.enumerated()), id: \.offset) { _, line in
                    Text(line).font(WatchInk.face(21)).monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .background(WatchInk.ground.opacity(0.92).ignoresSafeArea())
        .accessibilityElement(children: .combine)
        // VoiceOver's way out: the two-finger scrub closes THIS EXERCISE and returns to the set.
        .accessibilityAction(.escape) { store.sideShown = false }
    }
}
