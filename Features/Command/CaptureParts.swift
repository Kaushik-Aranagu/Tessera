import SwiftUI
import TesseraCore

// MARK: - Parts

/// The soul's three paints, top to bottom: vermilion (Speak), cobalt (Write), cadmium (Show).
enum SoulColor {
    static func of(_ index: Int) -> Color {
        switch index {
        case 0: Theme.Colors.live
        case 1: Theme.Colors.tess
        default: Theme.Colors.now
        }
    }
}

/// One mode: its word at 34 and its dab, which rises out of the soul with a slight overshoot.
struct ModeRow: View {
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
                    .textRole(.bodyStrong)
                    .foregroundStyle(isActive ? Theme.Colors.ink : Theme.Colors.inkSecondary)
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
                PaintDab(color: color, size: CGSize(width: 16, height: 14), seed: seed)
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
            withTesseraAnimation(.spring(response: 0.46, dampingFraction: 0.85).delay(delay),
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
struct CaptureWritingLine: View {
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

/// The wash Tess opens over: the ground at 96% rising from the bottom, 380 pt, with no top edge and fully opaque from
/// 22% of its height (calm-capture.md). No cobalt warmth.
struct CaptureWash: View {
    let dark: Bool

    var body: some View {
        Rectangle().fill(Theme.Colors.paper.opacity(0.96))
            .frame(height: 380)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.22)],
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
        // Never a task titled with a key, a secret, money or a body fact (board 0ah, Research AU): a question about
        // one is answered on the phone and saves nothing; anything else is a private note, as the Bar files it.
        if looksLikeClaudeKey(text) {
            return claudeKeyLine
        }
        let secret = SecretWords.mentions(text)
        if secret || PrivateFacts.isWalled(text, lastWeightKg: BodyWeight.lastKg(in: model.store)) {
            if text.hasSuffix("?") {
                return secret ? "It's in your private notes." : "That stays on this phone."
            }
            guard (try? model.engine.perform(CreateNote(body: text, isPrivate: true), by: .user)) != nil else {
                return "Couldn't save that."
            }
            model.touch()
            return "\(SecretWords.title), kept."
        }
        let title = text.prefix(1).uppercased() + text.dropFirst()
        guard model.capture(title: title, startsAt: AppClock.now.addingTimeInterval(4 * 3600)) != nil else {
            return "Couldn't save that."
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
        let e1RM = model.previewE1RM(weight: weight, reps: reps).map { ($0 * 10).rounded() / 10 }
        return Self.loggedReceipt(exercise: exercise.name, weight: weight, reps: reps, e1RM: e1RM)
    }

    /// Thing first (receipts-thing-first.md RC12): "Bench press 82.5 × 8, logged. e1RM 105.".
    static func loggedReceipt(exercise: String, weight: Double, reps: Double, e1RM: Double?) -> String {
        let lower = exercise.lowercased()
        let name = lower.prefix(1).uppercased() + lower.dropFirst()
        let line = "\(name) \(Format.kilograms(weight)) × \(Int(reps)), logged."
        return e1RM.map { "\(line) e1RM \(Format.kilograms($0))." } ?? line
    }
}
