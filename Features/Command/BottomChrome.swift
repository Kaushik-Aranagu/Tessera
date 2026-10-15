import SwiftData
import SwiftUI

/// The only glass in the app: the command bar (which morphs into Tess's capture panel) and the running-workout
/// pill, sharing one `GlassEffectContainer` so they blend as they move.
struct BottomChrome: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.zoomNamespace) private var zoomNamespace
    @Namespace private var glass
    @FocusState private var focused: Bool
    @State private var feedback: String?
    @State private var isThinking = false

    var body: some View {
        @Bindable var model = model
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 10) {
                if let session = model.session, !model.isWorkoutPresented, !model.isCommandExpanded {
                    WorkoutPill(session: session)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .glassEffectID("pill", in: glass)
                        .modifier(ZoomSource(id: "workout", namespace: zoomNamespace))
                        .onTapGesture { model.isWorkoutPresented = true }
                }
                if model.isCommandExpanded {
                    panel
                        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.panel))
                        .glassEffectID("command", in: glass)
                } else {
                    collapsed
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .glassEffectID("command", in: glass)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.xs)
        .onChange(of: model.isCommandExpanded) { _, expanded in
            focused = expanded
            if !expanded {
                feedback = nil
            }
        }
    }

    private func toggle(_ expanded: Bool) {
        withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = expanded }
    }

    private var collapsed: some View {
        Button { toggle(true) } label: {
            HStack(spacing: Theme.Spacing.m) {
                Text("›")
                    .textRole(.labelStrong)
                    .foregroundStyle(Theme.Colors.live)
                Text("Ask Tess, or log 82.5×8")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink)
            }
            .padding(.horizontal, Theme.Spacing.l + 2)
            .frame(height: 54)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Tess or log something")
    }

    private var panel: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Eyebrow(text: "Tess", color: Theme.Colors.live)
                Spacer()
                Button { toggle(false) } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Close")
            }
            HStack(alignment: .center, spacing: Theme.Spacing.s) {
                Group {
                    if isThinking {
                        ThinkingIndicator(size: 20).transition(.scale.combined(with: .opacity))
                    } else {
                        Text("›").textRole(.labelStrong).foregroundStyle(Theme.Colors.live)
                    }
                }
                .frame(width: 22)
                TextField("log bench 82.5x8, or ask anything", text: $model.commandDraft)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit(submit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            if let feedback {
                Text(feedback)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .transition(.opacity.combined(with: .offset(y: 6)))
            }
            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(["log bench 82.5x8", "what's my bench best?", "stretch at 21:00"],
                            id: \.self)
                    { suggestion in
                        Button {
                            model.commandDraft = suggestion
                            submit()
                        } label: {
                            Text(suggestion)
                                .textRole(.data)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .overlay(Capsule().strokeBorder(Theme.Colors.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(Theme.Spacing.l + 2)
    }

    private func submit() {
        let text = model.commandDraft
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !isThinking else { return }
        withTesseraAnimation(reduceMotion: reduceMotion) {
            isThinking = true
            feedback = nil
        }
        Task { @MainActor in
            // Tess's grammar is instant today; the beat lets the thinking state read before the answer lands.
            try? await Task.sleep(for: .milliseconds(650))
            let reply = CommandInterpreter(model: model).run(text)
            withTesseraAnimation(reduceMotion: reduceMotion) {
                isThinking = false
                feedback = reply
                model.commandDraft = ""
            }
        }
    }
}

private struct WorkoutPill: View {
    let session: WorkoutSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.training)
                .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
            Text(session.workout.title)
                .textRole(.bodyStrong)
                .foregroundStyle(Theme.Colors.ink)
            if let entry = session.currentEntry {
                Text(
                    "· \(session.currentExercise?.name ?? "") \(session.loggedSets(of: entry).count)/\(session.targetSets(of: entry))"
                )
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Format.duration(AppClock.adjust(context.date).timeIntervalSince(session.startedAt)))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.ink)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, Theme.Spacing.l + 2)
        .frame(height: 48)
        .contentShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the running workout")
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
        let words = text.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 && $0 != "log" }
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
