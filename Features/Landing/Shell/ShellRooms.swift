import SwiftUI

extension EnvironmentValues {
    /// Draws a room's own keystone (`SlotPayload.scene`) by key. Each room's shell host sets it; the default draws
    /// nothing.
    @Entry var shellScene: @MainActor (String) -> AnyView = { _ in AnyView(EmptyView()) }
    /// The page behind the shell's places; nil keeps the theme's page.
    @Entry var shellBackdrop: AnyView?
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
        ]
    }

    static var ids: [String] {
        all.map(\.id)
    }

    static func host(for room: String) -> AnyView? {
        all.first { $0.id == room }?.host()
    }
}
