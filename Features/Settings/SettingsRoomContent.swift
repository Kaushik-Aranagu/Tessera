import SwiftUI
import TesseraCore

/// Settings as content for the standing shell (sheet 283 v5): level 0 is the landing, the same content as
/// `SettingsLandingPage` (both read `SettingsLandingFacts` and `SettingsLandingWords`); level 1 is a door page: the
/// Door title and a Page of that door's lines with a row that opens the setting's own page. No action word. Nothing
/// here changes a setting, reads the Claude key (only whether Tess asks Claude) or touches a backup. Pure: no views,
/// no store reads.
struct SettingsRoomContent: RoomContent {
    static let room = "settings"
    static let title = "Settings"
    static let wallLabel = "Setting areas"
    static let caption = ["Tap an area to open it", "Tap an area"]
    static let firstDoor = SettingsArea.tess.rawValue

    struct Facts: Equatable {
        var settings: SettingsLandingFacts
        var seen: [String: Date] = [:]
        var colors: SettingsLandingWords.Colors
    }

    let facts: Facts
    var accent: Color = Theme.Colors.ink

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(route.door ?? Self.firstDoor)
    }

    var doors: [DialDoor] {
        SettingsLandingWords.doors(facts.settings, colors: facts.colors)
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let cards = SettingsLandingWords.cards(facts.settings)
        let item = cards.indices.contains(state.widgetIndex) ? cards[state.widgetIndex] : cards.first
        let doors = doors
        let focused = doors.isEmpty ? nil : doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
        let index = SettingsLandingWords.switcher.indices.contains(state.switcherIndex) ? state.switcherIndex : 0
        let needs = SettingsLandingWords.needs(facts.settings, switcher: index, opened: facts.seen)
        return Screen(layout: .landing, slots: [
            .title: title,
            .navWord: SlotContent(id: "settings.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "settings.switcher", kind: .switcher,
                                   payload: .switcher(across: SettingsLandingWords.switcher, vertical: [])),
            .needs: needs.isEmpty ? nil
                : SlotContent(id: ContentID("settings.needs.\(index)"), kind: .text, payload: .lines(needs)),
            .keystone: keystone,
            .caption: caption,
            .widget: cards.isEmpty ? nil : SlotContent(id: "settings.widget", kind: .widget, payload: .widget(cards)),
            .glyph: item.map { SlotContent(id: ContentID("settings.glyph.\($0.id)"), kind: .glyph,
                                           payload: .glyph($0, color: $0.bigColor ?? accent)) },
            .dial: doors.isEmpty ? nil : SlotContent(id: "settings.dial", kind: .dial, payload: .dial(doors)),
            .doorSummary: focused.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : SlotContent(id: ContentID("settings.summary.\(door.id)"), kind: .summary,
                                  payload: .summary(door))
            },
            .actionWord: nil,
            .tess: nil,
        ])
    }

    // MARK: Level 1

    private func door(_ id: String) -> Screen {
        let door = doors.first { $0.id == id }
        let area = SettingsArea(rawValue: id) ?? .tess
        return Screen(layout: .door, slots: [
            .title: title,
            .navWord: SlotContent(id: "settings.nav.settings", kind: .text, payload: .navWord(Self.title)),
            .doorTitle: SlotContent(id: ContentID("settings.door.\(id).title"), kind: .text,
                                    payload: .doorTitle(name: area.title, line: door?.label ?? door?.lines.first ?? "",
                                                        color: door?.color ?? accent)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("settings.door.\(id).page"), kind: .list,
                               payload: .list(Self.rows(door: door, area: area))),
            .actionWord: nil,
            .tess: nil,
        ])
    }

    /// A door's page: its own lines (facts only), then the row that opens the setting's page.
    static func rows(door: DialDoor?, area: SettingsArea) -> [ShellRow] {
        let lines = (door?.lines ?? []).enumerated().map { index, line in
            ShellRow(id: "line#\(index)", title: line)
        }
        return lines + [ShellRow(id: "open:\(area.rawValue)", title: "Open \(area.title)",
                                 detail: "The whole page")]
    }

    // MARK: Shared by both levels (same ids: the keystone, title and caption are not touched)

    private var title: SlotContent {
        SlotContent(id: "settings.title", kind: .text, payload: .title(Self.title, accent: accent))
    }

    private var keystone: SlotContent {
        SlotContent(id: "settings.wall", kind: .wall,
                    payload: .wall(SettingsLandingWords.wall(opened: facts.seen), label: Self.wallLabel))
    }

    private var caption: SlotContent {
        SlotContent(id: "settings.caption", kind: .text, payload: .lines(Self.caption))
    }

    /// The area a tapped wall word, widget item or page row opens; nil for a plain fact line.
    static func area(for id: String) -> SettingsArea? {
        SettingsArea(rawValue: id.hasPrefix("open:") ? String(id.dropFirst(5)) : id)
    }
}

extension SettingsRoomContent.Facts {
    @MainActor
    static func load(model: AppModel, scheme: ColorScheme, realModel: AppModel? = nil,
                     backupLine: String? = nil) -> Self
    {
        Self(settings: .read(model: model, realModel: realModel, backupLine: backupLine),
             seen: SettingsAreaSeen.all(), colors: SettingsLandingWords.colors(scheme))
    }
}

/// Settings opened through the standing shell (`-shellRoom settings` on the simulator, and Home through
/// `ShellRooms`). A door pushes its page; a word, item or the page's last row opens the setting's own page; back pops.
struct SettingsShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.realModel) private var realModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var navigator = ShellNavigator(root: .landing(SettingsRoomContent.room))
    @State private var area: SettingsArea?
    @State private var backupLine: String?
    @State private var opened = 0

    var body: some View {
        let _ = model.revision
        let _ = opened
        let facts = SettingsRoomContent.Facts.load(model: model, scheme: scheme, realModel: realModel,
                                                   backupLine: backupLine)
        ShellView(room: SettingsRoomContent(facts: facts), navigator: navigator, accent: Theme.Colors.ink,
                  act: handle)
            .environment(\.shellGlyphRoom, .log)
            .sheet(item: $area) { area in
                NavigationStack { area.destination }
            }
            .task {
                // Read once, from the copies' own files; nothing is written.
                backupLine = BackupKeeper.lastLine(copies: BackupKeeper.localCopies(), now: AppClock.now)
            }
        #if DEBUG
            .task { await navigator.walkForStills(room: SettingsRoomContent.room) }
        #endif
    }

    private func handle(_ intent: ShellIntent) {
        switch intent {
        case .back:
            if navigator.route.level == 0 {
                dismiss()
            } else {
                navigator.pop()
            }
        case let .openDoor(id):
            navigator.push(.door(SettingsRoomContent.room, id))
        case let .openItem(id):
            guard let next = SettingsRoomContent.area(for: id) else { return }
            SettingsAreaSeen.mark(next, at: AppClock.now)
            opened += 1
            area = next
        case .action:
            break
        }
    }
}
