import SwiftUI

/// Bridge as content for the standing shell (sheet 283 v4/v5). Bridge draws its own parts, so every place holds a
/// scene key the host renders from `BridgeStage`: the Settings word in the Title's place, the departure board in the
/// Switcher's, the mosaic in the keystone, the one-thing box in the widget, the apps dial across the doors band and
/// the undo line at the foot. The Nav word, Caption and Glyph are kept and empty; Tess is her own layer.
struct BridgeRoomContent: RoomContent {
    static let room = "bridge"

    enum Key {
        static let settings = "bridge.settings"
        static let board = "bridge.board"
        static let mosaic = "bridge.mosaic"
        static let oneThing = "bridge.oneThing"
        static let apps = "bridge.apps"
        static let undo = "bridge.undo"
    }

    func screen(for _: ShellRoute, state _: RoomState) -> Screen {
        Screen(layout: .bridge, slots: [
            .title: Self.scene(Key.settings, "Settings"),
            .navWord: nil,
            .switcher: Self.scene(Key.board, "The day"),
            .keystone: Self.scene(Key.mosaic, "The mosaic"),
            .caption: nil,
            .widget: Self.scene(Key.oneThing, "The one thing"),
            .glyph: nil,
            .dial: Self.scene(Key.apps, "The apps"),
            .actionWord: Self.scene(Key.undo, "Undo"),
            .tess: nil,
        ])
    }

    private static func scene(_ key: String, _ label: String) -> SlotContent {
        SlotContent(id: ContentID(key), kind: .scene, payload: .scene(key, label: label))
    }

    /// Draws one of Bridge's places from its stage.
    @MainActor @ViewBuilder
    static func draw(_ key: String, stage: BridgeStage) -> some View {
        switch key {
        case Key.settings: BridgeSettingsWord(stage: stage)
        case Key.board: BridgeBoard(stage: stage)
        case Key.mosaic: BridgeMosaicCore(stage: stage)
        case Key.oneThing: BridgeOneThing(stage: stage)
        case Key.apps: BridgeApps(stage: stage)
        case Key.undo: UndoFootLine()
        default: EmptyView()
        }
    }
}
