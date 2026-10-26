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
        /// The room as the root shell holds it beside Bridge (`ShellRoomDriver`); nil keeps the room on its own page
        /// when it is opened from Bridge.
        var driver: (@MainActor () -> any ShellRoomDriver)?

        init(id: String, driver: (@MainActor () -> any ShellRoomDriver)? = nil,
             host: @escaping @MainActor () -> AnyView)
        {
            self.id = id
            self.driver = driver
            self.host = host
        }
    }

    static var all: [Entry] {
        [
            Entry(id: NotesRoomContent.room, driver: { NotesRoomDriver() }) { AnyView(NotesShellHost()) },
        ]
    }

    /// One driver per room that has one, for the root shell.
    static func drivers() -> [String: any ShellRoomDriver] {
        var drivers: [String: any ShellRoomDriver] = [:]
        for entry in all {
            if let make = entry.driver {
                drivers[entry.id] = make()
            }
        }
        return drivers
    }

    static var ids: [String] {
        all.map(\.id)
    }

    static func host(for room: String) -> AnyView? {
        all.first { $0.id == room }?.host()
    }
}
