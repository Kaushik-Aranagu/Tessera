import SwiftUI
import TesseraCore

/// The floating chrome: the command bar, which morphs into Tess's capture panel. Tess's soul lives at its
/// leading edge; tapping her goes Home. Glass is shaped as a flush, machined inlay — no capsules.
struct BottomChrome: View {
    var onSoulTap: () -> Void = {}
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glass
    @FocusState private var focused: Bool
    @State private var feedback: String?
    @State private var isBusy = false

    private let barShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            if model.isCommandExpanded {
                panel
                    .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
                    .glassEffectID("command", in: glass)
            } else {
                collapsed
                    .background(barShape.fill(Color(hex: 0xFAF6EF).opacity(0.55)))
                    .glassEffect(.regular.interactive(), in: barShape)
                    .overlay {
                        barShape.strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(0.9), location: 0),
                                                                     .init(color: .clear, location: 0.05)],
                                                             startPoint: .top, endPoint: .bottom), lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                    .overlay { barShape.stroke(Theme.Colors.ink.opacity(0.25), lineWidth: 0.5).allowsHitTesting(false) }
                    .glassEffectID("command", in: glass)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, Theme.Spacing.xs)
        .onChange(of: model.isCommandExpanded) { _, expanded in
            focused = expanded
            if !expanded {
                feedback = nil
            }
            if !isBusy {
                model.tessMode = expanded ? .listening : restingOrIdle
            }
        }
        .onAppear { model.tessMode = restingOrIdle }
    }

    private var restingOrIdle: TessSoul.Mode {
        let hour = Calendar.current.component(.hour, from: AppClock.now)
        return hour >= 23 || hour < 6 ? .resting : .idle
    }

    private func toggle(_ expanded: Bool) {
        if model.launchNote != nil {
            TesseraSchema.clearLaunchNote()
        }
        model.launchNote = nil
        withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = expanded }
    }

    private var soul: some View {
        Button(action: onSoulTap) {
            TessSoul(mode: model.tessMode)
                .scaleEffect(0.62)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tess. Go home")
    }

    private var collapsed: some View {
        HStack(spacing: Theme.Spacing.s) {
            soul
            Button { toggle(true) } label: {
                HStack(spacing: Theme.Spacing.m) {
                    Text(model.lastCapture != nil ? "Added to Later." :
                        model.pendingCapture != nil ? "Drying. Swipe to drop it." :
                        model.launchNote ?? "Ask Tess, or log a set")
                        .font(Theme.voice)
                        .foregroundStyle(model.lastCapture != nil || model.pendingCapture != nil || model
                            .launchNote != nil
                            ? Theme.Colors.tess : Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .contentTransition(.opacity)
                    Spacer(minLength: 0)
                    if model.lastCapture != nil {
                        Button("Undo") { model.undoLastCapture() }
                            .textRole(.bodyStrong)
                            .foregroundStyle(Theme.Colors.live)
                            .frame(minWidth: 60, minHeight: 60)
                            .transition(.opacity)
                    }
                    // No mic glyph until voice ships (slice 17): it did nothing.
                }
                .frame(height: 74)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ask Tess or log something")
        }
        .padding(.leading, Theme.Spacing.xs)
        .padding(.trailing, Theme.Spacing.l + 2)
    }

    private var panel: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                soul
                Eyebrow(text: "Tess", color: Theme.Colors.live)
                Spacer()
                Button { toggle(false) } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
            TextField("log 82.5×8, or ask", text: $model.commandDraft)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .focused($focused)
                .submitLabel(.go)
                .onSubmit(submit)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, Theme.Spacing.xs)
                .onChange(of: model.commandDraft) { _, draft in
                    if !isBusy {
                        model.tessMode = draft.isEmpty ? .idle : .listening
                    }
                }
            if let feedback {
                Text(feedback)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .transition(.opacity.combined(with: .offset(y: 6)))
            }
            FlowLayout(spacing: Theme.Spacing.s) {
                ForEach(["log bench 82.5x8", "bench best?", "stretch at 21:00"], id: \.self) { suggestion in
                    Button {
                        model.commandDraft = suggestion
                        submit()
                    } label: {
                        Text(suggestion)
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(
                                Theme.Colors.hairline,
                                lineWidth: 1
                            ))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.m)
    }

    /// listening → thinking → done (with haptic) → idle.
    private func submit() {
        let text = model.commandDraft
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !isBusy else { return }
        isBusy = true
        withTesseraAnimation(reduceMotion: reduceMotion) {
            feedback = nil
            model.tessMode = .thinking
        }
        Task { @MainActor in
            // Questions about records are answered here; everything else is a capture through Tess's engine
            // (grammar first, the on-device model when Apple Intelligence is available), shown as ghost rows.
            let lowered = text.lowercased()
            let isQuestion = lowered.contains("best") || lowered.contains(" pr") || lowered.hasSuffix("?")
            let started = Date()
            let reply = isQuestion ? CommandInterpreter(model: model).run(text) : await model.ask(text)
            // Let thinking read for a beat even when the answer is instant.
            let elapsed = Date().timeIntervalSince(started)
            if elapsed < 0.6 {
                try? await Task.sleep(for: .seconds(0.6 - elapsed))
            }
            withTesseraAnimation(reduceMotion: reduceMotion) {
                feedback = reply
                model.commandDraft = ""
                model.tessMode = .done
            }
            try? await Task.sleep(for: .milliseconds(1700))
            model.tessMode = model.isCommandExpanded ? .listening : restingOrIdle
            isBusy = false
        }
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
        if text.lowercased().contains("best") || text.lowercased().contains(" pr") {
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
