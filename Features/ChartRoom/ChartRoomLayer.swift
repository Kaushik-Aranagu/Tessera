import SwiftUI

/// Everything the Chart room draws over the shell (sheet 357): the dashed outlines of the empty places with their
/// names, the drying line along the foot of each place a patch fills, what he said while Tess works, and the reach
/// line with Allow. The parts themselves are in the shell's own places (`DocumentRoom`); this layer holds no content of
/// its own and lets every touch through except Allow and a tap on a ghost.
struct ChartRoomLayer: View {
    let model: ChartRoomModel

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    /// The blank room's outlines unroll once as the room opens (sheet 366).
    @State private var unrolled = false

    private var reduceMotion: Bool {
        systemReduceMotion || ShellProbe.reduceMotion
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = max(0.86, min(1.1, proxy.size.height / 874))
            let dx = (proxy.size.width - 402) / 2
            let committed = PartResolver.resolve(model.document) { [data = model.data] in data.items($0) }
            let ghosts = model.ghostPlaces
            ZStack(alignment: .topLeading) {
                ForEach(DocumentRoom.outlined, id: \.place) { entry in
                    let rect = frame(entry.place, scale: scale, dx: dx)
                    // Sheet 362: a ghost on a place brings its outline down too, so the dashed line never crosses a
                    // word.
                    let set = committed[entry.place] != nil || ghosts.contains(entry.place)
                        || (entry.place == .widget && model.reachLine != nil)
                    let step = OutlineSetting.frame(at: 1, y: 0, setting: set, reduceMotion: reduceMotion)
                    let rank = DocumentRoom.outlined.firstIndex { $0.place == entry.place } ?? 0
                    Outline(name: entry.name, showsName: !ghosts.contains(entry.place) && (unrolled || reduceMotion),
                            drawn: unrolled || reduceMotion ? 1 : 0)
                        .animation(reduceMotion ? nil : OutlineUnroll.animation(rank: rank), value: unrolled)
                        .frame(width: rect.width - 4, height: rect.height - 4, alignment: .topLeading)
                        .scaleEffect(step.scale)
                        .opacity(step.opacity)
                        .offset(x: rect.minX + 2, y: rect.minY + 2 + step.offset)
                        .animation(
                            OutlineSetting.animation(y: rect.minY / scale, reduceMotion: reduceMotion),
                            value: set
                        )
                        .allowsHitTesting(false)
                }
                if let pending = model.pending {
                    ForEach(Place.allCases.filter { ghosts.contains($0) && $0 != .actionWord }, id: \.self) { place in
                        let rect = frame(place, scale: scale, dx: dx)
                        DryingLine(reduceMotion: reduceMotion)
                            .frame(width: rect.width - 4, height: 1)
                            .offset(x: rect.minX + 2, y: rect.maxY - 2)
                            .allowsHitTesting(false)
                    }
                    .id(pending.id)
                    if !pending.needsAllow {
                        ForEach(Place.allCases.filter { ghosts.contains($0) }, id: \.self) { place in
                            let rect = frame(place, scale: scale, dx: dx)
                            Color.clear
                                .frame(width: rect.width, height: rect.height)
                                .contentShape(Rectangle())
                                .onTapGesture { model.tapGhost() }
                                .offset(x: rect.minX, y: rect.minY)
                                .accessibilityHidden(true)
                        }
                    }
                }
                // A tap on a filled place picks it (sheet 360); the picked one wears a slate line 6 pt outside.
                if model.pending == nil {
                    ForEach([Place.title, .switcher, .keystone, .caption, .widget].filter { committed[$0] != nil },
                            id: \.self)
                    { place in
                        let rect = frame(place, scale: scale, dx: dx)
                        Color.clear
                            .frame(width: rect.width, height: rect.height)
                            .contentShape(Rectangle())
                            .onTapGesture { model.pick(place) }
                            .offset(x: rect.minX, y: rect.minY)
                            .accessibilityHidden(true)
                    }
                }
                if let place = model.picked {
                    let rect = frame(place, scale: scale, dx: dx).insetBy(dx: -6, dy: -6)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.Colors.Accent.chart, lineWidth: 1.5)
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.minX, y: rect.minY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                noteLine(scale: scale)
                widgetNote(scale: scale, dx: dx)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .tesseraFeedback(model.cue)
        .onAppear { unrolled = true }
    }

    /// A place's frame on screen; the Line runs the Needs' width too, and Doors is the dial and its summary together.
    private func frame(_ place: Place, scale: CGFloat, dx: CGFloat) -> CGRect {
        func rect(_ place: Place) -> CGRect {
            ShellLayout.screenRect(place, in: .landing, scale: scale, typeSize: typeSize)
        }
        var out = rect(place)
        if place == .switcher {
            out.size.width = 354
        }
        if place == .dial {
            out = out.union(rect(.doorSummary))
        }
        out.origin.x += dx
        return out
    }

    /// Tess's refusal line above the foot, with her offer as one plain button (sheet 361).
    @ViewBuilder
    private func noteLine(scale: CGFloat) -> some View {
        if let note = model.note {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                FitLine(forms: FitLine.cuts(note.line), size: 15, color: Theme.Colors.inkSecondary, weight: .medium)
                if let button = note.button {
                    Button { model.takeOffer() } label: {
                        Text(button)
                            .font(.custom("Figtree", size: 15, relativeTo: .callout).weight(.bold))
                            .foregroundStyle(Theme.Colors.Accent.chart)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("chart.offer")
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(width: 354, alignment: .leading)
            .offset(x: 24, y: 730 * scale)
        }
    }

    /// While Tess works, what he said, in quotes (Newsreader italic 20, ink 2); then the reach line with Allow.
    @ViewBuilder
    private func widgetNote(scale: CGFloat, dx: CGFloat) -> some View {
        let rect = frame(.widget, scale: scale, dx: dx)
        if let line = model.reachLine {
            VStack(alignment: .leading, spacing: 0) {
                FitLine(forms: FitLine.cuts(line), size: 16, color: Theme.Colors.Accent.wine, weight: .medium)
                    .frame(height: 24, alignment: .leading)
                Button { model.allow() } label: {
                    Text("Allow")
                        .font(.custom("Figtree", size: 16, relativeTo: .body).weight(.bold))
                        .foregroundStyle(Theme.Colors.Accent.wine)
                        .frame(minWidth: 88, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("chart.allow")
                .accessibilityHint("Lets this room \(line.replacingOccurrences(of: "This room can now ", with: ""))")
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(width: rect.width, alignment: .leading)
            .offset(x: rect.minX, y: rect.minY + 128 * scale)
        } else if !model.heard.isEmpty {
            Text("\u{201C}\(PartText.shown(model.heard))\u{201D}")
                .font(.custom("Newsreader", size: 20, relativeTo: .body).italic())
                .foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .frame(width: rect.width - 12, alignment: .leading)
                .offset(x: rect.minX + 12, y: rect.minY + 28 * scale)
                .allowsHitTesting(false)
                .accessibilityIdentifier("chart.heard")
        }
    }
}

/// One empty place: a dashed outline in ink 3 with its name at the top left (11 pt, ink 2). The outline never carries
/// a fill, and the name hides once a ghost fills the place so nothing overlaps.
private struct Outline: View {
    let name: String
    let showsName: Bool
    var drawn: Double = 1

    var body: some View {
        UnrollShape()
            .trim(from: 0, to: drawn)
            .stroke(Theme.Colors.inkTertiary.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .overlay(alignment: .topLeading) {
                Text(name)
                    .font(.custom("Figtree", size: 11, relativeTo: .caption2).weight(.medium))
                    .foregroundStyle(Theme.Colors.inkSecondary.opacity(0.7))
                    .lineLimit(1)
                    .padding(.leading, 8)
                    .padding(.top, 5)
                    .opacity(showsName ? 1 : 0)
                    .tesseraAnimation(.easeOut(duration: 0.4), value: showsName)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(name), empty")
    }
}

/// The 1 pt drying line in the room colour along the foot of a filled place: 2 s, linear, left to right. Reduce
/// Motion draws it whole (the 2 s wait still applies).
private struct DryingLine: View {
    let reduceMotion: Bool
    @State private var drawn = false

    var body: some View {
        Rectangle()
            .fill(Theme.Colors.Accent.chart)
            .scaleEffect(x: reduceMotion || drawn ? 1 : 0.001, y: 1, anchor: .leading)
            .onAppear {
                guard !reduceMotion else { return }
                withTesseraAnimation(.linear(duration: PartGhost.drying), reduceMotion: false) { drawn = true }
            }
            .accessibilityHidden(true)
    }
}
