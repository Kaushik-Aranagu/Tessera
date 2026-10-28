import SwiftUI
import TesseraCore

// The Chart room in the standing shell (R1 spec section 6), behind the `chartRoom` feature flag (Everywhere, ships
// On). The room is experimental: everything stays behind the flag, and Builder B's pages are untouched.

enum ChartRoomFlag {
    static let id = "chartRoom"

    /// On unless he turned it Off in Developer mode; a unit-test host and a demo keep it On (the room is the same).
    static var isOn: Bool {
        guard FeatureFlagStore.usesFlags else { return true }
        return FeatureFlagStore.isOn(id) ?? true
    }
}

extension ChartRoomModel {
    /// The one live model: kept on this iPhone (`chartRoom.document`), and `-resetChart` on the simulator starts blank.
    static func live() -> ChartRoomModel {
        let defaults = UserDefaults.standard
        if LaunchFlags.has("-resetChart") {
            defaults.removeObject(forKey: defaultsKey)
            defaults.removeObject(forKey: cursorKey)
        }
        let model = ChartRoomModel(defaults: defaults)
        // Simulator stills: `-chartSentences N` sets the first N canned sentences, `-chartFixture` loads Core's room.
        if LaunchFlags.has("-chartPlantDoors") {
            // Simulator stills and UI tests: a plant room with one door per plant (sheet 375).
            var doc = ChartDoc(name: "Chart room", color: "olive")
            doc.parts = [
                ChartPart(id: "title", kind: .title, place: "title", props: ["text": .text("Plants")]),
                ChartPart(id: "row", kind: .row, place: "keystone",
                          props: ["big": .text("lastWatered"), "sort": .text("-daysSince(lastWatered)")],
                          bind: "Plant"),
                ChartPart(id: "glow", kind: .top, place: "keystone",
                          props: ["on": .text("row"), "field": .text("lastWatered")]),
                ChartPart(id: "doors", kind: .doors, place: "dial",
                          props: ["summary": .text("waterEvery"), "sort": .text("-daysSince(lastWatered)")],
                          bind: "Plant"),
            ]
            model.load(doc)
        } else if LaunchFlags.has("-chartFixture") {
            var doc = ChartDoc(RoomFixture.chart)
            doc.color = "olive"
            model.load(doc)
        } else if let count = LaunchFlags.value(after: "-chartSentences").flatMap(Int.init) {
            model.setSentences(count)
        }
        return model
    }
}

/// The Chart room as the root shell holds it beside Bridge.
@MainActor
@Observable
final class ChartRoomDriver: ShellRoomDriver {
    let room = DocumentRoom.room
    let tessRoom: AppID? = nil
    let flip = KeystoneFlip.rows
    /// Its glyphs come from the Watch's own drawings (a watering can, a grove): the vetted set for a plant room.
    let glyphRoom: GlyphKind.Room? = .watch
    var accent: Color {
        ChartRoomSummary.color(chart.document.color)
    }

    /// Made on first use, so the drivers the shell builds and drops never reset a built room.
    @ObservationIgnored private(set) lazy var chart = ChartRoomModel.live()

    func content(model: AppModel, scheme _: ColorScheme) -> any RoomContent {
        chart.attach(model.engine)
        chart.onSmile = { [weak soul = model.soul] in soul?.smileOnce() }
        chart.onSmileEnd = { [weak soul = model.soul] in soul?.smileEnds() }
        return DocumentRoom(nodes: chart.nodes, ghost: chart.ghostPlaces, accent: accent, sayObject: chart.sayObject,
                            footSteps: chart.historyFoot ?? chart.replayFoot)
    }

    /// The object whose page a door opened (a sheet over the shell).
    var opened: ObjectStop?

    func handle(_ intent: ShellIntent, navigator _: ShellNavigator) -> Bool {
        switch intent {
        case .back: return false
        case let .openDoor(id): opened = ChartDoors.stop(id, chart)
        case let .action(id): run(id, chart)
        default: break
        }
        return true
    }

    func entered(navigator: ShellNavigator) {
        // The first open of a restored room replays how it was made (sheet 372).
        chart.openIfOwed()
        // A taken-down room goes: the empty room dissolves over Bridge, and the dial has one row less.
        chart.onArchived = { [weak navigator] in
            while navigator?.canPop == true {
                navigator?.pop()
            }
        }
    }

    func overlay(navigator _: ShellNavigator) -> AnyView {
        AnyView(ChartRoomLayer(model: chart))
    }

    func presenter() -> AnyView {
        AnyView(ChartRoomPresenter(driver: self))
    }
}

/// An object's page opened from a door.
struct ObjectStop: Identifiable, Hashable {
    let id: UUID
}

enum ChartDoors {
    /// The door the dial names ("chart.door.2") to the object it opens.
    @MainActor
    static func stop(_ door: String, _ chart: ChartRoomModel) -> ObjectStop? {
        guard let index = door.split(separator: ".").last.flatMap({ Int($0) }),
              let object = chart.doorObject(at: index)
        else { return nil }
        return ObjectStop(id: object)
    }
}

private struct ChartRoomPresenter: View {
    @Bindable var driver: ChartRoomDriver

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .sheet(item: $driver.opened) { stop in
                NavigationStack { ObjectPage(route: .object(stop.id)) }
            }
    }
}

/// What the action word's steps do.
@MainActor
func run(_ step: String, _ chart: ChartRoomModel) {
    if step == "say" {
        chart.saySomething()
    } else if step == "skip" {
        chart.skipReplay()
    } else if step == "close" {
        chart.closeHistory()
    } else if step == "goback" {
        chart.goBack()
    } else if step.hasPrefix("does:") {
        chart.does(String(step.dropFirst(5)))
    }
}

/// The Chart room opened on its own (`-shellRoom chart` on the simulator): the same shell and layer as the root's.
struct ChartShellHost: View {
    @Environment(AppModel.self) private var app
    @State private var navigator = ShellNavigator(root: .landing(DocumentRoom.room))
    @State private var chart = ChartRoomModel.live()
    @State private var opened: ObjectStop?

    var body: some View {
        let _ = app.revision
        let _ = chart.attach(app.engine)
        ShellView(
            room: DocumentRoom(
                nodes: chart.nodes,
                ghost: chart.ghostPlaces,
                sayObject: chart.sayObject,
                footSteps: chart.historyFoot ?? chart.replayFoot
            ),
            navigator: navigator,
            accent: ChartRoomSummary.color(chart.document.color)
        ) { intent in
            switch intent {
            case .back: navigator.pop()
            case let .openDoor(id): opened = ChartDoors.stop(id, chart)
            case let .action(id): run(id, chart)
            default: break
            }
        }
        .overlay { ChartRoomLayer(model: chart) }
        .sheet(item: $opened) { stop in
            NavigationStack { ObjectPage(route: .object(stop.id)) }
        }
        .task {
            // Simulator stills: `-chartSay` plays the next sentence 3 s after launch, so a ghost can be photographed.
            if LaunchFlags.has("-chartOpenDoor") {
                try? await Task.sleep(for: .seconds(3))
                opened = ChartDoors.stop("chart.door.0", chart)
                return
            }
            guard LaunchFlags.has("-chartSay") else { return }
            try? await Task.sleep(for: .seconds(3))
            chart.saySomething()
        }
    }
}

extension ChartRoomModel {
    /// The foot while the history is open: Close, and Go back to how it was at 1:18 pm while a version is previewed.
    var historyFoot: [ShellStep]? {
        guard historyOpen else { return nil }
        if let object = goBackObject {
            return [ShellStep(id: "goback", verb: "Go back", object: object), ShellStep(id: "close", verb: "Close")]
        }
        return [ShellStep(id: "close", verb: "Close")]
    }
}
