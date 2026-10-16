import SwiftUI
import TesseraCore
import TesseraTess

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
    @State private var undos = 0
    /// The open set-count ask, drawn beside the soul until he taps an answer or says something new.
    @State private var setAsk: TessSetCountAsk?
    private let voice = Tessera.TessVoice.shared
    @State private var breathe = false
    @State private var opens = 0
    @State private var reply: String?
    @State private var replyCount = 0
    @State private var ghost: String?
    @State private var drying: CGFloat = 0
    @State private var dryTask: Task<Void, Never>?
    @State private var isBusy = false

    enum Layer { case modes, write, speak }

    /// Tess's ears, and what she heard while it dries.
    @State private var listener = SpeechListener()
    @State private var voiceGhost: (clean: String, heard: String)?
    @State private var refusal: SpeechListener.Refusal?
    @State private var holdTimer: Task<Void, Never>?
    @State private var holdListening = false
    /// The hold timer fired on this press, so letting go is never a tap (even after a refused listen).
    @State private var holdFired = false
    /// A first tap waiting out the double-tap window.
    @State private var pendingTap: Task<Void, Never>?
    /// The one-time "Hold me to talk." hint: 0 not yet, 1 showing (after the first Allow), 2 done for good.
    @AppStorage("tess.holdHint") private var holdHint = 0
    /// The open dated-lift ask ("Bench 80 × 8 for Monday?"), answered with LOG or NOT NOW.
    @State private var liftAsk: TessDatedLiftAsk?

    /// The three modes, top to bottom. Their dabs are the soul's three colours.
    static let modes: [(word: String, seed: Int)] = [("Speak", 1), ("Write", 2), ("Show", 3)]
    static let rowHeight: CGFloat = 48
    /// The soul's centre sits this far above the bottom of the chrome; the mode column starts above it.
    static let soulLift: CGFloat = 54

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if model.isCommandExpanded {
                // The page recedes behind a veil of blurred ground (z); a tap on it closes Tess.
                // Calmer: the page blurs a little and drops to 50% (calm-capture.md).
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).opacity(0.35)
                    Theme.Colors.paper.opacity(0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                // A tap on the veil cancels a listen: nothing saved, no line.
                .onTapGesture {
                    if listener.state != .idle {
                        listener.stop(send: false)
                    }
                    close()
                }
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
                    model.soul.handle(.closed)
                }
            }
        }
        // An ask beside her owns the page while it waits (tess-motion.md §8, §15).
        .onChange(of: setAsk != nil || liftAsk != nil) { _, waiting in
            model.soul.handle(waiting ? .askWaiting : .askAnswered)
        }
        // A set ask belongs to the workout: it goes when the workout ends (QA C3).
        .onChange(of: model.session == nil) { _, ended in
            if ended {
                setAsk = nil
            }
        }
        .onDisappear(perform: askLeft)
        .onAppear {
            model.soul.handle(.appeared)
            breathe = !reduceMotion
            #if DEBUG
                if LaunchFlags.has("-tessScript") {
                    playScript()
                }
                if LaunchFlags.has("-speakScript") {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        open()
                        try? await Task.sleep(for: .seconds(1.4))
                        speak(hold: false)
                    }
                }
            #endif
        }
        .sensoryFeedback(.selection, trigger: opens)
        .sensoryFeedback(.success, trigger: model.soul.isBright) { _, lit in lit }
        .sensoryFeedback(.decrease, trigger: undos)
        // Core's overnight lines (the 04:00 roll, a workout wrapped up while away) show once, beside the soul
        // (late-night #13).
        .onChange(of: model.processNotes, initial: true) { _, notes in
            guard !notes.isEmpty else { return }
            // The empty wrap-up's UNDO brings the workout back (QA L2).
            voice.say(notes.joined(separator: " "), undo: model.processUndo)
            model.processNotes = []
            model.processUndo = nil
        }
    }

    // MARK: Rest

    /// One line per capture: Tess's reply wins; there are no generic fallbacks. UNDO stays while there's a capture.
    private var line: String? {
        reply ?? voice.note?.text ?? model.launchNote
    }

    private var resting: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            if !model.isCommandExpanded, line != nil || canUndo || setAsk != nil || liftAsk != nil || holdHint == 1 {
                VStack(alignment: .trailing, spacing: 2) {
                    if let liftAsk {
                        // "Bench 80 × 8 for Monday?" with LOG · NOT NOW as label words.
                        Text(liftAsk.line)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.tess)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 270, alignment: .trailing)
                        HStack(spacing: 30) {
                            Button("Log") { answerLift(.log) }
                            Button("Not now") { answerLift(.notNow) }
                        }
                        .buttonStyle(.labelWord)
                    } else if setAsk == nil, line == nil, !canUndo, holdHint == 1 {
                        Text(model.session != nil ? "Hold me to tell me a set." : "Hold me to talk.")
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.tess)
                    }
                    if let setAsk {
                        // "2 × 10: 2 sets, or 2 kg?": the two answers are value words in the line, ink at rest.
                        HStack(spacing: 0) {
                            Text("\(setAsk.count) × \(Format.kilograms(setAsk.reps)): ")
                                .foregroundStyle(Theme.Colors.tess)
                            Button(setAsk.setsAnswer) { answerAsk(.sets) }
                                .buttonStyle(.valueWash)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.Colors.ink)
                            Text(", or ").foregroundStyle(Theme.Colors.tess)
                            Button(setAsk.kilogramsAnswer) { answerAsk(.kilograms) }
                                .buttonStyle(.valueWash)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.Colors.ink)
                            Text("?").foregroundStyle(Theme.Colors.tess)
                        }
                        .font(Theme.voice)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    } else if let line {
                        // One line sits right by the soul; a line that wraps sets left-aligned from the gutter
                        // (Design S2 on #273).
                        ViewThatFits(in: .horizontal) {
                            Text(line).lineLimit(1)
                            Text(line)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
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
        TessSoul(mode: model.tessMode, hostScale: 0.72, eyes: model.tessHasEyes, gaze: model.soul.gaze)
            .scaleEffect(0.72)
            .scaleEffect(breathe ? 1.08 : 1)
            .tesseraAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: breathe)
            .scaleEffect(swell ? 1.06 : 1)
            // The brighten after a local capture is the router's (900 ms), drawn here.
            .saturation(model.soul.isBright ? 1.35 : 1)
            .brightness(model.soul.isBright ? 0.08 : 0)
            .tesseraAnimation(.easeOut(duration: model.soul.isBright ? 0.25 : 0.6), value: model.soul.isBright)
            .frame(width: 46, height: 40)
            .frame(width: 64, height: 64)
            .contentShape(Rectangle())
            .opacity(model.isCommandExpanded ? 0 : 1)
            // Feedback on touch-down, so the double-tap wait never reads as lag.
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    holdFired = false
                    opens += 1
                    if !reduceMotion {
                        withAnimation(.easeOut(duration: 0.13)) { swell = true }
                    }
                    // Holding the soul at rest is the fast path: listen while held (speak.md 1).
                    holdTimer = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        guard !Task.isCancelled, pressed, !model.isCommandExpanded else { return }
                        holdFired = true
                        holdListening = true
                        speak(hold: true)
                    }
                }
                .onEnded { value in
                    pressed = false
                    holdTimer?.cancel()
                    withAnimation(.easeInOut(duration: 0.13)) { swell = false }
                    // Let go to send; drag left off the soul to cancel.
                    if holdListening {
                        holdListening = false
                        listener.stop(send: value.translation.width > -60)
                    } else if !holdFired, abs(value.translation.width) < 12, abs(value.translation.height) < 12 {
                        soulTapped()
                    }
                })
            .scaleEffect(holdListening ? 1.4 + listener.level * 0.15 : 1)
            .animation(.easeOut(duration: 0.12), value: listener.level)
            .accessibilityElement()
            .accessibilityLabel("Tess")
            .accessibilityHint("Opens Tess.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { toggle() }
            .accessibilityAction(named: "Go home") { onSoulDoubleTap() }
            .accessibilityAction(named: "Talk to Tess") {
                if listener.state == .idle {
                    speak(hold: true)
                } else {
                    listener.stop(send: true)
                }
            }
    }

    // MARK: Open

    /// One question, on the mode layer only (calm-capture.md): never a command list.
    private var question: String {
        model.session != nil ? "Tell me a set." : "What’s on your mind?"
    }

    /// At most one fast path, the likeliest for right now. "Today" is gone: a double tap on the soul goes home.
    private var fastPath: (String, () -> Void)? {
        if let session = model.session {
            return ("Back to \(session.workout.title)", { [model] in
                model.isCommandExpanded = false
                model.isWorkoutPresented = true
            })
        }
        if let workout = model.tonightWorkout() {
            return ("Start \(workout.title)", { [model] in
                model.isCommandExpanded = false
                model.startWorkout(workout)
            })
        }
        return nil
    }

    private var surface: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if layer == .modes {
                VStack(alignment: .trailing, spacing: Theme.Spacing.m) {
                    Text(question)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                    if let fastPath {
                        Button(fastPath.0, action: fastPath.1)
                            .buttonStyle(.labelWord)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.bottom, Theme.Spacing.l)
                .transition(.opacity)
            }

            if layer == .write {
                writing
                    .transition(.opacity)
            }
            if layer == .speak {
                speaking
                    .transition(.opacity)
            }
            ForEach(Array(Self.modes.enumerated()), id: \.offset) { index, mode in
                ModeRow(word: mode.word, seed: mode.seed, color: SoulColor.of(index),
                        rise: CGFloat(Self.modes.count - index) * Self.rowHeight - Self.rowHeight / 2 + Self.soulLift
                            - Self.rowHeight / 2,
                        delay: Double(Self.modes.count - 1 - index) * 0.04,
                        isActive: mode.word == "Write",
                        isFolded: layer != .modes)
                {
                    if mode.word == "Write" {
                        withTesseraAnimation(reduceMotion: reduceMotion) { layer = .write }
                        focused = true
                    } else if mode.word == "Speak" {
                        speak(hold: false)
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

    /// Listening, then the voice ghost drying (speak.md).
    private var speaking: some View {
        SpeakLayer(listener: listener, ghost: voiceGhost, refusal: refusal, drying: drying,
                   act: { act(on: $0) }, editGhost: editVoiceGhost)
    }

    private var writing: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ZStack(alignment: .bottomLeading) {
                TextField("Ask", text: $model.commandDraft,
                          prompt: Text("Write anything").foregroundStyle(Theme.Colors.inkSecondary))
                    // His typing sits one step under her voice: Field 18 (calm-capture.md addendum).
                    .textRole(.field)
                    // The drying ghost reads in inkSecondary (calm-capture.md).
                    .foregroundStyle(ghost == nil ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                    .tint(Theme.Colors.tess)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(dry)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(ghost != nil)
                    .padding(.bottom, 6)
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
                            model.soul.handle(.draft(isEmpty: draft.isEmpty))
                        }
                    }
                // While the ghost dries only the dry line shows (Design B2 on #264).
                if ghost == nil {
                    CaptureWritingLine(color: Theme.Colors.tess, reduceMotion: reduceMotion)
                }
                if ghost != nil {
                    // One dry line for every drying ghost: 2.5 pt cobalt, draining right to left (speak.md 10).
                    Rectangle()
                        .fill(Theme.Colors.tess)
                        .frame(height: 2.5)
                        .scaleEffect(x: 1 - drying, anchor: .leading)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { cancelDrying() }
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.xl)
    }

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
        setAsk = nil
        liftAsk = nil
        model.soul.handle(.tessOpened)
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
        model.soul.handle(.sent)
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
        model.soul.handle(.dryCancelled)
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
        // A doubtful set count waits for a tap on one of its two answers (Core's set guard).
        let asked = isQuestion ? nil : model.pendingSetAsk
        let lift = isQuestion ? nil : model.pendingDatedLift
        ghost = nil
        drying = 0
        model.commandDraft = ""
        withTesseraAnimation(.spring(response: 0.42, dampingFraction: 0.9), reduceMotion: reduceMotion) {
            model.isCommandExpanded = false
            // At rest the soul is small: `.done` would multiply its dabs into mud, so it brightens instead.
            model.soul.handle(.committed)
        }
        isBusy = false
        if let asked {
            withTesseraAnimation(reduceMotion: reduceMotion) { setAsk = asked }
        } else if let lift {
            withTesseraAnimation(reduceMotion: reduceMotion) { liftAsk = lift }
        } else {
            say(answer)
        }
    }
}

// MARK: - Speak and the asks (same file, so they reach the view's private state)

extension BottomChrome {
    /// An ask can't wait off screen (tess-motion.md §14 `askLeft`): leaving with one open lets it go, or the router
    /// would keep refusing the lens. Emitted here because the ask's onChange won't run once the view is gone.
    private func askLeft() {
        guard setAsk != nil || liftAsk != nil else { return }
        setAsk = nil
        liftAsk = nil
        model.soul.handle(.askAnswered)
    }

    /// Taps are read off the press itself: a separate tap gesture never fired beside the touch-down drag, so the
    /// soul didn't open on a real tap. One tap opens or closes after the double-tap window; two go Home.
    private func soulTapped() {
        if let first = pendingTap {
            first.cancel()
            pendingTap = nil
            onSoulDoubleTap()
            return
        }
        pendingTap = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled else { return }
            pendingTap = nil
            toggle()
        }
    }

    private func toggle() {
        if model.isCommandExpanded {
            close()
        } else {
            open()
        }
    }

    /// Touching the drying ghost stops it, and the sentence opens in the Write line to edit.
    private func editVoiceGhost() {
        guard let voiceGhost else { return }
        dryTask?.cancel()
        drying = 0
        model.commandDraft = voiceGhost.clean
        self.voiceGhost = nil
        withTesseraAnimation(reduceMotion: reduceMotion) { layer = .write }
        focused = true
    }

    /// Tap Speak, or hold the soul: ask once, then listen at once.
    private func speak(hold: Bool) {
        refusal = nil
        voiceGhost = nil
        if !hold {
            withTesseraAnimation(reduceMotion: reduceMotion) { layer = .speak }
        }
        model.soul.handle(.speak(hold: hold))
        listener.onFinish = { heard in finishListening(heard, hold: hold) }
        #if DEBUG
            // `-speakScript`: words play in as if heard (the simulator has no mic to record).
            if LaunchFlags.has("-speakScript") {
                listener.playScript(["um", "oat", "milk", "and", "eggs", "for", "groceries"])
                return
            }
        #endif
        Task { @MainActor in
            if let refused = await listener.start(hold: hold) {
                holdListening = false
                if hold {
                    // From a hold the line shows beside the soul; the layer doesn't open. She goes back to rest
                    // first: the line's 4 s never settles her while she's listening.
                    model.soul.handle(.heardNothing)
                    say("\(refused.line) \(refused.action) still works.")
                } else {
                    withTesseraAnimation(reduceMotion: reduceMotion) { refusal = refused }
                }
                return
            }
            // After the first Allow, the hold hint shows by the soul until the first hold that listens.
            if hold {
                holdHint = 2
            } else if holdHint == 0 {
                holdHint = 1
            }
        }
    }

    private func finishListening(_ heard: String?, hold: Bool) {
        holdListening = false
        guard let heard else {
            // Nothing came in the first 5 s (a cancel says nothing at all).
            if listener.endedInSilence {
                close()
                say("Didn't hear anything.")
            } else if !hold {
                close()
            }
            model.soul.handle(.heardNothing)
            return
        }
        if SpokenPhrase.isUndo(heard) {
            close()
            if canUndo {
                undo()
            } else {
                say("Nothing to undo.")
            }
            return
        }
        // Spoken numbers become digits only for a set in a workout; elsewhere the words keep their case ("Call Mum
        // at seven.") (QA S3).
        let tidy = SpokenPhrase.clean(heard)
        let clean = model.session != nil ? TessSpoken.numbers(tidy) : tidy
        if !model.isCommandExpanded {
            withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = true }
        }
        layer = .speak
        withTesseraAnimation(reduceMotion: reduceMotion) { voiceGhost = (clean, heard) }
        model.soul.handle(.heard)
        drying = 0
        let seconds = reduceMotion ? 0.8 : 3.0
        withAnimation(.linear(duration: seconds)) { drying = 1 }
        dryTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, voiceGhost != nil else { return }
            // The ghost stays on screen until the commit closes the surface.
            await commit(clean)
            voiceGhost = nil
        }
    }

    private func act(on refusal: SpeechListener.Refusal) {
        switch refusal {
        case .micOff, .speechOff:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .noLanguage, .busy:
            self.refusal = nil
            withTesseraAnimation(reduceMotion: reduceMotion) { layer = .write }
            focused = true
        }
    }

    private func answerLift(_ choice: TessDatedLiftAsk.Choice) {
        let line = model.answer(choice)
        withTesseraAnimation(reduceMotion: reduceMotion) { liftAsk = nil }
        if !line.isEmpty {
            say(line)
        }
    }

    private func answerAsk(_ choice: TessSetCountAsk.Choice) {
        let line = model.answer(choice)
        withTesseraAnimation(reduceMotion: reduceMotion) { setAsk = nil }
        // The engine may already have dropped the ask (a new phrase): then there's nothing to say (QA C2).
        if !line.isEmpty {
            say(line)
        }
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

    /// Tess's line beside the soul, faded after 4 s.
    private func say(_ text: String) {
        withTesseraAnimation(reduceMotion: reduceMotion) { reply = text }
        // Her side of the line (back to rest after 4 s) is the router's timer.
        model.soul.handle(.lineShown)
        replyCount += 1
        let shown = replyCount
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard replyCount == shown else { return }
            withTesseraAnimation(reduceMotion: reduceMotion) { reply = nil }
        }
    }

    /// UNDO only ever sits under the line whose record it reverts: a Home line ("Done. …", "Carried 2 tasks") shows
    /// it only when that line has its own op; a capture's line shows it for that capture.
    private var canUndo: Bool {
        if let note = voice.note {
            return note.undo != nil || note.takeBack != nil
        }
        return model.lastCapture != nil
    }

    /// Home's last action (done, moved) first, else the last capture.
    private func undo() {
        if let note = voice.note, note.undo != nil || note.takeBack != nil {
            if let record = note.undo {
                _ = model.engine.undo(record)
            }
            note.takeBack?()
            model.touch()
            undos += 1
            withTesseraAnimation(reduceMotion: reduceMotion) { voice.clear() }
        } else {
            model.undoLastCapture()
        }
    }
}
