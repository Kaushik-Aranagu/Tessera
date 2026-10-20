import SwiftUI
import TesseraCore

/// What Tess knows (ship list AI-9, docs/ai/what-tess-knows.md, Design 49): every line she keeps about him, in his
/// areas, each with where it came from. Swipe a line left to forget it, with the 10 s UNDO; hold FORGET EVERYTHING to
/// forget them all, one UNDO for the lot. Nothing on this page sends anything anywhere, and after the UNDO window
/// Core scrubs a forgotten line's words from history.
struct TessKnowsPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    private var memory: TessMemoryStore {
        TessMemoryStore(engine: model.engine)
    }

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let groups = memory.grouped()
        let told = memory.lines(of: .told).count
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ Settings")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Settings")
                }
                Text("kept on this phone")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text("What Tess knows")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)
                Text(memory.countLine())
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(2)

                if groups.isEmpty {
                    Text(TessKnowsCopy.empty)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.xl)
                        .entrance(3)
                } else {
                    if told >= TessMemory.toldCap {
                        Text(TessMemory.capLine)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.tess)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, Theme.Spacing.l)
                    }
                    ForEach(Array(groups.enumerated()), id: \.element.area) { index, group in
                        MarginSection(label: group.area.word) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(group.lines.enumerated()), id: \.element.id) { offset, line in
                                    row(line, now: now)
                                    if offset < group.lines.count - 1 {
                                        RowSeparator()
                                    }
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(3 + min(index, 2))
                    }

                    PaintKey(paint: Theme.Colors.ink, duration: 0.7, hint: TessKnowsCopy.forgetAllHint,
                             action: forgetAll, label: { _ in
                                 Text(TessKnowsCopy.forgetAll).textRole(.labelStrong)
                             })
                             .accessibilityLabel(TessKnowsCopy.forgetAll)
                             .accessibilityAction(named: Text(TessKnowsCopy.forgetAll), forgetAll)
                             .padding(.top, Theme.Spacing.section)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
        // Leaving ends the page's part in the window; Core scrubs anything forgotten more than 10 s ago.
        .onDisappear { _ = memory.sweepForgotten(now: AppClock.now) }
    }

    private func row(_ line: TessMemory, now: Date) -> some View {
        let source = TessKnowsCopy.source(line, now: now)
        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(line.text)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(source)
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, Theme.Spacing.m)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .swipeToRemove(word: TessKnowsCopy.forget) { forget(line) }
    }

    private func forget(_ line: TessMemory) -> Bool {
        guard let result = try? model.engine.perform(ForgetMemory(memory: line.id), by: .user) else { return false }
        withTesseraAnimation(reduceMotion: reduceMotion) { model.touch() }
        let receipt = result.record.receipt ?? result.record.summary
        TessVoice.shared.say(receipt, undo: result.record)
        AccessibilityNotification.Announcement(receipt).post()
        return true
    }

    private func forgetAll() {
        guard let result = try? model.engine.perform(ForgetAllMemory(), by: .user) else { return }
        withTesseraAnimation(reduceMotion: reduceMotion) { model.touch() }
        let receipt = result.record.receipt ?? result.record.summary
        TessVoice.shared.say(receipt, undo: result.record)
        AccessibilityNotification.Announcement(receipt).post()
    }
}

/// What Tess knows' words (what-tess-knows.md section 4).
enum TessKnowsCopy {
    static let empty = "Say \u{201C}remember that\u{201D} and I'll keep it here."
    static let forget = "Forget"
    static let forgetAll = "Forget everything"
    static let forgetAllHint = "Hold to forget every line. You can undo it."

    /// The source line; Core ends a private one ", stays on this phone" (words only: no lock, no dot, no colour).
    static func source(_ line: TessMemory, now: Date) -> String {
        line.sourceLine(now: now)
    }

    /// Settings' door, third person, in ink: "Tess remembers 12 things." or "Tess remembers nothing yet."
    static func door(_ countWord: String) -> String {
        countWord == "Nothing yet" ? "Tess remembers nothing yet." : "Tess remembers \(countWord)."
    }
}
