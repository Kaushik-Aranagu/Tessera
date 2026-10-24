import QuartzCore
import SwiftUI
import TesseraCore

/// The places rail (Design 118 §7 and 119 §9/§10; Kaushik, Oct 22): the template for any list with levels. PLACE is a
/// dial on the left, SECTION a small word on the right, ROW a name with one value. The dial never travels: its places
/// turn through five fixed 58 pt slots as a loop, the focus place large, the rest small and faint. An optional pinned
/// place (To get, Inbox, Today) sits above the dial in the hot colour. A fourth level is a sheet on the row, never a
/// column. Each screen supplies the places, its sections and rows, and how a row looks; RailPage does the rest.
struct RailPage<Row: Identifiable, RowView: View>: View {
    /// The second level inside a place: a small word (nil lists the rows directly) and its rows.
    struct Section: Identifiable {
        let label: String?
        let rows: [Row]

        var id: String {
            label ?? ""
        }
    }

    /// How a place's second level shows: as small words above the rows, or not at all (a flat list).
    enum SectionStyle {
        case words, none
    }

    let title: String
    /// The line under the title, for the open place ("9 in the fridge", "7 to get").
    let subtitle: (String) -> String
    var back: (title: String, action: () -> Void)?
    /// A word at the right of the title, on its baseline (a knob such as Kind). When both do not fit on one line it
    /// drops under the title, left-aligned; the title never shrinks.
    var titleTrailing: AnyView?
    /// The place above the dial, out of the loop, in the hot colour (nil for none).
    var pinned: RailPlace?
    /// The app's one accent (131): the pinned place's colour. Never another app's, never the amber look-alike.
    let accent: Color
    /// The subtitle's colour: Tess's context violet by default; an app with no hue (Tasks) passes ink 2.
    var subtitleColor: Color = Theme.Colors.context
    let places: [RailPlace]
    @Binding var open: String
    var sectionStyle: SectionStyle = .words
    /// The rows of a place, grouped by section.
    let sections: (String) -> [Section]
    /// The line under the rows of a place, when it has one ("Swipe right when bought ...").
    var foot: (String) -> String? = { _ in nil }
    /// What an empty place says.
    var empty: (String) -> String = { _ in "Nothing here yet." }
    /// A thin level line under the subtitle for the open place (nil draws none).
    var level: (String) -> Double? = { _ in nil }
    @ViewBuilder let row: (Row) -> RowView

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let accessible = typeSize.isAccessibilitySize
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, Theme.Spacing.gutter)
            // At accessibility sizes the dial sits above the open place, one column, nothing clipped.
            let layout = accessible
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.l))
                : AnyLayout(HStackLayout(alignment: .top, spacing: Theme.Spacing.m))
            if let pinned {
                RailPinned(place: pinned, accent: accent, open: $open)
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .padding(.top, Theme.Spacing.xl)
            }
            layout {
                RailDial(pinned: pinned, places: places, open: $open, compact: accessible)
                    .frame(width: accessible ? nil : RailMetrics.columnWidth, alignment: .leading)
                    .frame(maxWidth: accessible ? .infinity : nil, alignment: .leading)
                ScrollView {
                    contents(of: open)
                        .id(open)
                        .transition(RailMetrics.swap(calm: calm))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Theme.Spacing.section)
                }
                .scrollIndicators(.hidden)
                .tesseraAnimation(RailMetrics.crossfade, value: open)
            }
            .padding(.leading, Theme.Spacing.gutter)
            .padding(.trailing, Theme.Spacing.gutter)
            .padding(.top, pinned == nil ? Theme.Spacing.xxl : Theme.Spacing.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var calm: Bool {
        reduceMotion || PowerState.isLowPower
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let back {
                Button(action: back.action) {
                    Text("‹ \(back.title)")
                        // Label size, sentence case (131 §1: no caps).
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to \(back.title)")
                .entrance(0)
            }
            titleRow
                .entrance(0, hero: true)
            Text(subtitle(open))
                .font(Theme.voice(size: 21))
                .foregroundStyle(subtitleColor)
                .contentTransition(.numericText())
                .tesseraAnimation(RailMetrics.crossfade, value: open)
                .padding(.top, Theme.Spacing.xs)
                .entrance(1)
            if let level = level(open) {
                PlaceLevelLine(level: level)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    private var titleText: some View {
        Text(title)
            .textRole(.hero)
            .foregroundStyle(Theme.Colors.ink)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var titleRow: some View {
        if let titleTrailing {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    // Measured at its full 72: the hero steps down to 48 only on its own, never to make room.
                    titleText.fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: Theme.Spacing.s)
                    titleTrailing
                }
                VStack(alignment: .leading, spacing: 0) {
                    titleText
                    titleTrailing
                }
            }
        } else {
            titleText
        }
    }

    @ViewBuilder
    private func contents(of place: String) -> some View {
        let groups = sections(place).filter { !$0.rows.isEmpty }
        VStack(alignment: .leading, spacing: 0) {
            if groups.isEmpty {
                Text(empty(place))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, RailMetrics.sectionGap)
            }
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, section in
                VStack(alignment: .leading, spacing: 0) {
                    if sectionStyle == .words, let label = section.label {
                        Text(label)
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, Theme.Spacing.xs)
                    }
                    ForEach(section.rows) { item in
                        row(item)
                    }
                }
                .padding(.top, index == 0 ? 0 : RailMetrics.sectionGap)
            }
            if let foot = foot(place) {
                Text(foot)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.xl)
            }
        }
    }
}

/// One top-level group on a rail: a stable id, its word and how many rows it holds.
struct RailPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let count: Int
}

/// The rail's numbers, in one place (Design 118 §7).
enum RailMetrics {
    static let columnWidth: CGFloat = 112
    static let slot: CGFloat = 58
    /// Two slots above the focus and two below.
    static let reach = 2
    static let focusScale: CGFloat = 1.32
    static let farScale: CGFloat = 0.70
    static let farInk = 0.30
    /// The dial's bow: the left edge moves in by 8 × d² pt.
    static let bow: CGFloat = 8
    static let pinnedSize: CGFloat = 24
    static let pinnedOpenScale: CGFloat = 1.5
    static let sectionGap: CGFloat = 20
    /// The open place's crossfade (old out, then new in), 150 ms through MotionPolicy when calm.
    static let crossfade = Animation.easeInOut(duration: 0.24)
    /// One spring for the dial's snap.
    static let snap = Animation.spring(Spring(duration: 0.38, bounce: 0.1))

    /// The open place's swap: a crossfade with a 14 pt sideways slip; calm, a crossfade alone.
    static func swap(calm: Bool) -> AnyTransition {
        calm ? .opacity : .asymmetric(insertion: .opacity.combined(with: .offset(x: 14)),
                                      removal: .opacity.combined(with: .offset(x: -14)))
    }
}

/// The left column: the pinned place, then the dial. The dial's focus is a continuous value `turn` (place index, any
/// real number; the places loop), which a drag moves and a release snaps to the nearest place.
private struct RailDial: View {
    let pinned: RailPlace?
    let places: [RailPlace]
    @Binding var open: String
    /// Accessibility sizes: the dial lays out as plain words, one per line, instead of turning.
    var compact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turn: Double = 0
    @State private var dragStart: Double?
    /// A tap right after the dial lets go is the finger stopping it, not a pick (gesture policy).
    @State private var holdoff = TapHoldoff()
    @State private var ticks = 0

    private var calm: Bool {
        reduceMotion || PowerState.isLowPower
    }

    private var pinnedOpen: Bool {
        pinned?.id == open
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if compact {
                compactWords
            } else {
                dial
            }
        }
        .tesseraFeedback(.selection, trigger: ticks)
        .onAppear(perform: alignTurn)
        .onChange(of: places) { alignTurn() }
    }

    // MARK: The dial

    private var dial: some View {
        let count = places.count
        return ZStack(alignment: .topLeading) {
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                Text(place.name)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .overlay(alignment: .bottomTrailing) {
                        Text("\(place.count)")
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .fixedSize()
                            .alignmentGuide(.trailing) { $0[.leading] - 4 }
                            .alignmentGuide(.bottom) { $0[.bottom] - 1 }
                    }
                    .fixedSize()
                    .modifier(DialSlot(index: index, count: count, turn: turn, calm: calm,
                                       dimmed: pinnedOpen))
                    .onTapGesture { pick(index) }
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: RailMetrics.slot * CGFloat(RailMetrics.reach * 2 + 1), alignment: .top)
        .contentShape(Rectangle())
        .gesture(drag)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Places")
        .accessibilityValue(focusPlace.map { "\($0.name), \($0.count)" } ?? "")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(1)
            case .decrement: step(-1)
            @unknown default: break
            }
        }
    }

    private var focusIndex: Int {
        guard !places.isEmpty else { return 0 }
        let rounded = Int(turn.rounded())
        return ((rounded % places.count) + places.count) % places.count
    }

    private var focusPlace: RailPlace? {
        places.isEmpty ? nil : places[focusIndex]
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart))
            .onChanged { value in
                holdoff.moved(at: CACurrentMediaTime())
                let start = dragStart ?? turn
                dragStart = start
                let before = Int(turn.rounded())
                // Down brings the place above into focus.
                turn = start - Double(value.translation.height / RailMetrics.slot)
                if Int(turn.rounded()) != before || pinnedOpen {
                    ticks += 1
                    if let place = focusPlace {
                        withTesseraAnimation(RailMetrics.crossfade, reduceMotion: calm) { open = place.id }
                    }
                }
            }
            .onEnded { value in
                holdoff.moved(at: CACurrentMediaTime())
                let start = dragStart ?? turn
                dragStart = nil
                // A flick carries on by its velocity, then rests on the nearest place.
                let landing = (start - Double(value.predictedEndTranslation.height / RailMetrics.slot)).rounded()
                let before = Int(turn.rounded())
                withTesseraAnimation(RailMetrics.snap, reduceMotion: calm) { turn = landing }
                if Int(landing) != before {
                    ticks += 1
                }
                if let place = focusPlace {
                    withTesseraAnimation(RailMetrics.crossfade, reduceMotion: calm) { open = place.id }
                }
            }
    }

    private func step(_ count: Int) {
        guard !places.isEmpty else { return }
        ticks += 1
        withTesseraAnimation(RailMetrics.snap, reduceMotion: calm) {
            turn = turn.rounded() + Double(count)
            if let place = focusPlace {
                open = place.id
            }
        }
    }

    /// A tap turns the dial the short way round to that place.
    private func pick(_ index: Int) {
        guard !places.isEmpty, holdoff.allowsTap(at: CACurrentMediaTime()) else { return }
        let count = Double(places.count)
        var delta = (Double(index) - turn).truncatingRemainder(dividingBy: count)
        if delta > count / 2 {
            delta -= count
        }
        if delta < -count / 2 {
            delta += count
        }
        ticks += 1
        withTesseraAnimation(RailMetrics.snap, reduceMotion: calm) {
            turn = (turn + delta).rounded()
            open = places[index].id
        }
    }

    /// The dial faces the open place when it is one of the loop's.
    private func alignTurn() {
        guard let index = places.firstIndex(where: { $0.id == open }), index != focusIndex else { return }
        turn = Double(index)
    }

    // MARK: Accessibility sizes

    private var compactWords: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(places) { place in
                Button {
                    ticks += 1
                    withTesseraAnimation(RailMetrics.crossfade, reduceMotion: calm) { open = place.id }
                } label: {
                    Text("\(place.name) \(place.count)")
                        .textRole(.body)
                        .foregroundStyle(open == place.id ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityAddTraits(open == place.id ? .isSelected : [])
            }
        }
    }
}

/// The pinned place above the dial (To get, Today): out of the loop, in the hot colour with its count, across the
/// whole width so it can grow to 1.5 when open without running into the open place.
private struct RailPinned: View {
    let place: RailPlace
    let accent: Color
    @Binding var open: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ticks = 0

    private var calm: Bool {
        reduceMotion || PowerState.isLowPower
    }

    private var pinnedOpen: Bool {
        place.id == open
    }

    var body: some View {
        Button {
            guard !pinnedOpen else { return }
            ticks += 1
            withTesseraAnimation(RailMetrics.snap, reduceMotion: calm) { open = place.id }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(place.name)
                    .font(Theme.voice(size: RailMetrics.pinnedSize))
                Text("\(place.count)")
                    .textRole(.data)
                    .contentTransition(.numericText())
            }
            .foregroundStyle(place.count > 0 || pinnedOpen ? accent : Theme.Colors.inkSecondary)
            .scaleEffect(pinnedOpen && !calm ? RailMetrics.pinnedOpenScale : 1, anchor: .bottomLeading)
            .frame(maxWidth: .infinity, minHeight: pinnedOpen && !calm ? 56 : 44, alignment: .bottomLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .tesseraAnimation(RailMetrics.snap, value: pinnedOpen)
        .tesseraFeedback(.selection, trigger: ticks)
        .accessibilityLabel("\(place.name), \(place.count)")
        .accessibilityAddTraits(pinnedOpen ? .isSelected : [])
    }
}

/// One place on the dial, placed by the turn: its slot, size, ink and bow follow its distance from the focus, and
/// the turn is animatable, so a snap moves every place along the loop (never across it).
private struct DialSlot: ViewModifier, Animatable {
    let index: Int
    let count: Int
    var turn: Double
    let calm: Bool
    let dimmed: Bool

    nonisolated var animatableData: Double {
        get { turn }
        set { turn = newValue }
    }

    func body(content: Content) -> some View {
        let distance = Self.distance(index: index, turn: turn, count: count)
        let near = min(abs(distance), 1)
        let eased = near * near * (3 - 2 * near)
        let reach = Double(RailMetrics.reach)
        // A place past the far slots fades out and returns from the other end.
        let edge = max(0, min(1, (reach + 0.5 - abs(distance)) / 0.5))
        let ink = (1 - (1 - RailMetrics.farInk) * min(abs(distance) / 1.5, 1)) * edge
        let scale = calm ? 1 : RailMetrics.focusScale - (RailMetrics.focusScale - RailMetrics.farScale) * eased
        let y = (reach + distance) * RailMetrics.slot
        return content
            .scaleEffect(scale * (dimmed && !calm ? 0.82 : 1), anchor: .leading)
            .opacity(ink * (dimmed ? 0.5 : 1))
            .frame(height: RailMetrics.slot, alignment: .center)
            .offset(x: calm ? 0 : RailMetrics.bow * CGFloat(distance * distance), y: CGFloat(y))
            .allowsHitTesting(abs(distance) < reach + 0.5)
    }

    /// The signed distance round the loop, in places: in −count/2 ..< count/2.
    static func distance(index: Int, turn: Double, count: Int) -> Double {
        guard count > 0 else { return 0 }
        let size = Double(count)
        var gap = (Double(index) - turn).truncatingRemainder(dividingBy: size)
        if gap < -size / 2 {
            gap += size
        }
        if gap >= size / 2 {
            gap -= size
        }
        return gap
    }
}
