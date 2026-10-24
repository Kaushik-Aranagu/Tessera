import SwiftUI
import TesseraCore
import TesseraTess

// Sheet 215 rev 5 to 16: Tess's own layer. A tap or a hold on her brings her into focus: Home sits under an 18 pt
// blur (saturation 1.15, a 52% page tint; with Reduce Transparency a 92% page colour), and she moves to the bottom
// middle. The layer is one running conversation: today's earlier turns above, smaller and quieter with their time
// markers, the newest exchange large (her line 23 pt, his 17), at most three plain replies, and a "Type to Tess"
// field. Her words arrive one at a time, never as letter flips. All text clears when it closes; the layer is masked
// in the app switcher.

/// The one sanctioned blur on Home: it is hers. Applied to Home's content while her layer is open.
struct TessBackdrop: ViewModifier {
    var open: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    static let blur: CGFloat = 18
    static let saturation = 1.15
    static let tint = 0.52
    static let tintReducedTransparency = 0.92

    func body(content: Content) -> some View {
        content
            .blur(radius: open && !reduceTransparency ? Self.blur : 0)
            .saturation(open && !reduceTransparency ? Self.saturation : 1)
            .overlay {
                Theme.Colors.paper
                    .opacity(open ? (reduceTransparency ? Self.tintReducedTransparency : Self.tint) : 0)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
            .allowsHitTesting(!open)
            .tesseraAnimation(Theme.Motion.house, value: open)
    }
}

extension View {
    func tessBackdrop(open: Bool) -> some View {
        modifier(TessBackdrop(open: open))
    }
}

/// Words wrapped left to right; a unit (a word or a door's whole name) is never broken across lines.
struct TessFlow: Layout {
    var spacing: CGFloat = 5
    var lineSpacing: CGFloat = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let placed = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in placed.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return (CGSize(width: widest, height: y + lineHeight), origins)
    }
}

/// One line of hers: its words in Newsreader and ink, the doors at weight 500, arriving one at a time.
struct TessLineView: View {
    let line: TessLayerModel.Line
    var font: Font
    var color: Color
    var arriving: Bool
    var echoName: String?
    var onArrived: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    /// The units of the line: each door's name whole, the rest word by word.
    private var units: [(text: String, isDoor: Bool)] {
        var result: [(String, Bool)] = []
        var rest = Substring(line.text)
        while !rest.isEmpty {
            let hit = line.names.compactMap { name in rest.range(of: name).map { (name, $0) } }
                .min { $0.1.lowerBound < $1.1.lowerBound }
            let head = hit.map { rest[rest.startIndex ..< $0.1.lowerBound] } ?? rest
            result += head.split(separator: " ").map { (String($0), false) }
            if let hit {
                result.append((hit.0, true))
                rest = rest[hit.1.upperBound...]
            } else {
                rest = ""
            }
        }
        return result
    }

    var body: some View {
        let units = units
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !arriving || reduceMotion)) { context in
            let elapsed = reduceMotion || !arriving ? .infinity : context.date.timeIntervalSince(start)
            TessFlow {
                ForEach(Array(units.enumerated()), id: \.offset) { index, unit in
                    let delay = delay(of: index, units: units)
                    Text(unit.text)
                        .font(unit.isDoor ? TessFont.line(TessFont.layerSize, weight: .medium) : font)
                        .foregroundStyle(unit.isDoor && echoName == unit.text ? Theme.Colors.ink : color)
                        .fixedSize()
                        .offset(y: TessWords.offset(elapsed: elapsed, delay: delay))
                        .opacity(TessWords.isShown(elapsed: elapsed, delay: delay) ? 1 : 0)
                }
            }
            .onChange(of: elapsed >= TessWords.total(line.text)) { _, done in
                if done, arriving {
                    onArrived()
                }
            }
        }
        // VoiceOver reads the whole line at once, and never re-announces the echo.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(line.text)
        .onAppear { start = Date() }
    }

    private func delay(of index: Int, units: [(text: String, isDoor: Bool)]) -> TimeInterval {
        var delay = 0.0
        for earlier in units.prefix(index) {
            delay += TessWords.perWord
            if let last = earlier.text.last, ".,?!:;".contains(last) {
                delay += TessWords.afterPunctuation
            }
        }
        return delay
    }
}

struct TessConversationLayer: View {
    @Bindable var model: TessLayerModel
    /// Closes the layer (tap on Home, swipe down, tap her, Escape, "That's all").
    var close: () -> Void
    /// What she says to a reply that is not "That's all": from the host.
    var answer: (String) -> String? = { _ in nil }
    /// Called when he sends typed words: the host answers.
    var send: (String) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var typing: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            // A tap on the blurred Home closes the layer.
            Color.clear.contentShape(Rectangle()).onTapGesture { close() }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 18) {
                Text(model.stateLine)
                    .font(Theme.voice(size: 15))
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .frame(minHeight: 22, alignment: .leading)
                    .accessibilityHidden(model.stateLine.isEmpty)
                conversation
                if !model.liveSpeech.isEmpty {
                    Text(model.liveSpeech)
                        .font(Theme.voice(size: 28).weight(.light))
                        .foregroundStyle(Theme.Colors.ink)
                }
                replies
                field
            }
            .padding(.horizontal, 28)
            .padding(.top, 76)
            .padding(.bottom, 206)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .pullGesture { down in
                if down {
                    close()
                }
            }
            // Masked in the app switcher: the layer's words never sit in a snapshot.
            if scenePhase != .active {
                Theme.Colors.paper.ignoresSafeArea().accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
        .focusable()
        .onKeyPress(.escape) {
            close()
            return .handled
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Tess")
    }

    private var conversation: some View {
        let lines = model.lines
        let markers = TessTimeMarker.markers(for: lines.map(\.date))
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                if let marker = markers[index] ?? (index == lines.count - 1 ? nil : nil) {
                    timeMarker(marker)
                }
                lineView(line, newest: index >= lines.count - 2 && index >= max(lines.count - 2, 0))
            }
            if let marker = model.openingMarker {
                timeMarker(marker)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeMarker(_ text: String) -> some View {
        Text(text)
            .font(Font.custom("Outfit", size: 12, relativeTo: .caption).weight(.ultraLight))
            .tracking(0.72)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .padding(.top, 10)
            .accessibilityLabel(text)
    }

    @ViewBuilder
    private func lineView(_ line: TessLayerModel.Line, newest: Bool) -> some View {
        switch line.role {
        case .tess:
            TessLineView(line: line, font: newest ? TessFont.newest : TessFont.inLayer,
                         color: newest ? Theme.Colors.ink : Theme.Colors.inkSecondary,
                         arriving: model.arriving == line.id,
                         echoName: model.echo?.line == line.id ? model.echo?.name : nil,
                         onArrived: { model.arrived(line.id) })
        case .user:
            Text(line.text)
                .font(Theme.voice(size: newest ? 17 : 16))
                .foregroundStyle(newest ? Theme.Colors.inkSecondary : Theme.Colors.inkTertiary)
        }
    }

    private var replies: some View {
        FlowReplies(replies: model.replies, picked: model.picked) { reply in
            Task {
                if await model.choose(reply, answer: answer) {
                    close()
                }
            }
        }
    }

    /// The field is multi-line (rev 19 F6): Enter sends and Shift-Enter adds a line on a hardware keyboard; on the
    /// phone
    /// keyboard return adds a line and the arrow sends. It is transient: it exists only while her layer is open.
    private var field: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("", text: $model.draft, prompt: Text("Type to Tess").foregroundStyle(Theme.Colors.inkTertiary),
                      axis: .vertical)
                .font(Theme.voice(size: 18))
                .foregroundStyle(Theme.Colors.ink)
                .tint(Theme.Colors.tess)
                .lineLimit(1 ... 4)
                .focused($typing)
                .onKeyPress(.return, phases: .down) { press in
                    if press.modifiers.contains(.shift) {
                        model.draft += "\n"
                        return .handled
                    }
                    submit()
                    return .handled
                }
                .accessibilityLabel("Type to Tess")
            if !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button { submit() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send")
            }
        }
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.hairline).frame(height: 1) }
    }

    private func submit() {
        let text = model.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        model.hear(text)
        send(text)
    }
}

/// At most three plain replies: ink words with no underline; the picked one flashes cobalt for 0.22 s.
private struct FlowReplies: View {
    let replies: [String]
    let picked: String?
    let choose: (String) -> Void

    var body: some View {
        TessFlow(spacing: 22, lineSpacing: 6) {
            ForEach(replies, id: \.self) { reply in
                Button { choose(reply) } label: {
                    Text(reply)
                        .font(Theme.voice(size: 17))
                        .foregroundStyle(picked == reply ? Theme.Colors.tess : Theme.Colors.ink)
                        .fixedSize()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minHeight: 26, alignment: .leading)
    }
}
