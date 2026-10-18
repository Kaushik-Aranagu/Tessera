import SwiftUI
import TesseraCore
import TesseraTess

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
    /// The key line's filter: it cuts a key out and keeps the line up across the cut's own change (QA on #767).
    @State private var keys = PasteKeyFilter()
    @FocusState private var editing: Bool
    /// Tess's line while a pasted link is read, and what reading it gave (G54, K87.4). Never the link itself.
    @State private var linkLine: String?
    @State private var readingLink = false
    /// The next change to the box is the link reader's, not his, so its line stays up.
    @State private var fromLink = false
    /// The shelf's links, read when the page shows and after each read.
    @State private var waitingLinks: [URL] = []

    /// The saved line's name: a private recipe is only "Private recipe" here too, spoken or drawn (G53).
    private var savedTitle: String {
        guard let title = saved.flatMap({ model.store.object(id: $0.id)?.title }) else { return "Recipe" }
        return RecipeCopy.shownTitle(title, isPrivate: RecipeCopy.isPrivate(title, model: model))
    }

    var body: some View {
        let lines = CreateRecipe.lines(of: text, corrections: corrections)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(refusedKey ? claudeKeyLine
                    : linkLine ?? PasteCopy.idleLine(link: RecipePasteLink.bareLink(text) != nil, reading: reading,
                                                     read: revealed >= lines.count, lines: lines))
                    .font(Theme.voice)
                    // The password refusal reads in ink (Design on #810).
                    // A refusal (a password link, a recipe already saved) reads in ink, not Tess's cobalt (Design).
                    .foregroundStyle(linkLine.map(PasteCopy.isRefusal) == true ? Theme.Colors.ink : Theme.Colors.tess)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(0)

                // Links kept for later (K86.7): read only on his tap, oldest first, never by themselves.
                if !reading, text.isEmpty, !readingLink, let waiting = waitingLinks.first {
                    Button(PasteCopy.readWaiting(waitingLinks.count)) {
                        // The reader's own fill: its "Reading <host>." line stays up (QA on #830).
                        fromLink = true
                        text = waiting.absoluteString
                        readLink(waiting)
                    }
                    .buttonStyle(.labelWord)
                    .padding(.top, Theme.Spacing.m)
                    .accessibilityHint("Reads the oldest link kept for later")
                    .entrance(1)
                }

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
                        .textRole(.field)
                        .foregroundStyle(Theme.Colors.ink)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .focused($editing)
                        .keyboardDoneWord { editing = false }
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
                    canSave: PasteCopy.canSave(lines),
                    // A bare link: Read it, on his tap only (K86.7); never Save on a link.
                    readLink: RecipePasteLink.bareLink(text).map { link in { readLink(link) } },
                    readingLink: readingLink,
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
        .onDisappear(perform: closeUndo)
        .onAppear { waitingLinks = RecipeLinkShelf.beside(model.store)?.waiting() ?? [] }
        .onChange(of: readingLink) { _, isReading in
            if !isReading {
                waitingLinks = RecipeLinkShelf.beside(model.store)?.waiting() ?? []
            }
        }
        .onChange(of: text) { old, new in
            // A link with a name or password in it is refused whole: never read, kept, saved or printed back (#810).
            // The same inside a longer paste: a recipe holding one is never painted or saveable (Kitchen on #821).
            if RecipePasteLink.isSecretLink(new) || PasteCopy.hasSecretLink(new) {
                linkLine = RecipeLinkLine.secretLink
                reading = false
                fromLink = false
                text = ""
                return
            }
            // His own change retires the last link line, so a refusal or "kept for later" never goes stale.
            if fromLink {
                fromLink = false
            } else if !new.isEmpty, new != old {
                linkLine = nil
            }
            // A Claude key never becomes a recipe (QA on #218): cut it out before anything reads it, keeping the rest
            // of the paste (Product 8:20 AM, K87.11). It's never echoed; the line says where a key goes.
            switch keys.change(old: old, new: new) {
            case let .cut(kept):
                refusedKey = true
                text = kept
            case let .keptAfterCut(read: shouldRead):
                refusedKey = true
                if shouldRead {
                    read()
                }
            case let .plain(read: shouldRead):
                if !new.isEmpty {
                    refusedKey = false
                }
                // A paste lands as one big change: read it straight away.
                if shouldRead {
                    read()
                }
            }
        }
        .onChange(of: editing) { _, isEditing in
            if !isEditing, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                read()
            }
        }
        .tesseraFeedback(.made, trigger: saved?.id)
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

    /// Reads the pasted link once. Read: the recipe's text lands in the box and the brush paints it, with the
    /// reader's line. Offline: "Recipe link, kept for later." and the box clears, the link on the shelf. Claude (L3)
    /// only while "Tess asks Claude" is on (G32).
    private func readLink(_ link: URL) {
        guard !readingLink else { return }
        readingLink = true
        linkLine = RecipeLinkLine.reading(link.host() ?? "the page")
        let store = model.store
        var claude = ClaudeRecipeReader(keys: SystemKeychain(), ledger: TessUsageLedger(store: store,
                                                                                        classes: model.classes))
        { [model] in model.asksClaude }
        claude.lastWeightKg = { BodyWeight.lastKg(in: store) }
        let reader = RecipeLinkReader(claude: claude)
        Task { @MainActor in
            let outcome = await RecipePasteLink.read(link, reader: reader, asksClaude: model.asksClaude,
                                                     shelf: RecipeLinkShelf.beside(store))
            readingLink = false
            // He changed the box while it read: his edit wins; the result is dropped (QA on #811).
            guard RecipePasteLink.bareLink(text) == link else {
                linkLine = nil
                return
            }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                linkLine = outcome.line
                if let recipe = outcome.result.text {
                    // Painted like a paste: the box takes the recipe's text and the brush reads it.
                    reading = false
                    corrections = [:]
                    // Only a real change fires onChange; an unchanged box would leave the flag set.
                    fromLink = recipe != text
                    text = recipe
                } else if outcome.kept {
                    reading = false
                    text = ""
                }
            }
        }
    }

    private func edit() {
        linkLine = nil
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
        let outcome = PasteCopy.save(text, corrections: corrections, engine: model.engine, store: model.store,
                                     classes: model.classes, missLog: CaptureMissLog.beside(model.store))
        let result: (output: ObjectRecord, record: OpRecord)
        switch outcome {
        case let .saved(recipe, record):
            result = (recipe, record)
        case let .duplicate(line):
            // Information, not a failure: ink, no haptic, his text kept (Product and Design 12:45).
            linkLine = line
            return
        case .failed:
            // Never silence: the text stays to fix or retry (G54, ruled Oct 17, 4:35).
            TessVoice.shared.say(PasteCopy.didntSave)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            saved = (result.output.id, result.record)
            model.touch()
        }
        let id = result.output.id
        Task { @MainActor in
            // The receipt's UNDO holds 4 s (10 s under VoiceOver) before the page moves on (K87.2).
            try? await Task.sleep(for: TessVoice.hold(undo: true, holds: .seconds(4)))
            if saved?.id == id {
                // The receipt stays through the push; onDisappear closes the UNDO once the page is covered.
                onSaved(id)
            }
        }
    }

    /// Leaving Paste closes the UNDO window: back from the recipe finds a fresh page, never a live UNDO (G52c).
    private func closeUndo() {
        guard saved != nil else { return }
        saved = nil
        text = ""
        reading = false
        revealed = 0
        corrections = [:]
    }

    private func undo(_ record: OpRecord) {
        model.engine.undo(record)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            saved = nil
            model.touch()
        }
    }
}

/// Pinned at the bottom: Save (tap), or once saved "Carbonara, on Recipes." with Undo.
private struct SaveBar: View {
    let saved: Bool
    /// Nothing read (no ingredient, no step; a bare link, say): Save isn't drawn, so no tap ends in silence (G54).
    let canSave: Bool
    var readLink: (() -> Void)?
    var readingLink = false
    let title: String
    let onSave: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void

    var body: some View {
        if saved {
            HStack(alignment: .firstTextBaseline) {
                Text(RecipeCopy.saved(title))
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                Spacer()
                Button("Undo", action: onUndo)
                    .buttonStyle(InkLabelWordStyle.undo)
                    .frame(minHeight: 44)
            }
        } else {
            HStack(spacing: Theme.Spacing.l) {
                if canSave {
                    PaintKey(paint: Theme.Colors.health, isTap: true, action: onSave) { _ in
                        Text("Save recipe")
                    }
                } else if let readLink {
                    PaintKey(paint: Theme.Colors.ink, isTap: true, action: readLink) { _ in
                        Text(readingLink ? "Reading" : "Read it")
                    }
                    .disabled(readingLink)
                    .accessibilityHint("Reads the recipe from the page")
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

/// The Paste box's key check, as a small state machine so it tests without a screen. A key-shaped change is cut
/// (`.cut`); the box then changes again to the cut text, and that change keeps the key line up and reads what was
/// kept (`.keptAfterCut`) instead of clearing the line as an ordinary edit would.
struct PasteKeyFilter {
    private var lastCut: String?

    enum Action: Equatable {
        case cut(String)
        case keptAfterCut(read: Bool)
        case plain(read: Bool)
    }

    mutating func change(old: String, new: String) -> Action {
        if looksLikeClaudeKey(new) {
            let kept = PasteCopy.withoutKeys(new)
            lastCut = kept
            return .cut(kept)
        }
        if let cut = lastCut, new == cut {
            lastCut = nil
            return .keptAfterCut(read: !new.isEmpty)
        }
        lastCut = nil
        return .plain(read: new.count - old.count > 40)
    }
}

enum PasteCopy {
    /// What Save came to.
    enum SaveOutcome {
        case saved(ObjectRecord, OpRecord)
        /// Already on Recipes: "<title> is already on Recipes." ("Private recipe" when walled). Nothing is written or
        /// logged.
        case duplicate(String)
        case failed
    }

    /// Save, out of the view so it tests. The same paste twice is one recipe (G59, #854): it says which and logs
    /// nothing, so a private duplicate (a medicine title, say) never reaches the miss log. Any other refusal logs the
    /// paste for week one, unless it holds a secret word, money, a body fact or a password link.
    @MainActor
    static func save(_ text: String, corrections: [Int: String], engine: ActionEngine, store: ObjectStore,
                     classes: [SystemCatalog.Key: ClassDef], missLog: CaptureMissLog?) -> SaveOutcome
    {
        if let line = duplicateLine(text, store: store, classes: classes) {
            return .duplicate(line)
        }
        do {
            let done = try engine.perform(
                CreateRecipe(text: text, corrections: corrections.isEmpty ? nil : corrections), by: .user
            )
            return .saved(done.output, done.record)
        } catch let ActionError.invalidArguments(_, reason) where isDuplicate(reason) {
            // The engine's own refusal, if the check above missed (corrections): the same line, nothing logged.
            return .duplicate(reason)
        } catch {
            // Nothing written (a link, say): kept on the phone for week one, never in the op log.
            // Never a pasted line with a secret word in it (Research 134; QA F3 on #422), money or a body fact
            // (board 0ah), or a link that carries a name or password (QA on #810).
            if !SecretWords.mentions(text), !hasSecretLink(text),
               !PrivateFacts.isWalled(text, lastWeightKg: BodyWeight.lastKg(in: store))
            {
                missLog?.record(text, at: AppClock.now, route: "none", source: "paste")
            }
            return .failed
        }
    }

    /// The engine's duplicate refusal: "<title> is already on Recipes." ("Private recipe" for a walled one).
    static func isDuplicate(_ line: String) -> Bool {
        line.hasSuffix(alreadyOnRecipes)
    }

    /// The duplicate line's tail, one constant for building and reading it (QA on #865); Core's #854 says the same.
    static let alreadyOnRecipes = " is already on Recipes."

    /// "Weeknight dal is already on Recipes." / "Private recipe is already on Recipes."
    static func duplicate(_ name: String) -> String {
        name + alreadyOnRecipes
    }

    /// Whether Tess's line on Paste is a refusal, drawn in ink.
    static func isRefusal(_ line: String) -> Bool {
        line == RecipeLinkLine.secretLink || isDuplicate(line)
    }

    /// Before Save writes: if this paste is already a saved recipe, the line naming it, masked when the title is
    /// walled. Nil when it's new.
    @MainActor
    static func duplicateLine(_ text: String, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> String? {
        guard let existing = RecipeBook(store: store, classes: classes).recipe(pastedAs: text) else { return nil }
        let walled = store.value("isPrivate", of: existing) == .bool(true)
            || ObjectPrivacy.isPrivateRecipeTitle(existing.title, lastWeightKg: BodyWeight.lastKg(in: store))
        return duplicate(walled ? ObjectPrivacy.recipeLabel : existing.title)
    }

    /// "Read 1 waiting" / "Read 3 waiting": the links kept for later.
    static func readWaiting(_ count: Int) -> String {
        "Read \(count) waiting"
    }

    /// Whether any word of the paste is a link with a user or password before its host.
    static func hasSecretLink(_ text: String) -> Bool {
        // Brackets, quotes and sentence marks around a link don't hide it: "(https://u:p@host)." (QA on #821).
        let wrapping = CharacterSet(charactersIn: "()[]{}<>\"'“”‘’.,;:!?")
        // Only link-shaped words are checked, as the bare-link rule reads them: an email (chef@bakery.com), an @handle
        // or "4 @ 350" is a recipe's ordinary text, never a password link (QA on #830).
        return text.split(whereSeparator: \.isWhitespace).contains { word in
            let trimmed = String(word).trimmingCharacters(in: wrapping)
            let lower = trimmed.lowercased()
            guard lower.hasPrefix("https://") || lower.hasPrefix("http://") || lower.hasPrefix("www.") else {
                return false
            }
            return RecipeLinkReader.hasCredentials(trimmed)
        }
    }

    /// Tess's line when no link line is up: the count once the brush has read, the link nudge for a bare link (a
    /// proposal; the read lines themselves are Core's), else the invitation.
    static func idleLine(link: Bool, reading: Bool, read: Bool,
                         lines: [(line: String, kind: RecipeParser.LineKind)]) -> String
    {
        if link {
            return "A link. Tap Read it and I'll read the page."
        }
        return reading && read ? tess(lines) : "Paste a recipe and I'll read it."
    }

    static let didntSave = "Didn't save that. Try again."

    /// Save is drawn only when the parser found something to keep: an ingredient or a step (G54).
    static func canSave(_ lines: [(line: String, kind: RecipeParser.LineKind)]) -> Bool {
        lines.contains { line in
            switch line.kind {
            case .ingredient, .step: true
            default: false
            }
        }
    }

    /// The paste with every Claude key taken out and the rest kept (K87.11), through Core's cutter, which also takes
    /// a key's tail when a paste wraps it; anything still key-shaped leaves nothing (QA on #767).
    static func withoutKeys(_ text: String) -> String {
        let kept = withoutClaudeKeys(text)
        return looksLikeClaudeKey(kept) ? "" : kept
    }

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
