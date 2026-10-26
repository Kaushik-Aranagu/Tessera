import SwiftUI

extension EnvironmentValues {
    /// Draws a room's own keystone (`SlotPayload.scene`) by key. Each room's shell host sets it; the default draws
    /// nothing.
    @Entry var shellScene: @MainActor (String) -> AnyView = { _ in AnyView(EmptyView()) }
    /// The page behind the shell's places; nil keeps the theme's page.
    @Entry var shellBackdrop: AnyView?
    /// The glyph library the shell's glyph place draws from (a room only draws its own drawings); nil: all of them.
    @Entry var shellGlyphRoom: GlyphKind.Room?
}

/// Any room's content behind one type, so the shell can hold a room chosen at run time.
struct AnyRoomContent: RoomContent {
    let base: any RoomContent

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        base.screen(for: route, state: state)
    }
}

/// The rooms the standing shell can open, by room id (a `ShellRoute.room`). Each entry is the room's host: a view
/// that loads the room's facts, builds its `RoomContent`, sets its keystone drawing, door-summary style and backdrop,
/// and answers its intents. Home wires its doors to `host(for:)`.
@MainActor
enum ShellRooms {
    struct Entry {
        let id: String
        let host: @MainActor () -> AnyView
    }

    static var all: [Entry] {
        [
            Entry(id: NotesRoomContent.room) { AnyView(NotesShellHost()) },
            Entry(id: DeckRoomContent.room) { AnyView(DeckShellHost()) },
            Entry(id: SettingsRoomContent.room) { AnyView(SettingsShellHost()) },
            Entry(id: WatchRoomContent.room) { AnyView(WatchShellHost()) },
            Entry(id: LookoutRoomContent.room) { AnyView(LookoutShellHost()) },
            Entry(id: GalleyRoomContent.room) { AnyView(GalleyShellHost()) },
            Entry(id: PurseRoomContent.room) { AnyView(PurseShellHost()) },
        ]
    }

    static var ids: [String] {
        all.map(\.id)
    }

    static func host(for room: String) -> AnyView? {
        all.first { $0.id == room }?.host()
    }
}

#if DEBUG
    extension ShellNavigator {
        /// `-shellDoor <door>` (simulator only, LaunchFlags): opens that door of `room` 2 s after launch and, with
        /// `-shellBack`, comes back 3 s later, so stills and recordings catch the merge and the split.
        func walkForStills(room: String) async {
            guard let door = LaunchFlags.value(after: "-shellDoor") else { return }
            try? await Task.sleep(for: .seconds(2))
            push(.door(room, door))
            guard LaunchFlags.has("-shellBack") else { return }
            try? await Task.sleep(for: .seconds(3))
            pop()
        }
    }
#endif
