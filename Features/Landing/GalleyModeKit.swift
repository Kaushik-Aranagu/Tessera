import SwiftUI

/// The shared pieces of the Galley's whole-screen modes (sheets 327 to 329): the cream ticket paper that stays paper
/// in the black look, the dotted-leader ledger row, the steps down the right edge, the verb in the thumb zone and the
/// receipt above it. Every mode reads top to bottom: what this is, the one big thing, the facts that serve it.
enum GalleyPaper {
    /// Paper stays paper in the black look, like the real ticket: these do not follow the colour scheme.
    static let sheet = Color(hex: 0xF6EFDF)
    static let ink = Color(hex: 0x2B2722)
    static let inkSecondary = Color(hex: 0x6B6258)
    static let ochre = Color(hex: 0x93611A)
    static let olive = Color(hex: 0x5E6B1F)
    static let wine = Color(hex: 0x9A2541)

    static func plex(_ weight: Weight, _ size: CGFloat) -> Font {
        .custom(weight.face, fixedSize: size)
    }

    static func number(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .custom("Outfit", fixedSize: size).weight(weight)
    }

    enum Weight {
        case regular, medium, bold

        var face: String {
            switch self {
            case .regular: "IBMPlexSansCond-Regular"
            case .medium: "IBMPlexSansCond-Medium"
            case .bold: "IBMPlexSansCond-Bold"
            }
        }
    }
}

/// A ledger row with dotted leaders from the name to its amount ("Chicken thighs ........ 1 lb"); a struck row reads
/// as got.
struct GalleyLeaderRow: View {
    let name: String
    var amount: String?
    var struck = false
    var size: CGFloat = 18

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(name)
                .font(GalleyPaper.plex(.regular, size))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
            Rectangle()
                .fill(.clear)
                .frame(height: 1)
                .overlay(alignment: .bottom) {
                    DottedLine().stroke(
                        GalleyPaper.inkSecondary.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.2, dash: [1.5, 4])
                    )
                    .frame(height: 1)
                }
                .offset(y: -3)
            if let amount {
                Text(amount)
                    .font(GalleyPaper.number(size, weight: .regular))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(struck ? GalleyPaper.inkSecondary : GalleyPaper.ink)
        .strikethrough(struck, color: GalleyPaper.inkSecondary)
        .accessibilityElement(children: .combine)
    }
}

private struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// One item of the steps (lifts, steps, aisles) down the right edge.
struct GalleyRailItem: Identifiable, Equatable {
    let id: Int
    let label: String
    /// A count or a time beside it.
    var detail: String?
    var current = false
    var done = false
}

/// The steps down the right edge above Tess; tap one to jump. Short names, never cut: a name that is too wide steps
/// down in size.
struct GalleyModeRail: View {
    let items: [GalleyRailItem]
    var tint: Color = GalleyPaper.ochre
    var tap: (Int) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            ForEach(items) { item in
                Button { tap(item.id) } label: {
                    HStack(spacing: 6) {
                        if let detail = item.detail {
                            Text(detail)
                                .font(GalleyPaper.number(14, weight: .regular))
                                .monospacedDigit()
                        }
                        Text(item.label)
                            .font(GalleyPaper.plex(item.current ? .bold : .regular, item.current ? 20 : 17))
                            .strikethrough(item.done, color: GalleyPaper.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(item.current ? tint : item.done ? GalleyPaper.inkSecondary.opacity(0.7)
                        : GalleyPaper.inkSecondary)
                    .frame(minHeight: 30, alignment: .trailing)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.label + (item.detail.map { ", \($0)" } ?? ""))
                .accessibilityAddTraits(item.current ? [.isSelected] : [])
            }
        }
        .frame(maxWidth: 150, alignment: .trailing)
    }
}

/// The verb bottom left at 44 pt in the room colour, with its object under it. Tap does it; a hold verb (Finish)
/// asks for a hold. A swipe up anywhere on the screen does the same (the screen adds that gesture).
struct GalleyModeVerb: View {
    let word: String
    var object: String?
    var hold = false
    var tint: Color = GalleyPaper.ochre
    var act: () -> Void

    @State private var held = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(word)
                .font(GalleyPaper.plex(.bold, 44))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let object, !object.isEmpty {
                Text(object)
                    .font(GalleyPaper.plex(.regular, 17))
                    .foregroundStyle(GalleyPaper.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(minHeight: 60, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if !hold {
                act()
            }
        }
        .onLongPressGesture(minimumDuration: 0.7) {
            if hold {
                act()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(object.map { "\(word), \($0)" } ?? word)
        .accessibilityHint(hold ? "Hold to do it" : "Does it")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { act() }
    }
}

/// The receipt just above the thumb zone: what happened, with Undo while it can be taken back.
struct GalleyModeReceipt: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let voice = TessVoice.shared

    var body: some View {
        if let note = voice.note {
            HStack(spacing: 12) {
                Text(note.text)
                    .font(GalleyPaper.plex(.medium, 15))
                    .foregroundStyle(GalleyPaper.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if note.undo != nil || note.takeBack != nil {
                    Button("Undo") { undo(note) }
                        .font(GalleyPaper.plex(.bold, 15))
                        .foregroundStyle(GalleyPaper.ochre)
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                }
            }
            .transition(.opacity)
        }
    }

    private func undo(_ note: TessVoice.Note) {
        if let record = note.undo {
            _ = model.engine.undo(record)
        }
        note.takeBack?()
        model.touch()
        withTesseraAnimation(reduceMotion: reduceMotion) { voice.clear() }
    }
}

/// The page every mode sits on: cream paper full bleed, the clip the ticket hangs from, the room's name top left
/// (goes back) and a count top right. Swipe up anywhere does the verb.
struct GalleyModeScreen<Content: View, Thumb: View>: View {
    let room: String
    let topRight: String
    var back: () -> Void
    var verb: () -> Void
    @ViewBuilder var content: Content
    @ViewBuilder var thumb: Thumb

    var body: some View {
        ZStack(alignment: .topLeading) {
            GalleyPaper.sheet.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Button(action: back) {
                        Text(room.uppercased())
                            .font(GalleyPaper.plex(.bold, 16))
                            .tracking(16 * 0.08)
                            .foregroundStyle(GalleyPaper.ochre)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back to \(room)")
                    Spacer()
                    Text(topRight)
                        .font(GalleyPaper.plex(.medium, 16))
                        .foregroundStyle(GalleyPaper.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.top, 8)
                content
                Spacer(minLength: 0)
                thumb
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(GalleyPaper.inkSecondary).frame(width: 18, height: 6).padding(.top, 2)
                .accessibilityHidden(true)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                guard value.translation.height < -60, abs(value.translation.height) > abs(value.translation.width) * 1.5
                else { return }
                verb()
            }
        )
        .preferredColorScheme(.light)
    }
}

/// Sheet 332: "Got" draws a pen stroke through the line from left to right at a slight angle, 300 ms, then the words
/// fade. The stroke is a trimmed path, so it is drawn by animating `progress` from 0 to 1.
struct GalleyPenStroke: Shape {
    /// How far across the stroke is drawn, 0 to 1.
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// Left edge a little low, right edge a little high: a slight angle, like a hand.
    static func ends(in rect: CGRect) -> (start: CGPoint, end: CGPoint) {
        (
            CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.62),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.5)
        )
    }

    func path(in rect: CGRect) -> Path {
        let ends = Self.ends(in: rect)
        var path = Path()
        path.move(to: ends.start)
        path.addLine(to: ends.end)
        return path.trimmedPath(from: 0, to: min(max(progress, 0), 1))
    }
}
