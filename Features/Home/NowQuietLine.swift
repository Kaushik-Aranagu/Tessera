import SwiftUI
import TesseraCore

/// The quiet lines Now can carry under the day word. Only one shows at a time, never stacked (hunt 28 CALL 3 B,
/// reinstall spec CALL 5): the found-key question first, the restore offer second, the signing lapse last. The next
/// one takes the place only when the one before is answered or gone.
enum NowQuietLine: Int, Comparable, CaseIterable {
    case keyQuestion
    case restoreOffer
    case signingLapse

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The one line to show from those that are due.
    static func pick(_ due: Set<Self>) -> Self? {
        due.min()
    }
}

/// Hosts the one quiet line on Now. Each line is Tess's voice, plain ink words, no card, no sheet, no alert; it fades
/// through MotionPolicy (150 ms crossfade under Reduce Motion or Low Power).
struct NowQuietLines: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openHomeLink) private var openLink
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    @State private var offer: RestoreOffer.Offer?
    /// Once the store holds his actions the offer can never come back this run: stop checking.
    @State private var offerSettled = false
    @State private var lapse: String?
    /// The copy's warning is showing: Restore turned into "Replace what is here" (sheet 111's two-step).
    @State private var confirming = false
    /// Tess's one line after the offer: staged, refused or not staged.
    @State private var receipt: String?
    @State private var restored = 0
    @State private var receiptHold: Task<Void, Never>?

    var body: some View {
        let keyDue = model.keyQuestionDue && !model.keyQuestionQuietOnNow
        let due = Set<NowQuietLine>([
            keyDue ? .keyQuestion : nil,
            offer != nil ? .restoreOffer : nil,
            lapse != nil ? .signingLapse : nil,
        ].compactMap(\.self))

        Group {
            if let receipt {
                voice(receipt)
            } else {
                switch NowQuietLine.pick(due) {
                case .keyQuestion:
                    ClaudeKeyQuestionNowLine {
                        // Shown once this launch: the three words wait in Claude's section.
                        model.keyQuestionQuietOnNow = true
                        openLink(.review)
                    }
                case .restoreOffer:
                    if let offer {
                        offerLine(offer)
                    }
                case .signingLapse:
                    if let lapse {
                        voice(lapse)
                    }
                case nil:
                    EmptyView()
                }
            }
        }
        .padding(.bottom, due.isEmpty && receipt == nil ? 0 : Theme.Spacing.xl)
        .transition(.opacity)
        .tesseraAnimation(value: due)
        .tesseraAnimation(value: confirming)
        .tesseraFeedback(.made, trigger: restored)
        .task(id: model.revision) { refresh() }
    }

    // MARK: The restore offer

    @ViewBuilder
    private func offerLine(_ offer: RestoreOffer.Offer) -> some View {
        switch offer {
        case let .copy(url, createdAt):
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                voice(confirming ? RestoreOfferCopy.confirm(createdAt) : RestoreOfferCopy.offer(createdAt))
                if confirming {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        ForEach([RestoreOfferCopy.inIt, RestoreOfferCopy.notInIt, RestoreOfferCopy.walled],
                                id: \.self)
                        { line in
                            Text(line)
                                .textRole(.label)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .transition(.opacity)
                }
                words {
                    // Plain ink, no cobalt: the only word here that can lose data, so it takes one more tap
                    // (sheet 111). No haptic on the first tap; one when the restore is staged.
                    Button(confirming ? RestoreOfferCopy.replace : RestoreOfferCopy.restore) {
                        if confirming {
                            stage(url, createdAt: createdAt)
                        } else {
                            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { confirming = true }
                        }
                    }
                    .buttonStyle(.labelWord(Theme.Colors.ink, silent: true))
                    .accessibilityLabel(confirming ? RestoreOfferCopy.replaceLabel : RestoreOfferCopy.restore)
                    Button(RestoreOfferCopy.notNow, action: notNow)
                        .buttonStyle(.labelWord)
                }
            }
            .accessibilityElement(children: .contain)
        case .backups:
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Button {
                    // The line has done its work: Backups keeps Restore (CALL 4 A).
                    RestoreOffer.dismiss()
                    openLink(.review)
                } label: {
                    Text(RestoreOfferCopy.backups)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityHint(RestoreOfferCopy.backupsHint)
                Button(RestoreOfferCopy.notNow, action: notNow)
                    .buttonStyle(.labelWord)
            }
        }
    }

    /// The words sit side by side, and stack one per row at accessibility sizes (sheet 111).
    private func words(@ViewBuilder _ content: () -> some View) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.l))
        return layout { content() }
    }

    private func voice(_ text: String) -> some View {
        Text(text)
            .font(Theme.voice)
            .foregroundStyle(Theme.Colors.tess)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44, alignment: .leading)
    }

    private func notNow() {
        RestoreOffer.dismiss()
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            confirming = false
            offer = nil
        }
    }

    /// Stages the copy for the next cold launch (Core applies it then). Refused while a workout or a cook runs.
    private func stage(_ url: URL, createdAt: Date) {
        if let running = runningName() {
            say(RestoreOfferCopy.waits(for: running))
            return
        }
        do {
            _ = try TesseraBackup.stageRestore(from: url)
            RestoreOffer.rememberStaged(createdAt)
            RestoreOffer.dismiss()
            restored += 1
            say(RestoreOfferCopy.staged)
        } catch TesseraBackup.BackupError.newerSchema {
            say(RestoreOfferCopy.newer)
        } catch TesseraBackup.BackupError.damaged {
            say(RestoreOfferCopy.unreadable)
        } catch {
            say(RestoreOfferCopy.notStaged)
        }
    }

    private func say(_ text: String) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            confirming = false
            offer = nil
            receipt = text
        }
        // The house hold: 4 s, 10 s under VoiceOver; then the line goes.
        receiptHold?.cancel()
        receiptHold = Task { @MainActor in
            try? await Task.sleep(for: .seconds(voiceOver ? 10 : 4))
            guard !Task.isCancelled else { return }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { receipt = nil }
            refresh()
        }
    }

    /// What's running, as shown elsewhere (a private workout reads "Private workout"), or nil.
    private func runningName() -> String? {
        if let session = model.session {
            return ObjectPrivacy.routineTitle(session.workout.title, in: model.store)
        }
        return model.processes.running().map {
            LedgerRow.shown($0, store: model.store, classes: model.classes,
                            lastWeightKg: BodyWeight.lastKg(in: model.store)).title
        }
    }

    // MARK: Checks

    private func refresh() {
        let now = AppClock.now
        lapse = SigningLapse.warning(expiry: SigningLapse.expiry(now: now), now: now)
        guard !offerSettled, receipt == nil else { return }
        let fresh = !AppModel.isDemo && model.settingsAreReal && TesseraBackup.offersRestore(
            in: model.context,
            folderPicked: BackupKeeper.pickedFolder != nil,
            restoreStaged: FileManager.default.fileExists(
                atPath: TesseraBackup.pendingURL(for: TesseraSchema.defaultURL).path
            ),
            dismissed: RestoreOffer.isDismissed
        )
        guard fresh else {
            offerSettled = true
            if offer != nil {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { offer = nil }
            }
            return
        }
        let busy = model.session != nil || model.processes.running() != nil
        let born = model.context.all(OpRecord.self).map(\.createdAt).min()
        let next = RestoreOffer.offer(fresh: true, busy: busy, copies: RestoreOffer.localCopies(), storeBornAt: born)
        if next != offer {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { offer = next }
        }
    }
}
