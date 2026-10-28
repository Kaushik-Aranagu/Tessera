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
    static func nodes(parts: [RoomPart], object: ObjectRecord, book: PageBook, engine: ActionEngine?)
        -> [Place: [PartNode]]
    {
        var out: [Place: [PartNode]] = [:]
        for part in parts {
            guard let place = Place(rawValue: part.place) else { continue }
            func words(_ text: String) -> String {
                PartText.shown(book.text(text, for: object, engine: engine))
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
                        if case let .string(text) = item {
                            words(text)
                        } else {
                            nil
                        }
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

    /// A routine named in a line through `{@field.parent.title}` (sheet 378): the field that links to it, if any.
    nonisolated static func routineLink(in template: String) -> String? {
        guard let open = template.range(of: "{@"), let close = template[open.upperBound...].firstIndex(of: "}") else {
            return nil
        }
        let path = template[open.upperBound ..< close].split(separator: ".").map(String.init)
        return path.count == 3 && path[1] == "parent" && path[2] == "title" ? path[0] : nil
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
        let parts = book.page(for: object)
        let nodes = PlainPage.nodes(parts: parts, object: object, book: book, engine: model.engine)
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
                sayWords(scale: scale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .background { ThemedBackground() }
        .onAppear {
            if pages == nil {
                pages = ChartPageModel(engine: model.engine, object: object.id)
            }
        }
        .accessibilityIdentifier("chart.plainPage")
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
                tessWords(intro)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(width: 354, alignment: .leading)
        .offset(x: 24, y: 668 * scale)
    }

    /// Tess's sentence in full: three lines at most, never cut mid-sentence.
    private func tessWords(_ text: String) -> some View {
        Text(text)
            .font(.custom("Figtree", size: 15, relativeTo: .callout))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
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
