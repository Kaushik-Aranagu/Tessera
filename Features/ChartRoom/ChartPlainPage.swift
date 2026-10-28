import SwiftUI
import TesseraCore

// The plain page every object of a class he made gets until he says how it should look (Design sheets 375 to 378).
// It is rendered from Core's `PageBook.page(for:)`: the object's own layer first, then the class's page (stored if he
// changed it, else generated), so a change said on one plant's page reaches every plant's page, and "just for the
// orchid" is a layer over that one. The kit draws it (title, line, number, lines), through the same frames the shell
// uses.

/// The page's content as kit nodes, by place. Pure over a page and the words its tokens read.
@MainActor
enum PlainPage {
    /// Which parts draw where: title, caption, keystone and the page's own lines.
    static func nodes(parts: [RoomPart], object: ObjectRecord, book: PageBook, engine: ActionEngine?,
                      drawingLinks: Bool = true) -> [Place: [PartNode]]
    {
        var out: [Place: [PartNode]] = [:]
        for part in parts {
            guard let place = Place(rawValue: part.place) else { continue }
            func words(_ text: String) -> String {
                filled(text, object: object, book: book, engine: engine)
            }
            let node: PartNode?
            switch part.kind {
            case "title":
                node = .title(id: part.id, text: words(part.text("text") ?? "{title}"))
            case "line":
                node = .line(id: part.id, text: words(part.text("text") ?? ""))
            case "lines":
                var texts: [String] = []
                if case let .array(items)? = part.props["lines"] {
                    texts = items.compactMap { item in
                        guard case let .string(text) = item else { return nil }
                        // A line that names a routine is drawn by the page itself, with its link (sheet 378).
                        return !drawingLinks && routineLink(in: text) != nil ? nil : words(text)
                    }.filter { !$0.isEmpty }
                }
                node = texts.isEmpty ? nil : .lines(id: part.id, texts: texts)
            case "number":
                let field = part.text("field") ?? ""
                var value = ""
                if case let .number(number)? = book.store.value(field, of: object) {
                    value = PartText.whole(number)
                }
                node = .number(id: part.id, value: value, unit: PartText.shown(part.text("unit") ?? ""),
                               label: PartText.shown(part.text("label") ?? ""))
            default:
                node = nil
            }
            if let node {
                out[place, default: []].append(node)
            }
        }
        return out
    }

    /// A page line with every token filled: "Last misted {@step.doneAt}" reads when the linked step was last checked
    /// off (sheet 379), then Core's own tokens ({title}, {field}, {recent(...)}, {@link.parent.title}).
    static func filled(_ template: String, object: ObjectRecord, book: PageBook, engine: ActionEngine?) -> String {
        let done = fillDone(template, now: AppClock.now) { key in
            book.store.linkedObjects(key, of: object).first.flatMap {
                RestBook(store: book.store, classes: book.classes).lastDone(ofStep: $0.id)
            }
        }
        return PartText.shown(book.text(done, for: object, engine: engine))
    }

    /// "today", "yesterday" or the weekday: when a routine step was last done, in a page's words (sheet 379).
    nonisolated static func dayWord(_ date: Date?, now: Date, calendar: Calendar = .current) -> String {
        guard let date else { return "never" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        switch days {
        case ..<1: return "today"
        case 1: return "yesterday"
        case 2 ..< 7:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    /// `{@field.doneAt}` in a line: when the step the link field points to was last done ("Last misted today").
    /// The date comes from `RestBook.lastDone(ofStep:)` through `lastDone`. Other tokens are left for `PageBook.text`.
    nonisolated static func fillDone(_ template: String, now: Date, calendar: Calendar = .current,
                                     lastDone: (String) -> Date?) -> String
    {
        var out = template
        while let open = out.range(of: "{@"), let close = out[open.upperBound...].firstIndex(of: "}") {
            let path = out[open.upperBound ..< close].split(separator: ".").map(String.init)
            guard path.count == 2, path[1] == "doneAt" else { break }
            out.replaceSubrange(open.lowerBound ... close,
                                with: dayWord(lastDone(path[0]), now: now, calendar: calendar))
        }
        return out
    }

    /// A line with a routine in it, split around the routine's name: "Last misted Thursday, in " and "Water
    /// houseplants".
    nonisolated static func splitAround(_ filled: String, routine title: String) -> (prefix: String, title: String)? {
        guard !title.isEmpty, let range = filled.range(of: title, options: .backwards) else { return nil }
        return (String(filled[..<range.lowerBound]), title)
    }

    /// The routine a plant's link field points to through its step's parent (sheet 378): `{@field.parent.title}`.
    static func routine(linkedBy key: String, from object: ObjectRecord, store: ObjectStore) -> ObjectRecord? {
        store.linkedObjects(key, of: object).first?.parent
    }

    /// A routine named in a line through `{@field.parent.title}` (sheet 378): the field that links to it, if any.
    nonisolated static func routineLink(in template: String) -> String? {
        var rest = Substring(template)
        while let open = rest.range(of: "{@"), let close = rest[open.upperBound...].firstIndex(of: "}") {
            let path = rest[open.upperBound ..< close].split(separator: ".").map(String.init)
            if path.count == 3, path[1] == "parent", path[2] == "title" {
                return path[0]
            }
            rest = rest[rest.index(after: close)...]
        }
        return nil
    }
}

/// What a plant's page can say to change it, and what it did (receipt and Tess's line come from the scope).
@MainActor
@Observable
final class ChartPageModel {
    struct Done: Identifiable {
        let id = UUID()
        let receipt: String
        let line: String
        let undo: () -> Void
    }

    let engine: ActionEngine
    let object: UUID
    private(set) var done: Done?
    private(set) var pending: OpRecord?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private let drying: Duration

    init(engine: ActionEngine, object: UUID, drying: Duration = .seconds(PartGhost.drying)) {
        self.engine = engine
        self.object = object
        self.drying = drying
    }

    /// Whether the object has been watered by an op that still stands: only then does its page offer to show when.
    func wasWatered() -> Bool {
        guard let record = engine.store.object(id: object), let field = record.classDef.flatMap({
            engine.store.field("lastWatered", of: $0)
        }) else { return false }
        return engine.history(of: object, limit: 400).contains { entry in
            entry.state != .undone && entry.ops.contains { op in
                if case let .setValue(id, fieldID, _, _) = op {
                    id == object && fieldID == field.id
                } else {
                    false
                }
            }
        }
    }

    /// Sheet 378: the orchid's own part, "Last misted today, in Water houseplants": read from the routine step its
    /// `misted` field links to (checking the step off on the routine page updates this line).
    static func mistedPart() -> RoomPatch {
        RoomPatch(room: "Plant page", say: "Last misted", ops: [
            .init(op: "add", id: "misted", kind: "lines", place: "page",
                  props: ["lines": .array([.string("Last misted {@misted.doneAt}, in {@misted.parent.title}")])]),
        ])
    }

    /// The change he can say on a plant's page: the dates it was watered, in its line.
    static func showWatered(room: String = "Plant page") -> RoomPatch {
        RoomPatch(room: room, say: "Watered dates", ops: [
            .init(op: "add", id: "watered", kind: "lines", place: "page",
                  props: ["lines": .array([.string("Watered {recent(lastWatered,3)}")])]),
        ])
    }

    /// Says a change on this page: to every page of the class, or `only` this object. It is a ghost for 2 s, then it
    /// sets with a receipt and Tess's line built from the scope, and Undo.
    func say(_ patch: RoomPatch, only: Bool, sentence: String) {
        guard pending == nil else { return }
        do {
            let result = try engine.perform(PatchPage(object: object, patch: patch, only: only, sentence: sentence),
                                            by: .tess, pending: true)
            pending = result.record
            let output = result.output
            task?.cancel()
            task = Task { [weak self, drying] in
                try? await Task.sleep(for: drying)
                guard !Task.isCancelled, let self, let record = pending else { return }
                try? engine.commit(record)
                pending = nil
                done = Done(receipt: output.receipt, line: output.line) { [weak self] in
                    guard let self else { return }
                    engine.undo(record)
                    done = nil
                }
            }
        } catch {
            done = nil
        }
    }

    func undo() {
        let current = done
        done = nil
        current?.undo()
    }
}

/// The plain page of an object of a class he made.
struct ChartPlainPage: View {
    let object: ObjectRecord

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pages: ChartPageModel?
    @State private var routine: ObjectStop?
    /// Bumped when a pushed routine page comes back, so the page re-reads what that page changed (a checked step).
    @State private var tick = 0
    /// Simulator only: why the UI test's seeded part could not be written.
    @State private var seedError: String?

    /// Objects of a class he made, while the Chart room is on (a system class keeps its own page).
    static func applies(to object: ObjectRecord) -> Bool {
        ChartRoomFlag.isOn && object.classDef.map { $0.systemKey == nil } == true
    }

    private var book: PageBook {
        PageBook(store: model.store, classes: model.classes)
    }

    /// The back word: the room he came from, by its own name.
    private var back: String {
        ChartRoomSummary.row().name
    }

    var body: some View {
        let _ = model.revision
        let _ = tick
        let parts = book.page(for: object)
        let nodes = PlainPage.nodes(parts: parts, object: object, book: book, engine: model.engine,
                                    drawingLinks: false)
        GeometryReader { proxy in
            let scale = max(0.86, min(1.1, proxy.size.height / 874))
            let dx = (proxy.size.width - 402) / 2
            ZStack(alignment: .topLeading) {
                ForEach([Place.title, .caption, .keystone, .page], id: \.self) { place in
                    if let list = nodes[place] {
                        let rect = rect(place, scale: scale, dx: dx)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(list) { node in
                                PartView(node: node, accent: Theme.Colors.Accent.lists)
                            }
                        }
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .frame(width: rect.width, height: rect.height, alignment: .topLeading)
                        .offset(x: rect.minX, y: rect.minY)
                    }
                }
                Button { dismiss() } label: {
                    Text(back)
                        .font(.custom("Figtree", size: 15, relativeTo: .callout).weight(.medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to \(back)")
                .frame(width: ShellLayout.ownFrame(.navWord).width, alignment: .trailing)
                .offset(x: ShellLayout.ownFrame(.navWord).minX + dx, y: ShellLayout.ownFrame(.navWord).minY * scale)
                tessLine(scale: scale)
                routineLines(parts: parts, scale: scale)
                if LaunchFlags.has("-chartMistedPart") {
                    let linked = model.store.linkedObjects("misted", of: object)
                    Text(
                        "seed \(seedError ?? "ok") plantsSeed \(UserDefaults.standard.string(forKey: "chartRoom.seedError") ?? "ok") parts \(parts.map(\.id).joined(separator: ",")) linked \(linked.map(\.title)) parent \(linked.first?.parent?.title ?? "none") routines \(model.classDef(.routine).map { model.store.objects(of: $0).map(\.title) } ?? []) steps \(model.classDef(.routineStep).map { model.store.objects(of: $0).count } ?? -1) raw \(String(describing: model.store.value("misted", of: object)))"
                    )
                    .font(.system(size: 11)).offset(x: 24, y: 560 * scale)
                }
                if pages?.wasWatered() == true {
                    sayWords(scale: scale)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .background { ThemedBackground() }
        .onAppear {
            if pages == nil {
                pages = ChartPageModel(engine: model.engine, object: object.id)
            }
            // Simulator only (UI tests): the orchid's own "Last misted" part, put there when its page opens.
            if LaunchFlags.has("-chartMistedPart"), object.title == "Orchid",
               !book.page(for: object).contains(where: { $0.id == "misted" })
            {
                do {
                    try model.engine.perform(PatchPage(object: object.id, patch: ChartPageModel.mistedPart(),
                                                       only: true), by: .user)
                } catch {
                    seedError = "\(error)"
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chart.plainPage")
        .onChange(of: routine) { _, now in
            if now == nil {
                tick += 1
            }
        }
        .navigationDestination(item: $routine) { stop in
            // The routine opens with the plant's name as its back word, in the room's colour (sheet 378).
            ObjectPage(route: .object(stop.id),
                       from: PageSource(name: object.title, color: ChartRoomSummary.row().color))
        }
    }

    /// A line that names a routine through a link field (sheet 378): the routine's name is a plum link that pushes the
    /// routine's page.
    private func routineLines(parts: [RoomPart], scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(parts.filter { $0.kind == "lines" && $0.place == "page" }, id: \.id) { part in
                if case let .array(items)? = part.props["lines"] {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        if case let .string(template) = item, let key = PlainPage.routineLink(in: template),
                           let target = PlainPage.routine(linkedBy: key, from: object, store: model.store),
                           let split = PlainPage.splitAround(
                               PlainPage.filled(template, object: object, book: book, engine: model.engine),
                               routine: target.title
                           )
                        {
                            HStack(spacing: 0) {
                                Text(split.prefix)
                                    .foregroundStyle(Theme.Colors.ink)
                                Button { routine = ObjectStop(id: target.id) } label: {
                                    Text(split.title)
                                        .foregroundStyle(Theme.Colors.Accent.routines)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("chart.routineLink")
                            }
                            .font(.custom("Figtree", size: 20, relativeTo: .body))
                        }
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(width: 354, alignment: .leading)
        .offset(x: 24, y: 420 * scale)
    }

    /// What he can say here: a change for every page of the class, or just for this one (the action word's two steps).
    private func sayWords(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                pages?.say(ChartPageModel.showWatered(), only: false, sentence: "Show when I watered it")
            } label: {
                Text("Say show when I watered it")
                    .font(.custom("Figtree", size: 20, relativeTo: .body).weight(.semibold))
                    .foregroundStyle(Theme.Colors.Accent.lists)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("chart.page.say")
            Button {
                pages?.say(ChartPageModel.showWatered(), only: true, sentence: "Show when I watered it, just here")
            } label: {
                Text("Just for the \(object.title.lowercased())")
                    .font(.custom("Figtree", size: 15, relativeTo: .callout).weight(.medium))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .offset(x: 24, y: 730 * scale)
    }

    private func rect(_ place: Place, scale: CGFloat, dx: CGFloat) -> CGRect {
        var rect = ShellLayout.ownFrame(place)
        if place == .caption || place == .title {
            rect.size.width = 354
        }
        rect.origin.y *= scale
        rect.origin.x += dx
        return rect
    }

    /// Tess's line: what the last change reached, from its scope; else which page this is (never a fixed string for a
    /// scope).
    private func tessLine(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let done = pages?.done {
                UndoLine(id: done.id, canUndo: true, tint: Theme.Colors.Accent.lists, reduceMotion: reduceMotion) {
                    FitLine(forms: FitLine.cuts(done.receipt), size: 15, color: Theme.Colors.inkSecondary,
                            weight: .medium)
                } undo: {
                    pages?.undo()
                }
                tessWords(done.line)
            } else {
                tessWords(intro, arrives: false)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(width: 354, alignment: .leading)
        .offset(x: 24, y: 668 * scale)
    }

    /// Tess's sentence, on the shared `TessLine`: a new line arrives word by word; the page's opening line is whole.
    private func tessWords(_ text: String, arrives: Bool = true) -> some View {
        TessLine(text: text, arrives: arrives, size: 15) { model.soul.lineStarted() }
            .frame(width: 354, alignment: .leading)
    }

    /// Before he says a change: the plain page's own line; on a page that is every plant's, who else it reaches.
    private var intro: String {
        guard let classDef = object.classDef else { return "" }
        if book.layer(forClass: classDef) != nil, book.layer(forObject: object.id) == nil {
            let scope = PageScope.klass(name: classDef.name, count: model.store.objects(of: classDef).count)
            if case let .klass(name, _) = scope {
                return "This page is every \(name.lowercased())'s. Say a change and they all get it"
            }
        }
        return "Every \(classDef.name.lowercased()) gets this plain page until you say how it should look"
    }
}
