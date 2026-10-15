import SwiftData
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

    private let barShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            if model.isCommandExpanded {
                panel
                    .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
                    .glassEffectID("command", in: glass)
            } else {
                collapsed
                    .glassEffect(.regular.interactive(), in: barShape)
                    .glassEffectID("command", in: glass)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
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
                    Text("Ask Tess, or log 82.5×8")
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "mic")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink)
                }
                .frame(height: 56)
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

    /// listening → thinking → working → done (with haptic) → idle.
    private func submit() {
        let text = model.commandDraft
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !isBusy else { return }
        isBusy = true
        withTesseraAnimation(reduceMotion: reduceMotion) {
            feedback = nil
            model.tessMode = .thinking
        }
        Task { @MainActor in
            // Tess's grammar is instant today; these beats let each state read before the answer lands.
            try? await Task.sleep(for: .milliseconds(900))
            model.tessMode = .working
            try? await Task.sleep(for: .milliseconds(500))
            let reply = CommandInterpreter(model: model).run(text)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                Color.clear.frame(height: 44)
                TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                    let sweep = TessSoul.phase(context.date.timeIntervalSinceReferenceDate, period: 2.2)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Theme.Colors.training.opacity(0.55))
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, Theme.Colors.training, .clear],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: proxy.size.width * 0.35)
                                .offset(x: reduceMotion ? 0 : proxy.size.width * (sweep * 1.35 - 0.35))
                        }
                    }
                    .frame(height: 2)
                }
            }
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
        guard let taskClass = model.classDef(.task) else { return "Couldn’t save that." }
        let task = model.store.create(taskClass, title: text.prefix(1).uppercased() + text.dropFirst())
        try? model.store.set("startsAt", to: .date(AppClock.now.addingTimeInterval(4 * 3600)), on: task)
        try? model.store.set("length", to: .duration(1800), on: task)
        model.touch()
        return "Added “\(task.title)” to later today."
    }

    private func exercise(matching text: String) -> ClassDef? {
        let words = text.lowercased().split(separator: " ").map(String.init)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 2 && $0 != "log" }
        let classes = (try? model.context.fetch(FetchDescriptor<ClassDef>())) ?? []
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
