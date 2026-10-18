import SwiftUI
import UIKit

/// A title that carries the progress of its thing (Design 72, round 2, title-accent.md): the whole title grows
/// bolder (500 → 640) and leans toward its area's colour (0 → 60%) as the thing gets done, the word that matters
/// wears the colour (72% mix) from the first step, and at done every effect joins under a 3 pt strike drawn left
/// to right, with one lift; 900 ms later it dries over 2 s to quiet ink at 50%, the strike kept.
struct TitleAccent: Equatable {
    /// 0…1 of the thing's own count (sets, steps, tasks). Held under 0.85 until done so the last step still moves.
    var progress: Double
    var isDone = false
    /// The area's colour; nil for Today's tasks, which stay ink (cobalt is Tess's voice only) with the word at 700.
    var tint: Color?
    /// Arrived already done (a page opened later): drawn dried, nothing plays.
    var isSettled = false

    static let progressCap = 0.85

    var shownProgress: Double {
        isDone ? 1 : min(max(progress, 0), Self.progressCap)
    }

    /// "Push Day A, bench set 2" → "bench set 2": the moment after the comma (sheet 72, decisions 3:05).
    static func keyWord(in title: String) -> Range<String.Index>? {
        guard let comma = title.firstIndex(of: ",") else {
            // A masked title ("Private workout", "Private recipe", "Private item") leads with what it is, not with
            // "Private" (Design low on #895). Case-sensitive, so a real title like "Private lessons" keys on
            // "lessons": harmless.
            let lead = "Private "
            guard title.hasPrefix(lead), title.count > lead.count else { return nil }
            return title.index(title.startIndex, offsetBy: lead.count) ..< title.endIndex
        }
        var start = title.index(after: comma)
        while start < title.endIndex, title[start] == " " {
            start = title.index(after: start)
        }
        return start < title.endIndex ? start ..< title.endIndex : nil
    }
}

/// The title itself. `spec` is the role's type (Hero 56 or Title 44); the weight runs on the face's own axis.
struct AccentTitle: View {
    let text: String
    let accent: TitleAccent
    let spec: ThemeConcept.TypeSpec
    var lineLimit: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strike: Double = 0
    @State private var dry: Double = 0
    @State private var lift = false
    @State private var finishing: Task<Void, Never>?

    var body: some View {
        AccentFace(text: text, spec: spec, tint: accent.tint, progress: accent.shownProgress, dry: dry)
            .lineLimit(lineLimit)
            .textRenderer(TitleStrikeRenderer(progress: strike, color: Theme.Colors.ink))
            .scaleEffect(lift ? 1.02 : 1, anchor: .leading)
            .opacity(1 - 0.5 * dry)
            .tesseraAnimation(.timingCurve(0.3, 0, 0.2, 1, duration: 0.6), value: accent.shownProgress)
            .onChange(of: accent.isDone, initial: true) { _, isDone in
                guard isDone else {
                    // Undoing a finish: the sleeping steps of the finish must not run on.
                    finishing?.cancel()
                    finishing = nil
                    lift = false
                    strike = 0
                    dry = 0
                    return
                }
                // Arrived already done (or Reduce Motion): drawn dried, the strike whole.
                if accent.isSettled || reduceMotion {
                    withTesseraAnimation(.easeInOut(duration: 0.15), reduceMotion: reduceMotion) {
                        strike = 1
                        dry = 1
                    }
                    return
                }
                finish()
            }
            .onDisappear {
                finishing?.cancel()
                finishing = nil
            }
            .accessibilityLabel(text)
            .accessibilityValue(accent.isDone && !text.lowercased().hasSuffix("done") ? "done" : "")
    }

    /// Strike (420 ms, ease-out), one 250 ms lift, then 900 ms later the 2 s dry.
    private func finish() {
        let still = reduceMotion
        withTesseraAnimation(.easeOut(duration: 0.42), reduceMotion: still) { strike = 1 }
        finishing?.cancel()
        finishing = Task { @MainActor in
            // Each step checks it is still wanted: an undone finish or a left page cancels the task.
            func step(_ milliseconds: Int) async -> Bool {
                try? await Task.sleep(for: .milliseconds(milliseconds))
                return !Task.isCancelled
            }
            guard await step(420) else { return }
            withTesseraAnimation(.easeOut(duration: 0.125), reduceMotion: still) { lift = true }
            guard await step(125) else { return }
            withTesseraAnimation(.easeIn(duration: 0.125), reduceMotion: still) { lift = false }
            guard await step(900) else { return }
            withTesseraAnimation(.easeInOut(duration: 2), reduceMotion: still) { dry = 1 }
        }
    }
}

/// The animatable part: weight, tracking and colour from `progress`, drying back with `dry`.
private struct AccentFace: View, Animatable {
    let text: String
    let spec: ThemeConcept.TypeSpec
    let tint: Color?
    var progress: Double
    var dry: Double

    nonisolated var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, dry) }
        set {
            progress = newValue.first
            dry = newValue.second
        }
    }

    var body: some View {
        let live = progress * (1 - dry)
        let weight = 500 + 140 * live
        let ink = Theme.Colors.ink
        let lean = tint.map { ink.mix(with: $0, by: 0.6 * live) } ?? ink
        Text(attributed(ink: ink))
            .font(AccentFont.font(spec, weight: weight))
            .tracking((spec.tracking - 0.012 * live) * spec.size)
            .lineHeight(.multiple(factor: spec.lineHeight))
            .foregroundStyle(lean)
    }

    private func attributed(ink: Color) -> AttributedString {
        var string = AttributedString(text)
        guard let key = TitleAccent.keyWord(in: text),
              let lower = AttributedString.Index(key.lowerBound, within: string),
              let upper = AttributedString.Index(key.upperBound, within: string) else { return string }
        let word = (1 - dry)
        if let tint {
            string[lower ..< upper].foregroundColor = ink.mix(with: tint, by: 0.72 * word)
        } else {
            // Today's tasks: the word is ink at 700, no colour.
            string[lower ..< upper].font = AccentFont.font(spec, weight: 500 + 200 * word)
        }
        return string
    }
}

/// The display face at any weight on its variable axis, scaled like the role it stands in for.
enum AccentFont {
    private static let weightAxis = 0x7767_6874 // 'wght'

    static func font(_ spec: ThemeConcept.TypeSpec, weight: Double) -> Font {
        let family = Theme.concept.fonts.display
        let size = UIFontMetrics(forTextStyle: spec.textStyle.uiKit).scaledValue(for: spec.size)
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [weightAxis: weight],
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        guard font.familyName == family else {
            return Font.system(size: size, weight: weight >= 600 ? .semibold : .medium)
        }
        return Font(font as CTFont)
    }
}

/// Draws the text, then a 3 pt strike through the x-height of each line in reading order, `progress` of the way.
struct TitleStrikeRenderer: TextRenderer, Animatable {
    var progress: Double
    var color: Color

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }
        guard progress > 0 else { return }
        let widths = layout.map(\.typographicBounds.rect.width)
        var left = widths.reduce(0, +) * progress
        for (line, width) in zip(layout, widths) where left > 0 {
            let bounds = line.typographicBounds
            let run = min(left, width)
            left -= run
            // Through the x-height: about half of the lowercase height above the baseline.
            let y = bounds.origin.y - bounds.ascent * 0.32
            context.fill(Path(roundedRect: CGRect(x: bounds.rect.minX, y: y - 1.5, width: run, height: 3),
                              cornerRadius: 1.5), with: .color(color))
        }
    }
}
