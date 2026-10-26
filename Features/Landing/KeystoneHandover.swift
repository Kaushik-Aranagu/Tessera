import SwiftUI

/// The keystone hands its item to the widget on arrival (sheet 283 v3): Galley tears a ticket off the rail and it
/// swings and falls into the glyph (about 900 ms); Purse slides a dot off the index line on an arc. Positions are
/// design
/// points on 402 x 874, scaled like `LandingScaffold`. Runs once; nothing under Reduce Motion; never takes a touch.
struct KeystoneHandover: View {
    enum Kind {
        case galleyTicket
        case purseDot
    }

    let kind: Kind
    /// Where it leaves the keystone, in design points.
    var from = CGPoint(x: 110, y: 290)
    /// The glyph's centre (x 298-378, top 444).
    static let glyphCentre = CGPoint(x: 338, y: 484)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var spot: CGPoint = .zero
    @State private var turn: Double = 0
    @State private var size: CGFloat = 1
    @State private var visible = false

    var body: some View {
        GeometryReader { proxy in
            let rise = max(0.86, min(1.1, proxy.size.height / 874))
            piece
                .scaleEffect(size)
                .rotationEffect(.degrees(turn), anchor: .top)
                .position(x: spot.x * rise, y: spot.y * rise)
                .opacity(visible ? 1 : 0)
        }
        .ignoresSafeArea(.container, edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await run() }
    }

    @ViewBuilder
    private var piece: some View {
        switch kind {
        case .galleyTicket:
            TornPaper()
                .fill(scheme == .dark ? Color(hex: 0x2B2722) : Color(hex: 0xF6EFDF))
                .frame(width: 34, height: 44)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Capsule().fill(LandingAccent.kitchen).frame(width: 18, height: 2)
                        Capsule().fill(Theme.Colors.inkSecondary).frame(width: 22, height: 1.5)
                        Capsule().fill(Theme.Colors.inkSecondary).frame(width: 14, height: 1.5)
                    }
                    .padding(6)
                }
        case .purseDot:
            Circle().fill(LandingAccent.money).frame(width: 8, height: 8)
        }
    }

    private func run() async {
        guard !reduceMotion else { return }
        // After the sections' own arrival has started.
        try? await Task.sleep(for: .milliseconds(450))
        spot = from
        visible = true
        switch kind {
        case .galleyTicket:
            // The tear: a small lift and a twist on the clip.
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
                spot = CGPoint(x: from.x + 6, y: from.y - 12)
                turn = -14
            }
            try? await Task.sleep(for: .milliseconds(220))
            // The swing and fall into the glyph.
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                spot = Self.glyphCentre
                turn = 9
                size = 0.7
            }
            try? await Task.sleep(for: .milliseconds(520))
        case .purseDot:
            // Off the line and up, then down on an arc into the widget.
            let top = CGPoint(x: (from.x + Self.glyphCentre.x) / 2 + 20, y: min(from.y, Self.glyphCentre.y) - 40)
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { spot = top }
            try? await Task.sleep(for: .milliseconds(260))
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { spot = Self.glyphCentre }
            try? await Task.sleep(for: .milliseconds(480))
        }
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            visible = false
            size = 0.3
        }
    }
}
