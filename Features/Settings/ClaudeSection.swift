import SwiftUI
import TesseraCore
import TesseraTess

// Settings › Claude (docs/design/claude-settings.md, Research's settings-claude.md). The key lives only in the
// Keychain: it passes through the SecureField's text once, goes straight to Core's ClaudeKeyCheck, and the field is
// cleared at once. After that the screen says only whether a key is saved. Nothing here reads the clipboard by itself.

/// The words for the key's state after a check: "works", "not allowed", "not checked", "account paused".
enum ClaudeKeyWords {
    static func status(_ outcome: String?) -> String {
        switch outcome.flatMap(ClaudeKeyCheck.Outcome.init(rawValue:)) {
        case .works, .capReached: "works"
        case .notAllowed: "not allowed"
        case .badKey: "didn't work"
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

    #if DEBUG
        /// Recordings only: plainly synthetic, built at run time so no key-shaped literal sits in the app.
        static var fakeKey: String {
            "sk-" + "ant-" + String(repeating: "x", count: 32)
        }
    #endif

    @MainActor static let defaultKeys: any TessKeychain = {
        #if DEBUG
            // `-fakeClaudeKey`: an in-memory key that only looks real, for recordings. Never the Keychain.
            if LaunchFlags.has("-fakeClaudeKey") {
                return InMemoryKeychain(fakeKey)
            }
        #endif
        return SystemKeychain()
    }()

    /// Whether a key is saved: yes or no only. No part of the key is kept or shown (Product 9:53).
    @State private var hasKey = false
    @State private var status = "not checked"
    @State private var writing = false
    @State private var replacing = false
    @State private var draft = ""
    @State private var checking = false
    @State private var line: String?
    /// Remove is two steps: "Remove" asks, "Remove key" does it (Product, 12:22 AM Oct 18).
    @State private var confirmingRemove = false
    /// The first line, "Tess asks Claude": misses and Plan my day. Lives in Core's settings object only.
    @State private var missesGoToClaude = true
    /// Tess's answer to the last flip of the switch, shown under it.
    @State private var switchLine: String?
    /// The clipboard's change count when a key was pasted, so a key still sitting there can be cleared after it passes.
    @State private var pasteChange: Int?
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

            if hasKey {
                withKey
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
                }
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .tesseraAnimation(value: hasKey)
        .tesseraAnimation(value: confirmingRemove)
        .tesseraAnimation(value: line)
        .tesseraAnimation(value: writing)
        .onAppear(perform: load)
    }

    // MARK: No key

    private var noKey: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // After a reinstall or on a new phone the key doesn't come along (restore-walk 6).
            Text(ledger.calls().isEmpty
                ? "Tess thinks \(Text("on this phone").fontWeight(.semibold)) only."
                : "No Claude key on this phone. Paste one here.")
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
            if writing {
                writingLine(prompt: "Paste a key from the Claude Console")
            } else {
                Button("Add a Claude key") { open() }
                    .buttonStyle(.valueWash)
                    .textRole(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minHeight: 44)
            }
            // Old receipts outlive the key (C4).
            if !ledger.calls().isEmpty {
                NavigationLink("Receipts") { ClaudeReceipts() }
                    .buttonStyle(.labelWord)
            }
        }
    }

    // MARK: With a key

    @ViewBuilder
    private var withKey: some View {
        let spent = ledger.monthTotal(now: AppClock.now)
        let share = min(Double(spent) / Double(TessUsageLedger.capNano), 1)
        let paused = spent >= TessUsageLedger.capNano
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: 0) {
                    Text("Tess asks Claude: ")
                    Button(missesGoToClaude ? "yes" : "no", action: toggleMisses)
                        .buttonStyle(.valueWash)
                        .fontWeight(.semibold)
                        .contentTransition(.opacity)
                        .accessibilityLabel("Tess asks Claude")
                        .accessibilityValue(missesGoToClaude ? "yes" : "no")
                    Text(".")
                }
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                // Tess answers the flip inline, under the switch.
                if let switchLine {
                    Text(switchLine)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                        .id(switchLine)
                }
            }
            .tesseraAnimation(.easeOut(duration: 0.18), value: missesGoToClaude)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                // The amount is the word that opens the receipts (C3).
                HStack(spacing: 0) {
                    Text("This month ")
                    NavigationLink(ClaudeKeyWords.dollars(spent)) { ClaudeReceipts() }
                        .buttonStyle(.valueWash)
                        .fontWeight(.semibold)
                        .accessibilityHint("Opens the receipts.")
                    Text(" of $\(TessUsageLedger.capDollars).")
                }
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                MonthLine(share: share, warm: share >= 0.8)
                    .accessibilityLabel(String(format: "%.2f of %d dollars this month", Double(spent) / 1e9,
                                               TessUsageLedger.capDollars))
                if paused {
                    Text("Paused until \(Text(ClaudeKeyWords.nextMonth(AppClock.now)).fontWeight(.semibold)).")
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                } else if share >= 0.8 {
                    Text("PAUSES AT $\(TessUsageLedger.capDollars)")
                        .textRole(.labelStrong)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Key saved · \(Text(status).foregroundStyle(Theme.Colors.inkSecondary))")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityLabel("Claude key saved, \(status)")
                HStack(spacing: 0) {
                    if confirmingRemove {
                        Text("Remove the Claude key? ").textRole(.body).foregroundStyle(Theme.Colors.ink)
                        Button("Remove", action: remove)
                            .accessibilityLabel("Remove the Claude key")
                        Text(" · ").textRole(.labelStrong).foregroundStyle(Theme.Colors.inkSecondary)
                        Button("Keep it") { confirmingRemove = false }
                    } else {
                        Button("Test") { retest() }
                        Text(" · ").textRole(.labelStrong).foregroundStyle(Theme.Colors.inkSecondary)
                        Button("Replace") {
                            replacing = true
                            open()
                        }
                        Text(" · ").textRole(.labelStrong).foregroundStyle(Theme.Colors.inkSecondary)
                        Button("Remove") { confirmingRemove = true }
                    }
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
            .textRole(.field)
            .foregroundStyle(Theme.Colors.ink)
            .tint(Theme.Colors.tess)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focused)
            .onChange(of: draft) { old, new in
                // A paste lands many characters at once (typing a key by hand isn't a thing): check it then.
                if new.count - old.count >= 10 {
                    pasteChange = UIPasteboard.general.changeCount
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

    /// "Tess asks Claude" lives only in Core's settings: the same field the capture router reads (QA M1).
    /// The word shows what's stored, read back after the write (QA F2): a failed write never reads as done.
    private func toggleMisses() {
        let wanted = !missesGoToClaude
        if LaunchFlags.has("-demo") {
            missesGoToClaude = wanted
        } else {
            _ = try? SettingsStore(engine: model.engine).update { $0.missesGoToClaude = wanted }
            missesGoToClaude = model.asksClaude
        }
        switchLine = missesGoToClaude
            ? "Tess asks Claude when she's unsure, and for Plan my day."
            : "Tess stays on this phone."
    }

    private func load() {
        missesGoToClaude = model.asksClaude
        hasKey = keys.read() != nil
        guard hasKey else { return }
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
        model.soul.handle(.askClaude)
        let checker = ClaudeKeyCheck(keys: keys, ledger: ledger)
        Task { @MainActor in
            let result = await checker.test(pasted: key)
            checking = false
            let passed = result.outcome == .works || result.outcome == .capReached
            model.soul.handle(passed ? .claudeDone : .claudeFailed)
            if let previous, result.outcome != .works, result.outcome != .capReached {
                // A new key that failed: the old one goes back and keeps working (QA C3, C4).
                if keys.save(previous) {
                    line = "That key didn't pass. Your old key still works."
                } else {
                    line = "That key failed, and the old one is gone. Add one?"
                    hasKey = false
                }
                replacing = false
                writing = false
                model.touch()
                return
            }
            withTesseraAnimation(reduceMotion: reduceMotion) {
                line = result.line
                hasKey = result.saved
                status = ClaudeKeyWords.status(result.outcome.rawValue)
                writing = result.outcome == .badKey || result.outcome == .notSaved
                replacing = false
            }
            // The key passed: if the clipboard hasn't changed since the paste, it still holds the key, so clear it
            // (QA C5). Writing the clipboard never reads it, so no paste banner.
            if result.saved, result.outcome != .badKey, let change = pasteChange,
               UIPasteboard.general.changeCount == change
            {
                UIPasteboard.general.items = []
            }
            pasteChange = nil
            model.touch()
        }
    }

    /// Step two: the key leaves the Keychain at once and nothing holds it (no UNDO, no timer). A plain receipt says so.
    private func remove() {
        KeyRemoval.remove(from: keys)
        withTesseraAnimation(.easeInOut(duration: 0.22), reduceMotion: reduceMotion) {
            confirmingRemove = false
            writing = false
            hasKey = false
            status = "not checked"
            line = "Claude key removed. Everything stays on this phone."
        }
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

// MARK: - Receipts

/// Every Claude call, newest first, one line each: "6:12 pm · Plan my day · Sonnet · 1.2¢". The month total sits on
/// top in dollars, rounded up; one call shows in cents.
struct ClaudeReceipts: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.revision
        let ledger = TessUsageLedger(store: model.store, classes: model.classes)
        let calls = ledger.calls().sorted { $0.createdAt > $1.createdAt }
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Button { dismiss() } label: {
                    Text("‹ Settings")
                        .textRole(.label)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to Settings")
                Text("Receipts")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                Text(
                    "This month \(Text(ClaudeKeyWords.dollars(ledger.monthTotal(now: AppClock.now))).fontWeight(.semibold)) of $\(TessUsageLedger.capDollars)."
                )
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                if calls.isEmpty {
                    Text("Nothing has gone to Claude yet.")
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                } else {
                    ForEach(calls, id: \.id) { call in
                        Text(ClaudeKeyWords.receipt(call, store: model.store))
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .background { ThemedBackground() }
        // The system back button is hidden, so the edge swipe back is ours (QA L1 on #353).
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

extension ClaudeKeyWords {
    /// "6:12 pm · Plan my day · Sonnet · 1.2¢".
    @MainActor
    static func receipt(_ call: ObjectRecord, store: ObjectStore) -> String {
        let time = receiptTime(call.createdAt)
        let use = store.value("use", of: call)?.stringValue.flatMap(TessUse.init(rawValue:))
        let model = store.value("model", of: call)?.stringValue ?? ""
        let nano = Int64(store.number("costNano", of: call) ?? 0)
        return [time, useName(use), modelName(model), cents(nano)].joined(separator: " · ")
    }

    /// "Thu Oct 16, 12 pm": the house clock (HouseTime), never "12:00 pm" or a 24-hour time, whatever the phone's
    /// clock setting (kitchen gap hunt G39). The day is fixed English too, so the receipt reads the same everywhere.
    static func receiptTime(_ date: Date, calendar: Calendar = .current) -> String {
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.calendar = calendar
        day.timeZone = calendar.timeZone
        day.dateFormat = "EEE MMM d"
        return "\(day.string(from: date)), \(HouseTime.clock(date, calendar: calendar))"
    }

    static func useName(_ use: TessUse?) -> String {
        switch use {
        case .keyCheck: "Key check"
        case .plan: "Plan my day"
        case .lines: "Home"
        case .capture: "A capture"
        case .question: "A question"
        case .paste: "A paste"
        case .recipeLink: "Recipe link"
        default: "Tess"
        }
    }

    static func modelName(_ model: String) -> String {
        model.contains("haiku") ? "Haiku" : model.contains("opus") ? "Opus" : model.contains("sonnet") ? "Sonnet" : "Claude"
    }

    /// One call in cents, to a tenth: "1.2¢"; nothing spent reads "free".
    static func cents(_ nano: Int64) -> String {
        guard nano > 0 else { return "free" }
        return String(format: "%.1f¢", (Double(nano) / 1_000_000).rounded(.up) / 10)
    }
}

/// Removing the key: it is deleted from the Keychain at once and held nowhere, so no Claude job can find it and
/// nothing can bring it back. Nothing here logs or shows any part of it.
enum KeyRemoval {
    static func remove(from keys: any TessKeychain) {
        keys.delete()
    }
}
