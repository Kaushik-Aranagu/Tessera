import SwiftUI

/// One card of the landing widget: Bridge's one-thing box (sheet 283), x 24-378, y 400-612. Header, Big line, Middle
/// line, Small line and an 80 pt glyph on the right. Rooms fill the text and supply the glyph.
struct WidgetItem: Identifiable, Equatable {
    let id: String
    /// 13 pt 600 caps, tracked .12 em, at y 429.
    var header: String
    /// A word at 38 pt 700, or (with `bigIsNumber`) an Outfit 56 number with its unit at half size.
    var big: String
    var bigIsNumber = false
    var unit: String?
    /// 20 pt 500.
    var middle = ""
    /// 15 pt 500 ink 2.
    var small = ""
    /// The Big line's color (a role color); nil is ink.
    var bigColor: Color?
    /// Hold the Big line to strike it (Done, Undo 10 s). Lookout and Purse have no strike.
    var strikeable = true
}

/// The widget section. Swipes across or up and down (past 50 / 44 pt) to the next item; hold the Big line 180 ms and
/// then 600 ms to strike it; tap opens. Reduce Motion: a plain swap.
struct LandingWidget<Glyph: View>: View {
    let items: [WidgetItem]
    @Binding var index: Int
    var open: (WidgetItem) -> Void
    var strike: (WidgetItem) -> Void = { _ in }
    @ViewBuilder let glyph: (WidgetItem) -> Glyph

    static var size: CGSize { CGSize(width: 354, height: 212) }
    static var top: CGFloat { 400 }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag = CGSize.zero
    @State private var struck: Set<String> = []
    @State private var cue = HapticCue()

    var body: some View {
        ZStack(alignment: .topLeading) {
            if items.indices.contains(index) {
                card(items[index])
                    .id(items[index].id)
                    .offset(x: lockedHorizontal ? drag.width * 0.9 : 0, y: lockedHorizontal ? 0 : drag.height * 0.9)
                    .transition(.asymmetric(insertion: .offset(y: reduceMotion ? 0 : 18), removal: .opacity))
            }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
        .gesture(swipe)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .contain)
        .accessibilityAdjustableAction { direction in turn(direction == .increment ? 1 : -1) }
    }

    private var lockedHorizontal: Bool { abs(drag.width) > abs(drag.height) }

    private func card(_ item: WidgetItem) -> some View {
        let done = struck.contains(item.id)
        return ZStack(alignment: .topLeading) {
            Text(item.header.uppercased())
                .font(.custom("Figtree", size: 13, relativeTo: .caption).weight(.semibold))
                .tracking(13 * 0.12)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(1)
                .offset(y: 29)
            bigLine(item, done: done).offset(y: 44)
            FitLine(forms: FitLine.cuts(item.middle), size: 20, color: Theme.Colors.ink, weight: .medium)
                .frame(width: 262, alignment: .leading)
                .offset(y: 122)
            FitLine(forms: FitLine.cuts(item.small), size: 15, color: Theme.Colors.inkSecondary, weight: .medium)
                .frame(width: 262, alignment: .leading)
                .offset(y: 154)
            glyph(item)
                .frame(width: 80, height: 80)
                .offset(x: 354 - 80, y: 44)
                .allowsHitTesting(false)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .onTapGesture { open(item) }
    }

    @ViewBuilder
    private func bigLine(_ item: WidgetItem, done: Bool) -> some View {
        let color = item.bigColor ?? Theme.Colors.ink
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if item.bigIsNumber {
                Text(item.big).font(.custom("Outfit", size: 56, relativeTo: .largeTitle).weight(.light))
                if let unit = item.unit {
                    Text(unit).font(.custom("Figtree", size: 28, relativeTo: .title2).weight(.regular))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            } else {
                Text(item.big).font(.custom("Figtree", size: 38, relativeTo: .largeTitle).weight(.bold))
            }
        }
        .foregroundStyle(done ? Theme.Colors.inkSecondary : color)
        .strikethrough(done, color: color)
        .lineLimit(1)
        .frame(width: 262, height: 64, alignment: .leading)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.78) {
            guard item.strikeable, !done else { return }
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { _ = struck.insert(item.id) }
            cue.play(.done)
            strike(item)
        }
        .accessibilityAction(named: item.strikeable ? "Done" : "") { if item.strikeable { strike(item) } }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { drag = $0.translation }
            .onEnded { value in
                let across = abs(value.translation.width) > abs(value.translation.height)
                let distance = across ? value.translation.width : value.translation.height
                let threshold: CGFloat = across ? 50 : 44
                if abs(distance) > threshold { turn(distance < 0 ? 1 : -1) }
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { drag = .zero }
            }
    }

    private func turn(_ delta: Int) {
        let next = index + delta
        guard items.indices.contains(next) else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { index = next }
        cue.play(.pageTurn)
    }
}
