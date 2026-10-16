import SwiftUI
import TesseraCore

/// Tess at rest is only her soul in the bottom-right thumb corner: no bar, no band, no writing line. A tap opens
/// her capture surface (the soul swells, its three dabs rise into Speak · Write · Show over a wash with no top
/// edge, and the page recedes); a double tap goes Home from any depth. Write stretches the cobalt dab into a
/// writing line. Speak and Show are words only until their layers ship. Spec: `docs/design/no-buttons.md`.
struct BottomChrome: View {
    var onSoulDoubleTap: () -> Void = {}
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focused: Bool
    @State private var layer = Layer.modes
    @State private var swell = false
    @State private var pressed = false
    @State private var glow = false
    @State private var undos = 0
    private let voice = TessVoice.shared
    @State private var breathe = false
    @State private var opens = 0
    @State private var reply: String?
    @State private var replyCount = 0
    @State private var ghost: String?
    @State private var drying: CGFloat = 0
    @State private var dryTask: Task<Void, Never>?
    @State private var isBusy = false

    enum Layer { case modes, write }

    /// The three modes, top to bottom. Their dabs are the soul's three colours.
    fileprivate static let modes: [(word: String, seed: Int)] = [("Speak", 1), ("Write", 2), ("Show", 3)]
    fileprivate static let rowHeight: CGFloat = 70
    /// The soul's centre sits this far above the bottom of the chrome; the mode column starts above it.
    fileprivate static let soulLift: CGFloat = 54

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if model.isCommandExpanded {
                // The page recedes behind a veil of blurred ground (z); a tap on it closes Tess.
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Theme.Colors.paper.opacity(0.7)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close() }
                .accessibilityHidden(true)
                // The page comes back only after the words have gone, so they never overlap it.
                .transition(.asymmetric(insertion: .opacity,
                                        removal: .opacity.animation(.easeInOut(duration: 0.42).delay(0.12))))
                CaptureWash(dark: colorScheme == .dark)
                    .transition(.asymmetric(insertion: .offset(y: 60).combined(with: .opacity),
                                            removal: .offset(y: 40).combined(with: .opacity)))
                    .gesture(DragGesture(minimumDistance: 20).onEnded { value in
                        if value.translation.height > 40 {
                            close()
                        }
                    })
                surface
                    .transition(.asymmetric(insertion: .opacity,
                                            removal: .opacity.animation(.easeOut(duration: 0.16))))
            }
            resting
        }
        .onChange(of: model.isCommandExpanded) { _, expanded in
            if expanded {
                opened()
            } else {
                focused = false
                layer = .modes
                if !isBusy {
                    model.tessMode = restingOrIdle
                }
            }
        }
        .onAppear {
            model.tessMode = restingOrIdle
            breathe = !reduceMotion
            #if DEBUG
                if LaunchFlags.has("-tessScript") {
                    playScript()
                }
            #endif
        }
        .sensoryFeedback(.selection, trigger: opens)
        .sensoryFeedback(.success, trigger: glow) { _, lit in lit }
        .sensoryFeedback(.decrease, trigger: undos)
        // Core's overnight lines (the 04:00 roll, a workout wrapped up while away) show once, beside the soul
        // (late-night #13).
        .onChange(of: model.processNotes, initial: true) { _, notes in
            guard !notes.isEmpty else { return }
            voice.say(notes.joined(separator: " "))
            model.processNotes = []
        }
    }

    private var restingOrIdle: TessSoul.Mode {
        let hour = Calendar.current.component(.hour, from: AppClock.now)
        return hour >= 23 || hour < 6 ? .resting : .idle
    }

    // MARK: Rest

    /// One line per capture: Tess's reply wins; there are no generic fallbacks. UNDO stays while there's a capture.
    private var line: String? {
        reply ?? voice.note?.text ?? model.launchNote
    }

    /// UNDO only ever sits under the line whose record it reverts: a Home line ("Done. …", "Carried 2 tasks") shows
    /// it only when that line has its own op; a capture's line shows it for that capture.
    private var canUndo: Bool {
        if let note = voice.note {
            return note.undo != nil
        }
        return model.lastCapture != nil
    }

    /// Home's last action (done, moved) first, else the last capture.
    private func undo() {
        if let record = voice.note?.undo {
            _ = model.engine.undo(record)
            model.touch()
            undos += 1
            withTesseraAnimation(reduceMotion: reduceMotion) { voice.clear() }
        } else {
            model.undoLastCapture()
        }
    }

    private var resting: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            if !model.isCommandExpanded, line != nil || canUndo {
                VStack(alignment: .trailing, spacing: 2) {
                    if let line {
                        Text(line)
                            .frame(maxWidth: 270, alignment: .trailing)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.tess)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .contentTransition(.opacity)
                    }
                    if canUndo {
                        Button("Undo") { undo() }
                            .buttonStyle(InkLabelWordStyle.undo)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
                .shadow(color: Theme.Colors.paper.opacity(0.9), radius: 6)
                .transition(.offset(x: 12).combined(with: .opacity))
            }
            soulKey
        }
        .padding(.leading, Theme.Spacing.gutter)
        .padding(.trailing, 13)
        .padding(.bottom, 2)
        .tesseraAnimation(value: line)
        .tesseraAnimation(value: canUndo)
    }

    /// The soul at 0.72, breathing 1 ↔ 1.08 over 3.2 s; tap opens, hold opens, double tap goes Home.
    private var soulKey: some View {
        TessSoul(mode: model.tessMode)
            .scaleEffect(0.72)
            .scaleEffect(breathe ? 1.08 : 1)
            .tesseraAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: breathe)
            .scaleEffect(swell ? 1.35 : 1)
            .saturation(glow ? 1.35 : 1)
            .brightness(glow ? 0.08 : 0)
            .frame(width: 46, height: 40)
            .frame(width: 64, height: 64)
            .contentShape(Rectangle())
            .opacity(model.isCommandExpanded ? 0 : 1)
            // Feedback on touch-down, so the double-tap wait never reads as lag.
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    opens += 1
                    if !reduceMotion {
                        withAnimation(.easeOut(duration: 0.13)) { swell = true }
                    }
                }
                .onEnded { _ in
                    pressed = false
                    withAnimation(.easeInOut(duration: 0.13)) { swell = false }
                })
            .onTapGesture(count: 2) { onSoulDoubleTap() }
            .onTapGesture { model.isCommandExpanded ? close() : open() }
            .onLongPressGesture(minimumDuration: 0.4) { open() }
            .accessibilityElement()
            .accessibilityLabel("Tess")
            .accessibilityHint("Opens Tess.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Go home") { onSoulDoubleTap() }
    }

    // MARK: Open

    private var question: String {
        if model.session != nil {
            return "Tell me a set."
        }
        return model.path.isEmpty ? "What’s next?" : "Log it, ask, or note it."
    }

    /// At most two fast paths, the likeliest for this screen right now.
    private var fastPaths: [(String, () -> Void)] {
        var paths: [(String, () -> Void)] = []
        if let session = model.session {
            paths.append(("Back to \(session.workout.title)", { [model] in
                model.isCommandExpanded = false
                model.isWorkoutPresented = true
            }))
        } else if let workout = model.tonightWorkout() {
            paths.append(("Start \(workout.title)", { [model] in
                model.isCommandExpanded = false
                model.startWorkout(workout)
            }))
        }
        if !model.path.isEmpty {
            paths.append(("Today", { [onSoulDoubleTap] in onSoulDoubleTap() }))
        }
        return Array(paths.prefix(2))
    }

    private var surface: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: layer == .write ? .leading : .trailing, spacing: Theme.Spacing.s) {
                Text(question)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.tess)
                if layer == .modes, !fastPaths.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(Array(fastPaths.enumerated()), id: \.offset) { index, path in
                            if index > 0 {
                                Text(" · ").textRole(.body).foregroundStyle(Theme.Colors.ink.opacity(0.75))
                            }
                            Button(path.0, action: path.1)
                                .buttonStyle(ValueWordStyle())
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: layer == .write ? .leading : .trailing)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.bottom, Theme.Spacing.xl)

            if layer == .write {
                writing
                    .transition(.opacity)
            }
            ForEach(Array(Self.modes.enumerated()), id: \.offset) { index, mode in
                ModeRow(word: mode.word, seed: mode.seed, color: SoulColor.of(index),
                        rise: CGFloat(Self.modes.count - index) * Self.rowHeight - Self.rowHeight / 2 + Self.soulLift
                            - Self.rowHeight / 2,
                        delay: Double(Self.modes.count - 1 - index) * 0.04,
                        isActive: mode.word == "Write",
                        isFolded: layer == .write)
                {
                    if mode.word == "Write" {
                        withTesseraAnimation(reduceMotion: reduceMotion) { layer = .write }
                        focused = true
                    } else {
                        // Speak and Show are words until their layers ship.
                        close()
                        say("\(mode.word) comes next.")
                    }
                }
            }
            Color.clear.frame(height: Self.soulLift - Self.rowHeight / 2 + 32)
        }
        .tesseraAnimation(value: layer)
    }

    private var writing: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ZStack(alignment: .bottomLeading) {
                TextField("log 82.5×8, or ask", text: $model.commandDraft)
                    .font(Self.modeFont)
                    .foregroundStyle(Theme.Colors.ink.opacity(ghost == nil ? 1 : 0.45))
                    .tint(Theme.Colors.tess)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit(dry)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(ghost != nil)
                    .padding(.bottom, 8)
                    .onKeyPress(.escape) {
                        close()
                        return .handled
                    }
                    .onChange(of: model.commandDraft) { _, draft in
                        // A Claude key never stays in Ask: not on screen, not as a ghost, not as a task. Cleared the
                        // moment it lands, before any interpreter can see it.
                        if Self.looksLikeClaudeKey(draft) {
                            model.commandDraft = ""
                            refuseKey()
                            return
                        }
                        if !isBusy {
                            model.tessMode = draft.isEmpty ? .idle : .listening
                        }
                    }
                WritingLine(color: Theme.Colors.tess, reduceMotion: reduceMotion)
                if ghost != nil {
                    Rectangle()
                        .fill(Theme.Colors.tess)
                        .frame(height: 1.5)
                        .scaleEffect(x: drying, anchor: .leading)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { cancelDrying() }
            HStack(spacing: 0) {
                // At most two, and a tap only fills the line: nothing submits until Return.
                ForEach(Array(["log bench 82.5x8", "bench best?"].enumerated()),
                        id: \.offset)
                { index, suggestion in
                    if index > 0 {
                        Text(" · ").textRole(.body).foregroundStyle(Theme.Colors.ink.opacity(0.6))
                    }
                    Button(suggestion) {
                        model.commandDraft = suggestion
                        focused = true
                    }
                    .buttonStyle(ValueWordStyle(weight: .regular, opacity: 0.6))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.xl)
    }

    fileprivate static var modeFont: Font {
        var spec = Theme.concept.scale.title
        spec.size = 34
        return Theme.Typography.font(spec, weight: .medium)
    }

    #if DEBUG
        /// `-tessScript`: plays open → Write → type → Return so the flow can be recorded without touch automation.
        private func playScript() {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                open()
                try? await Task.sleep(for: .seconds(1.6))
                withTesseraAnimation(reduceMotion: reduceMotion) { layer = .write }
                focused = true
                try? await Task.sleep(for: .seconds(1.2))
                for character in "stretch at 21:30" {
                    model.commandDraft.append(character)
                    try? await Task.sleep(for: .milliseconds(90))
                }
                try? await Task.sleep(for: .seconds(0.8))
                dry()
            }
        }
    #endif

    // MARK: Actions

    private func open() {
        if model.launchNote != nil {
            TesseraSchema.clearLaunchNote()
        }
        model.launchNote = nil
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.isCommandExpanded = true }
    }

    /// Runs on every open, including when another screen opens Tess with a draft ("log bench ").
    private func opened() {
        reply = nil
        model.tessMode = .listening
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.13)) { swell = true }
            withAnimation(.easeInOut(duration: 0.13).delay(0.13)) { swell = false }
        }
        if !model.commandDraft.isEmpty {
            layer = .write
            focused = true
        }
    }

    private func close() {
        cancelDrying()
        withTesseraAnimation(.spring(response: 0.42, dampingFraction: 0.9), reduceMotion: reduceMotion) {
            model.isCommandExpanded = false
        }
    }

    /// Return: the text dims to a ghost and a cobalt line dries under it for 2 s (touching cancels), then it commits.
    /// Core's shared guard (any "sk-ant-", any case).
    static func looksLikeClaudeKey(_ text: String) -> Bool {
        TesseraCore.looksLikeClaudeKey(text)
    }

    private func refuseKey() {
        ghost = nil
        dryTask?.cancel()
        close()
        say("That looks like a Claude key. It goes in Review, under Claude.")
    }

    private func dry() {
        let text = model.commandDraft
        guard !Self.looksLikeClaudeKey(text) else {
            model.commandDraft = ""
            refuseKey()
            return
        }
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !isBusy, ghost == nil else { return }
        ghost = text
        drying = 0
        model.tessMode = .thinking
        withAnimation(reduceMotion ? .linear(duration: 0.01) : .linear(duration: 2)) { drying = 1 }
        dryTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 2))
            guard !Task.isCancelled else { return }
            await commit(text)
        }
    }

    private func cancelDrying() {
        guard ghost != nil, !isBusy else { return }
        dryTask?.cancel()
        dryTask = nil
        ghost = nil
        drying = 0
        model.tessMode = .listening
        focused = true
    }

    /// The same grammar path as before: questions about records are answered here; everything else is a capture
    /// through Tess's engine (grammar first, the on-device model when Apple Intelligence is available).
    private func commit(_ text: String) async {
        // Belt and braces: nothing that looks like a key reaches an interpreter or the log.
        guard !Self.looksLikeClaudeKey(text) else {
            refuseKey()
            return
        }
        isBusy = true
        let lowered = text.lowercased()
        let isQuestion = lowered.contains("best") || lowered.contains(/\bprs?\b/) || lowered.hasSuffix("?")
        let answer = isQuestion ? CommandInterpreter(model: model).run(text) : await model.ask(text)
        ghost = nil
        drying = 0
        model.commandDraft = ""
        withTesseraAnimation(.spring(response: 0.42, dampingFraction: 0.9), reduceMotion: reduceMotion) {
            model.isCommandExpanded = false
            // At rest the soul is small: `.done` would multiply its dabs into mud, so it brightens instead.
            model.tessMode = restingOrIdle
        }
        isBusy = false
        brighten()
        say(answer)
    }

    /// The small soul's "done": its colours brighten for a beat, with a success haptic.
    private func brighten() {
        withTesseraAnimation(.easeOut(duration: 0.25), reduceMotion: reduceMotion) { glow = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            withTesseraAnimation(.easeInOut(duration: 0.6), reduceMotion: reduceMotion) { glow = false }
        }
    }

    /// Tess's line beside the soul, faded after 4 s.
    private func say(_ text: String) {
        withTesseraAnimation(reduceMotion: reduceMotion) { reply = text }
        replyCount += 1
        let shown = replyCount
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard replyCount == shown else { return }
            withTesseraAnimation(reduceMotion: reduceMotion) { reply = nil }
            if !model.isCommandExpanded {
                model.tessMode = restingOrIdle
            }
        }
    }
}

// MARK: - Parts

/// The soul's three paints, top to bottom: vermilion (Speak), cobalt (Write), cadmium (Show).
private enum SoulColor {
    static func of(_ index: Int) -> Color {
        switch index {
        case 0: Theme.Colors.live
        case 1: Theme.Colors.tess
        default: Theme.Colors.now
        }
    }
}

/// One mode: its word at 34 and its dab, which rises out of the soul with a slight overshoot.
private struct ModeRow: View {
    let word: String
    let seed: Int
    let color: Color
    /// How far below its row the soul sits, in points; the dab starts there.
    let rise: CGFloat
    let delay: Double
    let isActive: Bool
    let isFolded: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var risen = false
    @State private var landed = false
    @State private var inWord = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Text(word)
                    .font(BottomChrome.modeFont)
                    .foregroundStyle(isActive ? Theme.Colors.ink : Theme.Colors.ink.opacity(0.55))
                    .offset(x: risen || reduceMotion ? 0 : 24)
                    .opacity(risen ? 1 : 0)
                    // The pigment lands into the word as a wash behind its first letters, then dries away.
                    .background(alignment: .leading) {
                        RadialGradient(colors: [color.opacity(0.28), .clear], center: .center, startRadius: 0,
                                       endRadius: 40)
                            .frame(width: 80, height: 50)
                            .blur(radius: 4)
                            .opacity(landed ? 1 : 0)
                            .allowsHitTesting(false)
                    }
                // The soul's pigment rises out of it and lands in the word; at rest only the word remains.
                PaintDab(color: color, size: CGSize(width: 22, height: 18), seed: seed)
                    .scaleEffect(risen ? 1 : 0.7)
                    .offset(y: risen || reduceMotion ? 0 : rise)
                    .opacity(risen && !inWord ? 1 : 0)
                    .frame(width: 64)
            }
            .frame(maxWidth: .infinity, minHeight: BottomChrome.rowHeight, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 13)
        .opacity(isFolded ? 0 : 1)
        .frame(height: isFolded ? 0 : BottomChrome.rowHeight)
        .clipped(antialiased: false)
        .allowsHitTesting(!isFolded)
        .accessibilityHidden(isFolded)
        .onAppear {
            withTesseraAnimation(.spring(response: 0.48, dampingFraction: 0.68).delay(delay),
                                 reduceMotion: reduceMotion) { risen = true }
            guard !reduceMotion else {
                inWord = true
                return
            }
            withAnimation(.easeOut(duration: 0.2).delay(delay + 0.45)) {
                landed = true
                inWord = true
            }
            withAnimation(.easeIn(duration: 0.5).delay(delay + 0.75)) { landed = false }
        }
    }
}

/// The writing line: the cobalt dab stretched sideways into a 0.5 pt hairline at 60%, drawn from the right.
private struct WritingLine: View {
    let color: Color
    let reduceMotion: Bool
    @State private var drawn = false

    var body: some View {
        Rectangle()
            .fill(color.opacity(0.6))
            .frame(height: 0.5)
            .scaleEffect(x: drawn ? 1 : 0.06, anchor: .trailing)
            .opacity(drawn ? 1 : 0)
            .onAppear {
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Theme.Motion.house.delay(0.05)) { drawn = true }
            }
    }
}

/// The wash Tess opens over: the ground at 95% rising from the bottom, 470 pt, with no top edge and a faint
/// cobalt warmth in the soul's corner.
private struct CaptureWash: View {
    let dark: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle().fill(Theme.Colors.paper.opacity(0.95))
            if !dark {
                RadialGradient(colors: [Theme.Colors.tess.opacity(0.12), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 320)
            }
        }
        .frame(height: 470)
        .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.3)],
                             startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea(.container, edges: .bottom)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
    }
}

/// A label word (16/700 uppercase): on touch the ink goes full and a 1.5 pt hairline draws out from the centre.
struct InkLabelWordStyle: ButtonStyle {
    var color: Color = Theme.Colors.inkSecondary
    /// UNDO (and Finish or Resume while something runs) keep their colour at rest; every other label word rests in
    /// ink and shows its colour only on press (no-dots B5).
    var keepsColor = false

    static var undo: InkLabelWordStyle {
        InkLabelWordStyle(color: Theme.Colors.liveInk, keepsColor: true)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.labelStrong)
            .textCase(.uppercase)
            .foregroundStyle(configuration.isPressed || keepsColor ? color : Theme.Colors.ink)
            .overlay(alignment: .bottom) {
                Rectangle().fill(color).frame(height: 1.5)
                    .scaleEffect(x: configuration.isPressed ? 1 : 0, anchor: .center)
                    .offset(y: 4)
                    .tesseraAnimation(.easeOut(duration: 0.18), value: configuration.isPressed)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// A value word inside a line: on touch a soft, edgeless cobalt wash blooms behind it.
private struct ValueWordStyle: ButtonStyle {
    var weight: Font.Weight = .semibold
    var opacity: Double = 1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.font(Theme.concept.scale.body, weight: weight))
            .foregroundStyle(Theme.Colors.ink.opacity(configuration.isPressed ? 1 : opacity))
            .background {
                Rectangle()
                    .fill(Theme.Colors.tess.opacity(configuration.isPressed ? 0.22 : 0))
                    .padding(-6)
                    .blur(radius: 5)
                    .tesseraAnimation(.easeOut(duration: 0.12), value: configuration.isPressed)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// A running process (a live workout) shown as a lit seam along the top edge; tap to return to it.
struct RunningSeam: View {
    let session: WorkoutSession
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ProcessSeam()
                .frame(maxHeight: .infinity, alignment: .top)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(session.workout.title) is running. Return to workout")
    }
}

/// Tess's command grammar (on-device, deterministic for now; Foundation Models comes later).
@MainActor
struct CommandInterpreter {
    let model: AppModel

    func run(_ raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "Try “log bench 82.5x8”." }
        if let match = text.firstMatch(of: /^log\s+(.+?)\s+(\d+(?:[.,]\d+)?)\s*[x×]\s*(\d+)$/.ignoresCase()) {
            return log(
                exerciseQuery: String(match.1),
                weight: Double(match.2.replacingOccurrences(of: ",", with: ".")) ?? 0,
                reps: Double(match.3) ?? 0
            )
        }
        if text.lowercased().contains("best") || text.lowercased().contains(/\bprs?\b/) {
            guard let exercise = exercise(matching: text), let best = model.bestSet(of: exercise) else {
                return "No logged sets for that yet."
            }
            return "Your best \(exercise.name.lowercased()): \(Format.kilograms(best.weight)) × \(Int(best.reps)), "
                + "e1RM \(Format.kilograms((best.e1RM * 10).rounded() / 10)) kg."
        }
        let title = text.prefix(1).uppercased() + text.dropFirst()
        guard model.capture(title: title, startsAt: AppClock.now.addingTimeInterval(4 * 3600)) != nil else {
            return "Couldn’t save that."
        }
        return "Drying. Swipe to drop it."
    }

    private func exercise(matching text: String) -> ClassDef? {
        let words = text.lowercased().split(separator: " ").map(String.init)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 2 && $0 != "log" }
        let classes = model.store.allClasses()
        guard let exerciseRoot = model.classDef(.exercise) else { return nil }
        return classes
            .filter { ClassResolver.isSubclass($0, of: exerciseRoot) && $0.id != exerciseRoot.id }
            .filter { candidate in words.contains { candidate.name.lowercased().contains($0) } }
            .min { $0.name.count < $1.name.count }
    }

    private func log(exerciseQuery: String, weight: Double, reps: Double) -> String {
        guard let exercise = exercise(matching: exerciseQuery) else { return "I don’t know “\(exerciseQuery)” yet." }
        guard let workout = model.session?.workout ?? model.tonightWorkout()
        else { return "No workout today to log into." }
        if model.session == nil {
            model.startWorkout(workout)
            model.isWorkoutPresented = false
        }
        guard let session = model.session,
              let index = session.entries.firstIndex(where: { session.exerciseClass(of: $0)?.id == exercise.id })
        else { return "\(exercise.name) isn’t in \(workout.title)." }
        session.select(entryAt: index)
        session.weight = weight
        session.reps = reps
        session.logSet()
        let e1RM = model.previewE1RM(weight: weight, reps: reps)
            .map { " · e1RM \(Format.kilograms(($0 * 10).rounded() / 10))" } ?? ""
        return "Logged \(exercise.name.lowercased()) \(Format.kilograms(weight)) × \(Int(reps))\(e1RM)."
    }
}
