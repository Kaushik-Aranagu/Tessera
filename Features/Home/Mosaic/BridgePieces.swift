import SwiftUI
import TesseraCore

// Bridge's parts, each drawn at its own place's origin (sheet 283 v4). `HomeMosaicPage` positions them at the sheet's
// fixed points; the standing shell hands each to its place. All of them read one `BridgeStage`.

/// The departure board in its masthead place (140, 74, 238 x 104). Its rows ride 8 pt above the place and may run
/// 18 pt past it, as on the page.
struct BridgeBoard: View {
    @Bindable var stage: BridgeStage
    @Environment(AppModel.self) private var model

    var body: some View {
        MosaicSentence(pickedClauses: stage.momentClause.map { [$0] }, dayClauses: stage.dayClauses,
                       onDoor: { clause, frame in
                           stage.doorwayFrom(frame) {
                               DaySentence.open(clause, model: model, openLink: { stage.present($0) })
                           }
                       },
                       noticeList: stage.notices,
                       onRoom: { app, frame in
                           stage.doorwayFrom(frame) { stage.openRoomWord(app) }
                       },
                       onSky: { stage.playDusk() },
                       facts: stage.facts,
                       paused: !stage.active || stage.link != nil,
                       onAnnouncement: { stage.announce($0) })
            // Until the first refresh has read Core's loaders the sentence waits (no flicker between the fallback and
            // the real lines).
            .opacity(stage.dayClauses == nil ? 0 : 1)
            .accessibilityHidden(stage.dayClauses == nil)
            .mosaicShield()
            .frame(width: BridgePlace.board.width, alignment: .topTrailing)
            .frame(maxHeight: BridgePlace.board.height + 18, alignment: .top)
            .offset(y: -8)
            // The board's rows are fixed 30 pt flaps: its type stops at xLarge so rows never overlap at AX5.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

/// The Settings word in its place (24, 74, 110 x 44), level with the board's date line.
struct BridgeSettingsWord: View {
    let stage: BridgeStage

    var body: some View {
        SettingsEntry { stage.openSettings() }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .frame(height: BridgePlace.settings.height)
            .offset(x: -8)
    }
}

/// The mosaic's place in the keystone band: the 160 pt core centred in the 182 pt band. With the moods on, the core
/// only reserves its frame (the field behind draws the pixels) and owns the face swipe and tap.
struct BridgeMosaicCore: View {
    @Bindable var stage: BridgeStage

    var body: some View {
        MosaicSlot(coreTop: $stage.coreTop, facts: stage.facts, scene: $stage.scene, caption: $stage.caption,
                   faces: stage.faces)
            .frame(width: BridgePlace.keystone.width)
            .padding(.top, BridgePlace.coreTop - BridgePlace.keystone.minY)
    }
}

/// The one-thing box in the widget place (24, 412, 354 x 200), one thing at a time.
struct BridgeOneThing: View {
    @Bindable var stage: BridgeStage

    var body: some View {
        HomeOneThing(things: stage.things, index: $stage.thingIndex, turn: { stage.turnThing($0) },
                     done: { stage.finishThing($0) }, open: { stage.openThing($0) }, onSlot: { stage.signSlot = $0 })
            .frame(width: BridgePlace.widget.width, height: BridgePlace.widget.height)
            .mosaicShield()
    }
}

/// The apps dial in the doors place (24, 640, 354 x 120: the dial and its fact column).
struct BridgeApps: View {
    let stage: BridgeStage

    var body: some View {
        if HomeMosaic.appsListIsOn {
            AppsListSlot(onHold: { stage.wheelHeld = $0 }, onGlance: { stage.playGlance($0) })
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .frame(width: BridgePlace.doors.width, height: BridgePlace.doors.height, alignment: .top)
                .mosaicShield()
        }
    }
}

/// The mosaic itself: the screen's own pixels, edge to edge, behind every place (sheet 202).
struct BridgeField: View {
    @Bindable var stage: BridgeStage

    var body: some View {
        if stage.layerOn, let facts = stage.facts, let mood = stage.pick?.mood {
            HomeLayerHost(
                scroll: stage.scroll,
                // Bridge has no scroll and its places are measured in the page's own space, whose origin is the
                // screen's top (sheet 283 fixed places).
                scrollMinY: 0,
                facts: facts,
                scene: $stage.scene,
                controller: stage.controller,
                // The core sits where it does at rest, in whole tiles.
                coreTop: (stage.coreTop / 4).rounded() * 4,
                shield: stage.shield,
                mood: mood,
                moment: stage.moment,
                caption: $stage.caption,
                page: MosaicPage(rawValue: stage.pager.index) ?? .mood,
                pageDirection: stage.pageDirection,
                signSpec: stage.signSpec,
                scenery: stage.scenery,
                dusk: stage.dusk,
                faceModel: stage.faces
            )
        }
    }
}

/// Tess on her own layer above all of Bridge; touches pass through except on her. Her conversation opens over Home,
/// and she moves to the bottom middle (sheets 209 and 215).
struct BridgeTess: View {
    @Bindable var stage: BridgeStage
    @Environment(AppModel.self) private var model

    var body: some View {
        if stage.layerOn, HomeMosaic.appsListIsOn {
            ZStack {
                if stage.roomOpen {
                    TessRoom(entries: stage.roomEntries, watching: "Watching today.", undo: { entry in
                        switch TessRoomLog.undo(entry, engine: model.engine) {
                        case let .putBack(line): line
                        default: nil
                        }
                    }, close: { stage.roomOpen = false })
                        .transition(.identity)
                }
                if stage.tessOpen {
                    TessConversationLayer(model: stage.tessModel, close: { stage.closeTess() },
                                          answer: { stage.tessAnswer($0) }, send: { stage.tessHeard($0) })
                }
                TessLayer(
                    thoughts: TessThoughts.lines(facts: stage.facts, asksClaude: model.asksClaude),
                    onTap: { stage.tessTapped() },
                    open: stage.tessOpen,
                    holding: stage.tessHolding,
                    voice: stage.tessVoice,
                    heardAt: stage.tessHeardAt,
                    quiet: stage.tessModel.isQuiet(),
                    onHold: { stage.holdBegan() },
                    onHoldEnd: { stage.holdEnded(cancelled: $0) },
                    onDoubleTap: { stage.tessQuiet() },
                    onSwipeUp: { stage.openRoom() }
                )
            }
            .onChange(of: stage.listener.heard) { _, words in
                stage.tessModel.liveSpeech = words
                stage.tessHeardAt = Date()
            }
            .onChange(of: stage.listener.level) { _, level in
                stage.tessVoice = stage.tessHolding ? level : 0
            }
        }
    }
}

/// Bridge's life: the minute refresh, the faces' clock, coming and going, the haptic beats, the shields, the
/// touch feed and the pull down for Settings. Put on whatever draws Bridge (the page, or the shell).
struct BridgeLife: ViewModifier {
    let stage: BridgeStage
    /// Whether Bridge is the screen showing (in the shell, false while a room holds the places).
    var showing = true
    /// The standing shell draws Tess itself in its rooms, so the app's own corner Tess stays away.
    var tessElsewhere = false

    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let _ = wire()
        content
            .onPreferenceChange(MosaicShieldKey.self) { stage.shield = $0 }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { stage.pageWidth = $0 }
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { stage.scrollMinY = $0 }
            .onChange(of: scenePhase, initial: true) { old, phase in
                if old == phase {
                    stage.scenePhase = phase
                } else {
                    stage.phaseChanged(phase)
                }
            }
            .mosaicTouchFeed(stage.controller, enabled: stage.layerOn && showing)
            // Sheet 215: Home sits under her blur (hers alone) while her layer is open.
            .tessBackdrop(open: stage.tessOpen)
            // Live only when seen: her layer, a full-screen link or a room in the shell hides Bridge.
            .liveScope(!stage.tessOpen && stage.link == nil && showing)
            .onChange(of: stage.layerOn && showing, initial: true) { _, on in
                model.homeTessLayerActive = tessElsewhere || (on && HomeMosaic.appsListIsOn)
            }
            .onDisappear { model.homeTessLayerActive = false }
            // Sheet 203: a pull down from the top 40 pt also opens Settings.
            .simultaneousGesture(
                DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart)).onEnded { value in
                    if showing, value.startLocation.y < 40,
                       GestureTuning.pull(dx: Double(value.translation.width), dy: Double(value.translation.height),
                                          velocityY: Double(value.velocity.height)) > 0
                    {
                        stage.openSettings()
                    }
                }
            )
            .task(id: Int(AppClock.now.timeIntervalSince1970 / 60) &+ model.revision) { stage.refreshPick() }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    stage.tickFaces()
                }
            }
            .task(id: stage.faces.faces.count > 1) {
                // The next face leans in once, so the swipe is found.
                guard stage.faces.faces.count > 1, !reduceMotion else { return }
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                stage.faces.peekOnce()
            }
            .onChange(of: showing, initial: true) { _, on in
                stage.onScreen = on
                if !on {
                    stage.endMoment()
                }
            }
            .onAppear { openLaunchLink() }
            .onDisappear {
                stage.onScreen = false
                stage.endMoment()
            }
            // A mood change cancels the moment, and the sentence turns back with it.
            .onChange(of: stage.pick?.mood) { _, _ in stage.endMoment() }
            .tesseraFeedback(.made, trigger: stage.softBeats)
            .tesseraFeedback(.selection, trigger: stage.tickBeats)
            .tesseraFeedback(.setLogged, trigger: stage.rigidBeats)
            .environment(\.openHomeLink) { stage.present($0) }
            .environment(\.playDoorway) { accent, reverse, navigate in
                model.doorway.play(from: stage.doorwayOrigin ?? stage.mosaicCentre, accent: accent, reverse: reverse,
                                   reduceMotion: reduceMotion, navigate: { BridgeStage.withoutAnimation(navigate) })
                stage.doorwayOrigin = nil
            }
    }

    @MainActor private static var openedLaunchLink = false

    /// `-openLink pantry|recipes|notes|...` opens that screen once per launch (simulator only, for UI tests): in the
    /// standing shell when it holds the room, else on its own page.
    private func openLaunchLink() {
        #if DEBUG
            guard !Self.openedLaunchLink, let value = LaunchFlags.value(after: "-openLink"),
                  let target = HomeLink.allCases.first(where: { value == "\($0)" }) else { return }
            Self.openedLaunchLink = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                if stage.openInShell?(target) != true {
                    stage.link = target
                }
            }
        #endif
    }

    private func wire() {
        if stage.model !== model {
            stage.model = model
        }
        stage.reduceMotion = reduceMotion
    }
}

/// The rooms Bridge opens on their own pages (the doorway, then a full-screen page), for any room the standing
/// shell does not hold yet.
struct BridgeDoors: ViewModifier {
    @Bindable var stage: BridgeStage

    func body(content: Content) -> some View {
        content
            // A room word for a room with a landing (Galley) opens its landing as a door, with Tess in the room's
            // colour.
            .fullScreenCover(item: $stage.roomDoor) { door in
                HomeV2DoorPage(door: door)
                    .overlay(alignment: .bottomTrailing) {
                        BottomChrome(onSoulDoubleTap: { stage.roomDoor = nil }, room: door.roomID)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .overlay(alignment: .leading) { edge { stage.roomDoor = nil } }
                    .accessibilityAction(.escape) { stage.roomDoor = nil }
            }
            .fullScreenCover(item: $stage.link) { link in
                // Settings and Today have no Close word of their own; a room has Close at the top right.
                Group {
                    if link == .settings || link == .today {
                        link.destination
                    } else {
                        link.destination
                            .safeAreaInset(edge: .top, spacing: 0) {
                                HStack {
                                    Spacer()
                                    Button("Close") { stage.dismissLink() }
                                        .buttonStyle(InkLabelWordStyle())
                                }
                                .padding(.horizontal, Theme.Spacing.gutter - 8)
                            }
                            // Sheet 283: Tess bottom right on every room landing too; her double tap goes back.
                            .overlay(alignment: .bottomTrailing) {
                                if LandingSwitch.isOn {
                                    BottomChrome(onSoulDoubleTap: { stage.dismissLink() }, room: link.roomID)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                }
                            }
                    }
                }
                // The edge swipe back runs the doorway in reverse, into the mosaic (no "‹ Home" word on a room).
                .overlay(alignment: .leading) { edge { stage.dismissLink() } }
            }
    }

    private func edge(_ back: @escaping () -> Void) -> some View {
        Color.clear
            .frame(width: 20)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 12).onEnded { value in
                if value.translation.width > 60, abs(value.translation.height) < value.translation.width {
                    back()
                }
            })
            .accessibilityHidden(true)
    }
}

extension BridgeStage {
    /// The Settings word, the pull down and the dial's Settings row: the shell holds Settings when it can.
    func openSettings() {
        if openInShell?(.settings) == true {
            return
        }
        link = .settings
    }
}
