import SwiftUI
import TesseraCore
import TesseraTess

// Settings › Claude (docs/design/claude-settings.md, Research's settings-claude.md). The key lives only in the
// Keychain: it passes through the SecureField's text once, goes straight to Core's ClaudeKeyCheck, and the field is
// cleared at once. After that only "...a1B2" is ever drawn. Nothing here reads the clipboard by itself.

/// The words for the key's state after a check: "works", "not allowed", "not checked", "account paused".
enum ClaudeKeyWords {
    static func status(_ outcome: String?) -> String {
        switch outcome.flatMap(ClaudeKeyCheck.Outcome.init(rawValue:)) {
        case .works, .capReached: "works"
        case .notAllowed: "not allowed"
        case .accountPaused: "account paused"
        default: "not checked"
        }
    }

    /// "$1.20", rounded up to the cent.
    static func dollars(_ nano: Int64) -> String {
        let cents = (Double(nano) / 10_000_000).rounded(.up)
        return String(format: "$%.2f", cents / 100)
    }

    /// "Nov 1": when a paused month opens again.
    static func nextMonth(_ now: Date, calendar: Calendar = .current) -> String {
        (calendar.dateInterval(of: .month, for: now)?.end ?? now).formatted(.dateTime.month(.abbreviated).day())
    }
}

struct ClaudeSection: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The real Keychain in the app; previews and recordings pass an in-memory one with a fake key.
    var keys: any TessKeychain = ClaudeSection.defaultKeys

    @MainActor static let defaultKeys: any TessKeychain = {
        #if DEBUG
            // `-fakeClaudeKey`: an in-memory key that only looks real, for recordings. Never the Keychain.
            if ProcessInfo.processInfo.arguments.contains("-fakeClaudeKey") {
                return InMemoryKeychain("sk-ant-api03-FAKE-recording-only-a1B2")
            }
        #endif
        return SystemKeychain()
    }()

    @State private var last4: String?
    @State private var status = "not checked"
    @State private var writing = false
    @State private var replacing = false
    @State private var draft = ""
    @State private var checking = false
    @State private var line: String?
    @State private var removed = false
    @State private var removal: Task<Void, Never>?
    @FocusState private var focused: Bool

    private var ledger: TessUsageLedger {
        TessUsageLedger(store: model.store, classes: model.classes)
    }

    var body: some View {
        let _ = model.revision
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("CLAUDE")
                .textRole(.labelStrong)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityAddTraits(.isHeader)

            if let last4, !removed {
                withKey(last4)
                    .transition(.opacity)
            } else {
                noKey
                    .transition(.opacity)
            }

            if let line {
                VStack(alignment: .leading, spacing: 2) {
                    Text(line)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                    if removed {
                        Button("Undo", action: undoRemove)
                            .buttonStyle(.labelWord(Theme.Colors.liveInk))
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .tesseraAnimation(value: last4)
        .tesseraAnimation(value: removed)
        .tesseraAnimation(value: line)
        .tesseraAnimation(value: writing)
        .onAppear(perform: load)
        .onDisappear {
            // Leaving with a removal pending: it goes through now, as it would after 10 s.
            if removed {
                finishRemoval()
            }
        }
    }

    // MARK: No key

    private var noKey: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Tess thinks \(Text("on this phone").fontWeight(.semibold)) only.")
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
            if writing {
                writingLine(prompt: "Paste a key from the Claude Console")
            } else {
                Button("Add a Claude key") { open() }
                    .buttonStyle(.valueWash)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.tess)
                    .frame(minHeight: 44)
            }
        }
    }

    // MARK: With a key

    @ViewBuilder
    private func withKey(_ last4: String) -> some View {
        let spent = ledger.monthTotal(now: AppClock.now)
        let share = min(Double(spent) / Double(TessUsageLedger.capNano), 1)
        let paused = spent >= TessUsageLedger.capNano
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Tess can ask \(Text("Claude").fontWeight(.semibold)).")
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Group {
                    if paused {
                        Text("Paused until \(Text(ClaudeKeyWords.nextMonth(AppClock.now)).fontWeight(.semibold)).")
                    } else {
                        Text("This month \(Text(ClaudeKeyWords.dollars(spent)).fontWeight(.semibold)) of $10.")
                    }
                }
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                MonthLine(share: share, warm: share >= 0.8)
                    .accessibilityLabel(String(format: "%.2f of 10 dollars this month", Double(spent) / 1e9))
                if share >= 0.8, !paused {
                    Text("PAUSES AT $10")
                        .textRole(.labelStrong)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(
                    "Key ends in \(Text("...\(last4)").fontWeight(.semibold)) · \(Text(status).foregroundStyle(Theme.Colors.inkSecondary))"
                )
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityLabel("Claude key, ends in \(last4), \(status)")
                HStack(spacing: 22) {
                    Button("Test") { retest() }
                    Button("Replace") {
                        replacing = true
                        open()
                    }
                    Button("Remove", action: remove)
                }
                .buttonStyle(.labelWord(Theme.Colors.inkSecondary))
                .disabled(checking)
                if replacing, writing {
                    writingLine(prompt: "Paste the new key")
                }
            }
        }
    }

    // MARK: The writing line

    /// A 0.5 pt cobalt line, no box. Paste by long press; the check runs by itself the moment a key lands.
    private func writingLine(prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SecureField(text: $draft, prompt: Text(prompt).foregroundStyle(Theme.Colors.inkSecondary)) {
                Text("Claude key")
            }
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .tint(Theme.Colors.tess)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focused)
            .onChange(of: draft) { old, new in
                // A paste lands many characters at once (typing a key by hand isn't a thing): check it then.
                if new.count - old.count >= 10 {
                    submit()
                }
            }
            .onSubmit(submit)
            .onChange(of: focused) { _, isFocused in
                if !isFocused, draft.isEmpty, !checking {
                    withTesseraAnimation(reduceMotion: reduceMotion) {
                        writing = false
                        replacing = false
                    }
                }
            }
            Rectangle()
                .fill(Theme.Colors.tess.opacity(0.6))
                .frame(height: 0.5)
        }
        .frame(minHeight: 44)
        .transition(.opacity.combined(with: .offset(y: -6)))
    }

    // MARK: Actions

    private func load() {
        guard let key = keys.read() else {
            last4 = nil
            return
        }
        last4 = String(key.suffix(4))
        let lastCheck = ledger.calls()
            .filter { model.store.value("use", of: $0)?.stringValue == TessUse.keyCheck.rawValue }
            .max { $0.createdAt < $1.createdAt }
        status = ClaudeKeyWords.status(lastCheck.flatMap { model.store.value("outcome", of: $0)?.stringValue })
    }

    private func open() {
        line = nil
        withTesseraAnimation(reduceMotion: reduceMotion) { writing = true }
        focused = true
    }

    /// The pasted text goes straight to the check and the field is cleared, so the key is never held or drawn.
    private func submit() {
        let pasted = draft.filter { !$0.isWhitespace }
        draft = ""
        guard !pasted.isEmpty, !checking else { return }
        guard pasted.hasPrefix("sk-ant-") else {
            line = "That doesn't look like a Claude key. Paste it again?"
            return
        }
        // Replace keeps the old key working until the new one passes.
        let previous = replacing ? keys.read() : nil
        check(pasted, previous: previous)
    }

    private func retest() {
        guard let key = keys.read() else { return }
        check(key, previous: nil)
    }

    private func check(_ key: String, previous: String?) {
        checking = true
        focused = false
        line = "Checking it with Claude."
        model.tessMode = .thinking
        let checker = ClaudeKeyCheck(keys: keys, ledger: ledger)
        Task { @MainActor in
            let result = await checker.test(pasted: key)
            checking = false
            model.tessMode = .done
            if let previous, result.outcome != .works, result.outcome != .capReached {
                // A new key that failed: the old one stays, and its state's line explains why.
                _ = keys.save(previous)
                line = result.line
                replacing = false
                writing = false
                model.touch()
                return
            }
            withTesseraAnimation(reduceMotion: reduceMotion) {
                line = result.line
                last4 = result.last4
                status = ClaudeKeyWords.status(result.outcome.rawValue)
                writing = result.outcome == .badKey
                replacing = false
            }
            model.touch()
        }
    }

    /// One tap, no confirm: everything folds away and S1 shows, with UNDO for 10 s. The Keychain item goes only
    /// when the 10 s are up.
    private func remove() {
        withTesseraAnimation(.easeInOut(duration: 0.22), reduceMotion: reduceMotion) {
            removed = true
            writing = false
            line = "Claude key removed. Everything stays on this phone."
        }
        removal?.cancel()
        removal = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled, removed else { return }
            finishRemoval()
        }
    }

    private func undoRemove() {
        removal?.cancel()
        withTesseraAnimation(reduceMotion: reduceMotion) {
            removed = false
            line = "Claude key is back."
        }
    }

    private func finishRemoval() {
        keys.delete()
        removed = false
        last4 = nil
        status = "not checked"
        withTesseraAnimation(reduceMotion: reduceMotion) { line = nil }
        model.touch()
    }
}

/// The month: a hairline across the column with a 6 pt brushstroke painted to the share spent. Cobalt until 80%,
/// then the look's amber (`now`) — the stroke only, never the text.
private struct MonthLine: View {
    let share: Double
    let warm: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Colors.hairline)
                    .frame(height: 0.5)
                Brushstroke()
                    .stroke(warm ? Theme.Colors.now : Theme.Colors.tess,
                            style: StrokeStyle(lineWidth: 6, lineCap: .butt))
                    .frame(width: max(proxy.size.width * (drawn || reduceMotion ? share : 0), 0), height: 6)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 12)
        .onAppear {
            withTesseraAnimation(.easeOut(duration: 0.5), reduceMotion: reduceMotion) { drawn = true }
        }
    }
}
