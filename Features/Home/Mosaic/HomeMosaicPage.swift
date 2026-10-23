import SwiftUI
import TesseraCore

/// Home as a mosaic (sheet 199, Builder B's part): the date and a Settings word, three right-aligned lines about the
/// day, the mosaic with its caption, then Next. Nothing else: no write line, mic, widgets, ring or bars. Used in
/// place of Home when Settings › Review › "Mosaic" is On.
struct HomeMosaicPage: View {
    /// The page's own coordinate space, so a finished row's frame can be handed to the mosaic.
    static let space = "homeMosaicPage"

    @Environment(AppModel.self) private var model
    @State private var link: HomeLink?
    /// Set by the mosaic when it is on the page: lays a finished row's colour into the picture.
    @State private var mosaicLay: ((CGRect) -> Void)?
    /// The mosaic's one caption line.
    @State private var caption = ""
    /// Sheet 200: Tess's pick (mood, its three lines) and the facts it read, refreshed each minute and on a change.
    @State private var pick: MosaicPick?
    @State private var facts: MosaicFacts?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeMosaic.sectionGap) {
                header
                    // Moods: 64 pt from the safe area to the sentence in all, so the row's gap is what is left.
                    .padding(.bottom, HomeMosaic.moodsIsOn
                        ? HomeMosaic.moodsTopInset - HomeMosaic.headerHeight - HomeMosaic.sectionGap : 0)
                MosaicSentence(pickedLines: pick?.lines)
                VStack(alignment: .leading, spacing: 0) {
                    MosaicSlot(lay: $mosaicLay, caption: $caption, facts: facts, mood: pick?.mood)
                        .padding(.top, HomeMosaic.moodsIsOn ? HomeMosaic.moodsMosaicGap - HomeMosaic.sectionGap : 0)
                    if !caption.isEmpty {
                        Text(caption)
                            .font(Theme.voice(size: 16))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.s)
                    }
                }
                // The call site that becomes `mosaic.lay(from: rowFrame, tone: .glaze)` with A's view.
                MosaicNextList { rowFrame in mosaicLay?(rowFrame) }
                if HomeMosaic.appsListIsOn {
                    AppsListSlot()
                }
            }
            .padding(.horizontal, HomeMosaic.gutter)
            .padding(.top, HomeMosaic.moodsIsOn ? 0 : Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.xl)
            .coordinateSpace(.named(Self.space))
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .task(id: Int(AppClock.now.timeIntervalSince1970 / 60) &+ model.revision) { refreshPick() }
        .environment(\.openHomeLink) { link = $0 }
        .fullScreenCover(item: $link) { link in
            link.destination
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Close") { self.link = nil }
                            .buttonStyle(InkLabelWordStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.gutter - 8)
                }
        }
    }

    private static let backShownKey = "homeMosaic.backShown"

    /// Asks Core's picker what the day looks like now; "Welcome back" shows once per absence.
    private func refreshPick() {
        guard HomeMosaic.moodsIsOn else {
            pick = nil
            return
        }
        let now = AppClock.now
        let read = MosaicFacts.make(engine: model.engine, now: now)
        let defaults = UserDefaults.standard
        let inputs = MosaicMoodInputs.make(engine: model.engine, facts: read, plan: model.plan,
                                           backShown: defaults.bool(forKey: Self.backShownKey),
                                           previous: pick.map { ($0.mood, $0.since) })
        let next = MosaicMoodPicker.pick(inputs)
        if next.mood == .back, !model.isSample {
            defaults.set(true, forKey: Self.backShownKey)
        }
        facts = read
        if next != pick {
            pick = next
        }
    }

    /// The date at the left, the Settings word at the right (a 44 pt target).
    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            Text(AppClock.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(Theme.voice(size: 16))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            SettingsKnob()
            Button { link = .settings } label: {
                Text("Settings")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens Settings")
        }
    }
}
