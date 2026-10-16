import SwiftUI
import TesseraCore

/// Paste a recipe (kitchen screen 11). The raw text stays exactly where it lands, in body type, and the parser
/// paints over it as it reads, top to bottom like a brush passing: amounts get a cadmium under-stroke, ingredient
/// names a sage dab, durations turn cadmium, and each step gets a numeral and a hairline in the margin. A misread is
/// fixed by tapping the line to cycle it (ingredient, step, ignore), never by a form. Tess says what she read, in
/// cobalt. Save commits it with an Undo.
struct PasteRecipe: View {
    var onSaved: (UUID) -> Void = { _ in }

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var text = ""
    @State private var reading = false
    @State private var revealed = 0
    /// The brush band's position down the column, 0 … 1.
    @State private var band: CGFloat = -0.2
    @State private var corrections: [Int: String] = [:]
    @State private var saved: (id: UUID, record: OpRecord)?
    /// A Claude key pasted here by mistake: refused on the spot, never read, saved or shown.
    @State private var refusedKey = false
    @FocusState private var editing: Bool

    private var savedTitle: String {
        saved.flatMap { model.store.object(id: $0.id)?.title } ?? "Recipe"
    }

    var body: some View {
        let lines = CreateRecipe.lines(of: text, corrections: corrections)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(refusedKey ? "That looks like a Claude key. It goes in Settings, not a recipe."
                    : reading && revealed >= lines.count ? PasteCopy.tess(lines) : "Paste a recipe and I'll read it.")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(0)

                if reading {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            PaintedLine(line: line.line, kind: line.kind, step: stepNumber(at: index, in: lines),
                                        painted: index < revealed)
                            {
                                cycle(index, current: line.kind)
                            }
                        }
                    }
                    .overlay {
                        // The brush passing: a soft cadmium band moves down over the text as it's read.
                        GeometryReader { proxy in
                            LinearGradient(colors: [Theme.Colors.now.opacity(0), Theme.Colors.now,
                                                    Theme.Colors.now.opacity(0)],
                                           startPoint: .top, endPoint: .bottom)
                                .frame(height: 80)
                                .offset(y: band * proxy.size.height - 40)
                                .blendMode(Theme.Colors.soulBlend)
                                .opacity(reduceMotion || band >= 1 ? 0 : 0.25)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.top, Theme.Spacing.xl)
                    .transition(.opacity)
                } else {
                    TextEditor(text: $text)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .focused($editing)
                        .frame(minHeight: 320, alignment: .topLeading)
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.horizontal, -5)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Ingredients, then the method. Any shape is fine.")
                                    .textRole(.body)
                                    .foregroundStyle(Theme.Colors.inkSecondary)
                                    .padding(.top, Theme.Spacing.xl + 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityLabel("Recipe text")
                        .entrance(1)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            // Room for the pinned Save bar, so the last step never sits under it.
            .padding(.bottom, reading ? 110 : Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .safeAreaInset(edge: .bottom) {
            if reading {
                SaveBar(
                    saved: saved != nil,
                    title: savedTitle,
                    onSave: save,
                    onUndo: {
                        if let saved {
                            undo(saved.record)
                        }
                    },
                    onEdit: edit
                )
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.vertical, Theme.Spacing.m)
                .background { ThemedBackground().opacity(0.92) }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: text) { old, new in
            // A Claude key never becomes a recipe (QA on #218): clear it before anything reads it.
            if looksLikeClaudeKey(new) {
                text = ""
                refusedKey = true
                return
            }
            if !new.isEmpty {
                refusedKey = false
            }
            // A paste lands as one big change: read it straight away.
            if new.count - old.count > 40 {
                read()
            }
        }
        .onChange(of: editing) { _, isEditing in
            if !isEditing, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                read()
            }
        }
        .sensoryFeedback(.success, trigger: saved?.id)
        #if DEBUG
            // `-pasteDemo`: lands a recipe as if pasted, for recordings.
            .task {
                guard LaunchFlags.has("-pasteDemo"), text.isEmpty else { return }
                try? await Task.sleep(for: .seconds(1.2))
                text = KitchenDemo.dal
            }
        #endif
    }

    private func stepNumber(at index: Int, in lines: [(line: String, kind: RecipeParser.LineKind)]) -> Int? {
        guard case .step = lines[index].kind else { return nil }
        return lines[...index].count {
            if case .step = $0.kind {
                true
            } else {
                false
            }
        }
    }

    /// The brush pass: lines paint in one after another over about 600 ms.
    private func read() {
        // A paste fires both the big-change and the focus-loss reads; the brush passes once.
        guard !reading else { return }
        editing = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { reading = true }
        let count = CreateRecipe.lines(of: text, corrections: corrections).count
        guard !reduceMotion else {
            revealed = count
            return
        }
        revealed = 0
        band = -0.2
        withAnimation(.smooth(duration: min(0.9, max(0.6, Double(count) * 0.03)))) { band = 1.2 }
        Task { @MainActor in
            let step = max(0.012, min(0.9, max(0.6, Double(count) * 0.03)) / Double(max(count, 1)))
            for index in 1 ... max(count, 1) {
                try? await Task.sleep(for: .seconds(step))
                withAnimation(.smooth(duration: 0.28)) { revealed = index }
            }
        }
    }

    private func edit() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            reading = false
            corrections = [:]
        }
        editing = true
    }

    /// Tap a line to read it differently: ingredient → step → ignore → ingredient.
    /// Ingredient → step → ignore → ingredient, from what the line was last marked (or read) as, so a line that
    /// won't read as an ingredient still moves on to step. Titles, headings and details aren't cycled.
    private func cycle(_ index: Int, current: RecipeParser.LineKind) {
        guard let next = PasteCopy.nextReading(after: corrections[index], current: current) else { return }
        // Instant: the line repaints in place (a crossfade would draw both readings over each other).
        corrections[index] = next
    }

    private func save() {
        guard let result = try? model.engine.perform(
            CreateRecipe(text: text, corrections: corrections.isEmpty ? nil : corrections), by: .user
        ) else {
            // Nothing written (a link, say): kept on the phone for week one, never in the op log.
            CaptureMissLog.beside(model.store)?.record(text, at: AppClock.now, route: "none", source: "paste")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            saved = (result.output.id, result.record)
            model.touch()
        }
        let id = result.output.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if saved?.id == id {
                onSaved(id)
            }
        }
    }

    private func undo(_ record: OpRecord) {
        model.engine.undo(record)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            saved = nil
            model.touch()
        }
    }
}

/// Pinned at the bottom: Save (tap), or once saved "Carbonara saved." with Undo.
private struct SaveBar: View {
    let saved: Bool
    let title: String
    let onSave: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void

    var body: some View {
        if saved {
            HStack(alignment: .firstTextBaseline) {
                Text("\(title) saved.")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                Spacer()
                Button("Undo", action: onUndo)
                    .buttonStyle(InkLabelWordStyle.undo)
                    .frame(minHeight: 44)
            }
        } else {
            HStack(spacing: Theme.Spacing.l) {
                PaintKey(paint: Theme.Colors.health, isTap: true, action: onSave) { _ in
                    Text("Save recipe")
                }
                Button("Edit", action: onEdit)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .buttonStyle(HandleButtonStyle())
                    .frame(minHeight: 44)
            }
        }
    }
}

/// One line as written, with the parser's paint over it.
private struct PaintedLine: View {
    let line: String
    let kind: RecipeParser.LineKind
    let step: Int?
    let painted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                // The margin: a numeral and a hairline for each step.
                ZStack(alignment: .topLeading) {
                    if let step {
                        Text("\(step)")
                            .font(Theme.voice(size: 18))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .opacity(painted ? 1 : 0)
                    }
                }
                .frame(width: 22, alignment: .leading)
                .overlay(alignment: .trailing) {
                    if step != nil {
                        Rectangle()
                            .fill(Theme.Colors.hairline)
                            .frame(width: Theme.Stroke.hairline)
                            .opacity(painted ? 1 : 0)
                    }
                }
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // A re-read swaps the line in place; the old reading never fades over the new one.
                    .id(PasteCopy.kindName(kind))
                    .transition(.identity)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 32)
        }
        .buttonStyle(HandleButtonStyle())
        // A re-read repaints in place; never crossfade the two readings over each other.
        .accessibilityElement(children: .combine)
        .accessibilityValue(PasteCopy.kindName(kind))
        .accessibilityHint("Tap to read it as something else")
    }

    @ViewBuilder private var content: some View {
        switch kind {
        case .title:
            Text(line)
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        case .heading:
            Text(line)
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
        case .meta:
            Text(line)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
        case let .ingredient(parsed):
            IngredientPaint(line: line, parsed: parsed, painted: painted)
        case .step:
            Text(PasteCopy.durationsInked(line, painted: painted))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        case .ignored:
            Text(line)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// "200 g flour": the amount gets a cadmium under-stroke, the name a sage dab just before it.
private struct IngredientPaint: View {
    let line: String
    let parsed: IngredientLine
    let painted: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let (amount, rest) = PasteCopy.split(line, name: parsed.name)
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if !amount.isEmpty {
                Text(amount)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .background(alignment: .bottom) {
                        Brushstroke(progress: painted ? 1 : 0)
                            .stroke(Theme.Colors.now.opacity(painted ? 0.35 : 1),
                                    style: StrokeStyle(lineWidth: HomeStroke.underAmount, lineCap: .round))
                            .tesseraAnimation(Theme.Motion.dry(reduceMotion: reduceMotion) ?? .default, value: painted)
                            .frame(height: 9)
                            .offset(y: 6)
                    }
            }
            PaintDab(color: Theme.Colors.health, size: CGSize(width: 10, height: 8), seed: line.count)
                .padding(.horizontal, Theme.Spacing.xs)
                .opacity(painted ? 1 : 0)
                .scaleEffect(painted ? 1 : 0.4)
            Text(rest)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum PasteCopy {
    /// Ingredient → step → ignore → ingredient, from what the line was last marked as (else how it read), so a line
    /// that won't read as an ingredient still moves on to step. Titles, headings and details aren't cycled.
    static func nextReading(after marked: String?, current: RecipeParser.LineKind) -> String? {
        let read = switch current {
        case .ingredient: "ingredient"
        case .step: "step"
        case .ignored: "ignore"
        case .title, .heading, .meta: ""
        }
        return ["ingredient": "step", "step": "ignore", "ignore": "ingredient"][marked ?? read]
    }

    /// "Eight ingredients, six steps, two timers."
    static func tess(_ lines: [(line: String, kind: RecipeParser.LineKind)]) -> String {
        var ingredients = 0, steps = 0, timers = 0
        for line in lines {
            switch line.kind {
            case .ingredient: ingredients += 1
            case let .step(_, found):
                steps += 1
                timers += found.count
            default: break
            }
        }
        guard ingredients > 0 else { return "I couldn't find ingredients. Tap a line to mark one." }
        func count(_ value: Int, _ one: String) -> String {
            "\(SpokenTime.number(value)) \(value == 1 ? one : one + "s")"
        }
        var parts = [count(ingredients, "ingredient"), count(steps, "step")]
        if timers > 0 {
            parts.append(count(timers, "timer"))
        }
        let sentence = parts.joined(separator: ", ")
        return sentence.prefix(1).uppercased() + sentence.dropFirst() + "."
    }

    static func kindName(_ kind: RecipeParser.LineKind) -> String {
        switch kind {
        case .title: "title"
        case .heading: "heading"
        case .meta: "detail"
        case .ingredient: "ingredient"
        case .step: "step"
        case .ignored: "ignored"
        }
    }

    /// The line split before the ingredient's name: ("200 g ", "flour, sifted").
    static func split(_ line: String, name: String) -> (String, String) {
        guard let range = line.range(of: name, options: .caseInsensitive), range.lowerBound > line.startIndex else {
            return ("", line)
        }
        return (String(line[..<range.lowerBound]), String(line[range.lowerBound...]))
    }

    /// Durations in a step turn cadmium once the brush has passed.
    static func durationsInked(_ line: String, painted: Bool) -> AttributedString {
        var text = AttributedString(line)
        guard painted else { return text }
        let pattern = /(?i)\d+(?:[.,]\d+)?(?:\s*(?:-|–|to)\s*\d+(?:[.,]\d+)?)?\s*(?:hours?|hrs?|minutes?|mins?|seconds?|secs?)\b/
        for match in line.matches(of: pattern) {
            if let range = Range(match.range, in: text) {
                text[range].foregroundColor = Theme.Colors.now
                text[range].font = Theme.Typography.font(Theme.concept.scale.body, weight: .semibold)
            }
        }
        return text
    }
}
