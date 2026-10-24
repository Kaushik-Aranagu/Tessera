import SwiftUI
import TesseraCore

// The Kitchen's shared pieces (sheets 231 to 233): the place dial, the focus wheel, the receipt line and the foot.
// No data of their own; Pantry, Recipes, the landing and cooking all draw with these. No cards, bars, dots, fades or
// food drawings. With Reduce Motion everything lands in one step; the ticks stay.

// MARK: - Loop maths

/// How a looping list sits around its focus, pure so it tests without a screen.
@MainActor
enum KitchenLoop {
    /// Steps from `focus` to `index` the nearer way round: -(count - 1) / 2 through count / 2.
    static func relative(_ index: Int, focus: Int, count: Int) -> Int {
        AppsListRows.relative(index, middle: focus, count: count)
    }

    static func wrapped(_ index: Int, _ delta: Int, count: Int) -> Int {
        AppsListRows.wrapped(index, delta, count: count)
    }

    /// Whole places a drag of `translation` points has turned (`step` points each), toward zero. Up is positive.
    static func consumed(translation: CGFloat, step: CGFloat) -> Int {
        Int((-translation / step).rounded(.towardZero))
    }

    /// Where a lifted finger lands, in places from the focus now: a flick moves exactly one place the way it went; a
    /// slow drag goes to the nearest place. `rest` is the drag left over inside the current place.
    static func landing(rest: CGFloat, step: CGFloat, velocity: CGFloat, turned: Int, travel: CGFloat) -> Int {
        if turned == 0, abs(velocity) > 300 || abs(travel) > 20 {
            return (abs(velocity) > 300 ? velocity : travel) < 0 ? 1 : -1
        }
        return rest < -step / 2 ? 1 : rest > step / 2 ? -1 : 0
    }

    /// "Fridge, 8 things": the spoken count of a place.
    static func spoken(_ name: String, count: Int) -> String {
        "\(name), \(count) \(count == 1 ? "thing" : "things")"
    }
}

// MARK: - Names

/// A name that fits its line without an ellipsis: Tess's short form past `limit` characters, cut at a word edge, and a
/// hard cut at the limit only for one long word. Pure.
@MainActor
enum KitchenText {
    static func short(_ name: String, limit: Int = 20) -> String {
        guard name.count > limit else { return name }
        var words = RecipeBook.shortName(ofTitle: name).split(separator: " ").map(String.init)
        while words.count > 1, words.joined(separator: " ").count > limit {
            words.removeLast()
        }
        let joined = HomeBoard.trimTail(words.joined(separator: " "))
        return joined.count > limit ? String(joined.prefix(limit)) : joined
    }

    /// What a surface outside the room may say of a thing: the walled label for a private name, else the short form.
    @MainActor
    static func shown(_ name: String, in store: ObjectStore, limit: Int = 20) -> String {
        let walled = ObjectPrivacy.isPrivateTitle(name, lastWeightKg: BodyWeight.lastKg(in: store))
        return walled ? "Private item" : short(name, limit: limit)
    }
}

// MARK: - Place dial

/// The headline dial (sheet 231 to 233): three 64 pt slots in a 196 pt headline. The focus is 44 pt Figtree 600 in
/// kitchen with its count in Outfit 200 in ink; a neighbour is 26 pt at 400 in ink 2 with its count in Outfit 300. It
/// loops. A drag tracks the finger 1:1 and snaps on a spring, a flick moves exactly one place, a tap on a neighbour
/// centres it, and each place passed is one light tick. VoiceOver adjusts it. At AX3 and up it shows the focus and the
/// next place, and the slot grows a line.
struct PlaceDial: View {
    struct Place: Identifiable, Equatable {
        let id: String
        let name: String
        let count: Int
    }

    let places: [Place]
    @Binding var focus: Int
    /// A tap on the focus (Pantry: nothing; Recipes: opens the full list).
    var onTapFocus: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var drag: CGFloat = 0
    @State private var turned = 0
    @State private var ticks = 0

    static let slot: CGFloat = 64
    static let headline: CGFloat = 196
    static let focusSize: CGFloat = 44
    static let neighbourSize: CGFloat = 26

    private var large: Bool {
        typeSize >= .accessibility3
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(places.indices, id: \.self) { index in
                let rel = KitchenLoop.relative(index, focus: focus, count: places.count)
                if abs(rel) <= 2, !large || (rel >= 0 && rel <= 1) {
                    row(places[index], rel: rel)
                        .offset(y: (CGFloat(rel) + (large ? 0 : 1)) * Self.slot + drag)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.headline, alignment: .top)
        .frame(height: large ? nil : Self.headline, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    guard places.count > 1 else { return }
                    let total = KitchenLoop.consumed(translation: value.translation.height, step: Self.slot)
                    if total != turned {
                        focus = KitchenLoop.wrapped(focus, total - turned, count: places.count)
                        turned = total
                        ticks += 1
                    }
                    drag = value.translation.height + CGFloat(turned) * Self.slot
                }
                .onEnded { value in
                    let steps = KitchenLoop.landing(rest: drag, step: Self.slot,
                                                    velocity: value.velocity.height,
                                                    turned: turned, travel: value.translation.height)
                    turned = 0
                    settle(by: steps)
                }
        )
        .tesseraFeedback(.dialStep, trigger: ticks)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place")
        .accessibilityValue(places.indices.contains(focus)
            ? KitchenLoop.spoken(places[focus].name, count: places[focus].count) : "")
        .accessibilityAdjustableAction { direction in
            settle(by: direction == .increment ? 1 : -1)
        }
    }

    private func row(_ place: Place, rel: Int) -> some View {
        let isFocus = rel == 0
        // Every row is laid out at the focus size and scaled down, so a place swells as it arrives and its width is
        // never a surprise.
        let scale = isFocus ? 1 : Self.neighbourSize / Self.focusSize
        return Button {
            if isFocus {
                onTapFocus()
            } else {
                settle(by: rel)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(KitchenText.short(place.name, limit: 12))
                    .font(Theme.voice(size: Self.focusSize).weight(isFocus ? .semibold : .regular))
                    .foregroundStyle(isFocus ? Theme.Colors.Accent.kitchen : Theme.Colors.inkSecondary)
                    .lineLimit(1)
                Text("\(place.count)")
                    .font(Theme.numeral(Self.focusSize))
                    .foregroundStyle(isFocus ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                    .contentTransition(.numericText())
            }
            .fixedSize()
            .scaleEffect(scale, anchor: .leading)
            .frame(maxWidth: .infinity, minHeight: Self.slot, maxHeight: Self.slot, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private func settle(by steps: Int) {
        guard !places.isEmpty else { return }
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            if steps != 0 {
                focus = KitchenLoop.wrapped(focus, steps, count: places.count)
                ticks += 1
            }
            drag = 0
        }
    }
}

// MARK: - Focus wheel

/// The wheel (sheet 230): the focus is the FIRST slot, 50 pt tall with room for two detail lines; every other row is
/// 38 pt. It loops: scrolling moves the next item up into focus and the old one goes round to the back. A drag tracks
/// the finger, a flick moves one row, it snaps on a spring with a tick per row, a tap on a row brings it to the top
/// and a tap on the focus opens it. There is no spring-back; the height always ends on a row boundary (202 pt in a
/// band, 392 pt on a full page).
struct FocusWheel<Item: Identifiable, Content: View>: View where Item.ID: Hashable {
    let items: [Item]
    @Binding var top: Int
    /// Rows under the focus: 4 in a band (202 pt), 9 on a full page (392 pt).
    var others = 4
    /// The focus slot: 50 pt for plain names, about 80 pt where it carries two detail lines.
    var focusHeight: CGFloat = FocusWheel<Item, Content>.defaultFocusHeight
    var onOpen: (Item) -> Void = { _ in }
    /// The row at a fractional place: `focus` runs 1 on the focus down to 0 a row away, so size and weight can carry
    /// the distance; `distance` is the whole places from the top.
    @ViewBuilder let content: (Item, _ focus: Double, _ distance: Int) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var drag: CGFloat = 0
    @State private var turned = 0
    @State private var ticks = 0

    static var defaultFocusHeight: CGFloat {
        50
    }

    static var rowHeight: CGFloat {
        38
    }

    /// 202 pt for a band, 392 pt for a full page (with the 50 pt focus; 232 and 422 with the 80 pt one): the focus
    /// plus the rows under it, always ending on a row boundary.
    static func height(others: Int, focusHeight: CGFloat = defaultFocusHeight) -> CGFloat {
        focusHeight + CGFloat(others) * rowHeight
    }

    private var rowsShown: Int {
        typeSize >= .accessibility3 ? min(others, 2) : others
    }

    /// Where the top edge of a row `place` places from the top sits, in points (the focus row is taller).
    static func y(_ place: CGFloat, focusHeight: CGFloat = defaultFocusHeight) -> CGFloat {
        if place >= 1 {
            return focusHeight + (place - 1) * rowHeight
        }
        return place >= 0 ? place * focusHeight : place * rowHeight
    }

    /// A row's height at a fractional place: the focus height at 0, the plain row height a place away.
    static func height(at place: CGFloat, focusHeight: CGFloat = defaultFocusHeight) -> CGFloat {
        rowHeight + (focusHeight - rowHeight) * max(0, 1 - abs(place))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(items.indices, id: \.self) { index in
                let rel = (index - top + items.count) % max(items.count, 1)
                // A row past the bottom waits above the focus, so the ring turns without a gap.
                let place = rel <= rowsShown + 1 ? rel : rel - items.count
                let at = CGFloat(place) + drag / Self.rowHeight
                if place >= -1, place <= rowsShown + 1 {
                    Button {
                        if rel == 0 {
                            onOpen(items[index])
                        } else {
                            settle(by: rel)
                        }
                    } label: {
                        content(items[index], Double(max(0, 1 - abs(at))), place)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: Self.height(at: at, focusHeight: focusHeight), alignment: .top)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(y: Self.y(at, focusHeight: focusHeight))
                    .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Self.height(others: rowsShown, focusHeight: focusHeight), alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    guard items.count > 1 else { return }
                    let total = KitchenLoop.consumed(translation: value.translation.height, step: Self.rowHeight)
                    if total != turned {
                        top = KitchenLoop.wrapped(top, total - turned, count: items.count)
                        turned = total
                        ticks += 1
                    }
                    drag = value.translation.height + CGFloat(turned) * Self.rowHeight
                }
                .onEnded { value in
                    let steps = KitchenLoop.landing(rest: drag, step: Self.rowHeight,
                                                    velocity: value.velocity.height,
                                                    turned: turned, travel: value.translation.height)
                    turned = 0
                    settle(by: steps)
                }
        )
        .tesseraFeedback(.dialStep, trigger: ticks)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("List")
        .accessibilityAdjustableAction { direction in
            settle(by: direction == .increment ? 1 : -1)
        }
    }

    private func settle(by steps: Int) {
        guard !items.isEmpty else { return }
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            if steps != 0 {
                top = KitchenLoop.wrapped(top, steps, count: items.count)
                ticks += 1
            }
            drag = 0
        }
    }
}

// MARK: - Receipt line

/// What the Kitchen says after a change (sheet 231): "Thing, what happened. Undo". One fixed 26 pt line above the foot.
/// It lasts 10 s, the newest replaces it, and it clips in from the top in 0.3 s.
@MainActor
@Observable
final class KitchenReceipts {
    struct Line: Equatable, Identifiable {
        let id = UUID()
        let text: String
        var undo: (() -> Void)?

        static func == (lhs: Line, rhs: Line) -> Bool {
            lhs.id == rhs.id
        }
    }

    private(set) var line: Line?

    /// "Milk, used up. On To get." with the one Undo, kept 10 s.
    func say(_ text: String, undo: (() -> Void)? = nil) {
        let next = Line(text: text, undo: undo)
        line = next
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            if line?.id == next.id {
                line = nil
            }
        }
    }

    func undo() {
        guard let line else { return }
        line.undo?()
        self.line = nil
    }
}

struct ReceiptLine: View {
    let receipts: KitchenReceipts
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let height: CGFloat = 26

    var body: some View {
        ZStack(alignment: .leading) {
            if let line = receipts.line {
                HStack(spacing: 6) {
                    Text(line.text)
                        .font(Theme.voice(size: 15))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                    if line.undo != nil {
                        Button("Undo") { receipts.undo() }
                            .font(Theme.voice(size: 15).weight(.semibold))
                            .foregroundStyle(Theme.Colors.Accent.kitchenText)
                            .buttonStyle(.plain)
                            .frame(minHeight: 26)
                            .contentShape(Rectangle().inset(by: -10))
                    }
                }
                .id(line.id)
                .transition(reduceMotion ? .identity : .modifier(active: ReceiptClip(progress: 0),
                                                                 identity: ReceiptClip(progress: 1)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.height, maxHeight: Self.height, alignment: .leading)
        .clipped()
        .animation(MotionPolicy.resolve(.easeOut(duration: 0.3), reduceMotion: reduceMotion), value: receipts.line?.id)
        .accessibilityElement(children: .contain)
    }
}

/// The line is revealed from its top edge down.
struct ReceiptClip: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        content.mask(alignment: .top) {
            Rectangle().scaleEffect(y: max(progress, 0.001), anchor: .top)
        }
    }
}

// MARK: - Brief

/// One brief line (22 pt, one line, no wrap): a line that changes is clipped in from the top, never faded.
struct KitchenBriefLine: View {
    let text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let height: CGFloat = 22

    var body: some View {
        ZStack(alignment: .leading) {
            Text(text.isEmpty ? " " : text)
                .font(Theme.voice(size: 17))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .id(text)
                .transition(reduceMotion ? .identity : .modifier(active: ReceiptClip(progress: 0),
                                                                 identity: ReceiptClip(progress: 1)))
        }
        .frame(maxWidth: .infinity, minHeight: Self.height, maxHeight: Self.height, alignment: .leading)
        .clipped()
        .animation(MotionPolicy.resolve(.easeOut(duration: 0.3), reduceMotion: reduceMotion), value: text)
    }
}

// MARK: - Foot

/// The foot: one action word bottom-left (19 pt 600 in kitchen); Tess keeps the bottom-right corner. The left edge goes
/// back and a tap on the title opens the room index (the caller wires both).
struct KitchenFoot: View {
    let action: String?
    var hint: String?
    let perform: () -> Void

    var body: some View {
        HStack {
            if let action {
                Button(action: perform) {
                    Text(action)
                        .font(Theme.voice(size: 19).weight(.semibold))
                        .foregroundStyle(Theme.Colors.Accent.kitchen)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(hint ?? "")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
    }
}

// MARK: - Calories hook

/// Calories show in the Kitchen room only, behind Settings "Show calories". Core's nutrition table is not here yet:
/// until `Nutrition.perServing` exists and returns a value, both the line and the switch stay hidden. This is the one
/// hook that lights them up.
enum KitchenCalories {
    /// About how many calories a serving has, or nil while there is no table (the line is then not drawn).
    @MainActor
    static func perServing(of _: ObjectRecord, servings _: Int, in _: ObjectStore) -> Int? {
        nil
    }

    /// The Settings switch is offered only when there is a table.
    @MainActor static var isAvailable: Bool {
        false
    }
}
