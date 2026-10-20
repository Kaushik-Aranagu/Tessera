import SwiftUI
import TesseraCore
import UniformTypeIdentifiers

/// What the class inspector shows (Design sheet 113): the class's name, where it comes from, how many objects it
/// has, its fields with their types (computed ones with the formula as written), its links in and out, and its
/// views. Read through ClassResolver and ObjectStore only; never an object's value or title.
struct ClassInspection: Equatable {
    struct FieldRow: Equatable, Identifiable {
        let id: UUID
        let name: String
        /// One word, or "link to Exercise".
        let type: String
        /// The formula text as written, for a computed field.
        let formula: String?

        /// "Volume, formula, formula: weight * reps" (sheet 113 VoiceOver).
        var voiceOver: String {
            formula.map { "\(name), \(type), formula: \($0)" } ?? "\(name), \(type)"
        }
    }

    struct LinkRow: Equatable, Identifiable {
        enum Direction: String, Equatable {
            case `in`, out
        }

        let classID: UUID
        let name: String
        let direction: Direction

        var id: String {
            "\(classID.uuidString)-\(direction.rawValue)"
        }

        /// "Exercise in", "Routine out".
        var line: String {
            "\(name) \(direction.rawValue)"
        }
    }

    let classID: UUID
    let name: String
    let isBuiltIn: Bool
    let objectCount: Int
    let fields: [FieldRow]
    let links: [LinkRow]
    let views: [String]

    /// "Built in, 38 objects" or "Yours, 1 object".
    var originLine: String {
        "\(isBuiltIn ? "Built in" : "Yours"), \(objectCount) object\(objectCount == 1 ? "" : "s")"
    }

    /// The type of a field as one plain word; a link names the class it points at.
    static func typeWord(_ kind: FieldKind, target: String?) -> String {
        switch kind {
        case .text: "text"
        case .number: "number"
        case .bool: "yes or no"
        case .date: "date"
        case .duration: "duration"
        case .mass: "weight"
        case .choice: "choice"
        case .ref: target.map { "link to \($0)" } ?? "link"
        case .refList: target.map { "links to \($0)" } ?? "links"
        case .classRef: target.map { "kind of \($0)" } ?? "kind"
        case .computed: "formula"
        case .richText: "long text"
        }
    }

    @MainActor
    static func make(_ classDef: ClassDef, store: ObjectStore, prototypeID: UUID?) -> ClassInspection {
        let fields = ClassResolver.effectiveFields(of: classDef)
        let rows = fields.map { field in
            FieldRow(id: field.id, name: field.name,
                     type: typeWord(field.kind, target: field.targetClassID.flatMap { store.classDef(id: $0)?.name }),
                     formula: field.kind == .computed ? field.expression : nil)
        }
        var links: [LinkRow] = []
        var seen = Set<String>()
        func add(_ row: LinkRow) {
            if seen.insert(row.id).inserted {
                links.append(row)
            }
        }
        for field in fields where [.ref, .refList, .classRef].contains(field.kind) {
            if let target = field.targetClassID.flatMap({ store.classDef(id: $0) }) {
                add(LinkRow(classID: target.id, name: target.name, direction: .out))
            }
        }
        // A link in is a field another class declares itself; inherited copies would list every subclass.
        for other in store.allClasses() where other.id != classDef.id {
            let declares = ClassResolver.effectiveFields(of: other).contains { field in
                field.declaringClassID == other.id && field.targetClassID == classDef.id
            }
            if declares {
                add(LinkRow(classID: other.id, name: other.name, direction: .in))
            }
        }
        let count = store.objects(of: classDef).count { !$0.isDeleted && $0.id != prototypeID }
        let views = (classDef.views ?? []).sorted { $0.sortIndex < $1.sortIndex }.map(\.name)
            .filter { !$0.isEmpty }
        return ClassInspection(classID: classDef.id, name: classDef.name,
                               isBuiltIn: classDef.systemKey != nil || classDef.packageID != nil,
                               objectCount: count, fields: rows, links: links, views: views)
    }
}

/// The inspector's switch (sheet 113): Off until Kaushik asks for it. Product adds the `classInspector` row; until
/// it exists the value is nil, which reads as Off.
enum ClassInspectorSwitch {
    static func isOn(_ value: String?) -> Bool {
        value == "On"
    }

    @MainActor
    static var isOn: Bool {
        isOn(ReviewChoices.shared.value(of: "classInspector"))
    }
}

/// What a page pushes to open a class's inspector.
struct InspectorTarget: Hashable, Identifiable {
    let id: UUID
}

/// A read-only page for one class (Design sheet 113): one column in the class page grammar, four blocks between
/// hairlines, nothing editable. The foot carries Export and Import for class packages.
struct ClassInspector: View {
    let classID: UUID
    @Environment(AppModel.self) private var model
    @State private var next: InspectorTarget?
    @State private var importing = false
    @State private var preview: ClassPackageImport?
    @State private var importLine: String?
    @State private var importRecord: OpRecord?
    @State private var undos = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let _ = model.revision
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                if let classDef = model.classDef(id: classID) {
                    let inspection = ClassInspection.make(classDef, store: model.store,
                                                          prototypeID: model.prototype(of: classDef)?.id)
                    content(inspection, classDef: classDef)
                } else {
                    Text(ObjectPageCopy.gone).textRole(.title).foregroundStyle(Theme.Colors.ink)
                }
            }
            .padding(.leading, Theme.Spacing.gutter - 6)
            .padding(.trailing, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, 180)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        .navigationDestination(item: $next) { target in
            ClassInspector(classID: target.id)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            preview = ClassPackageImport.read(result)
        }
        .tesseraFeedback(.undo, trigger: undos)
        .sheet(item: $preview) { found in
            ClassPackagePreviewSheet(found: found) { line, record in
                withTesseraAnimation(reduceMotion: reduceMotion) {
                    importLine = line
                    importRecord = record
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ inspection: ClassInspection, classDef: ClassDef) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            RevealingHero(text: inspection.name)
                .accessibilityAddTraits(.isHeader)
                .entrance(1, hero: true)
            Text(inspection.originLine)
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .entrance(2)
        }

        if !inspection.fields.isEmpty {
            Hairline()
            MarginSection(label: "Fields") {
                VStack(spacing: 0) {
                    ForEach(Array(inspection.fields.enumerated()), id: \.element.id) { index, field in
                        FieldLine(field: field)
                        if index < inspection.fields.count - 1 {
                            RowSeparator()
                        }
                    }
                }
            }
            .entrance(3)
        }

        if !inspection.links.isEmpty {
            Hairline()
            MarginSection(label: "Links") {
                VStack(spacing: 0) {
                    ForEach(inspection.links) { link in
                        Button { next = InspectorTarget(id: link.classID) } label: {
                            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                                Text(link.name)
                                    .textRole(.body)
                                    .foregroundStyle(Theme.Colors.ink)
                                    .padding(.bottom, 4)
                                    .overlay(alignment: .bottom) { DottedRule(color: Theme.Colors.inkTertiary) }
                                Spacer(minLength: Theme.Spacing.s)
                                Text(link.direction.rawValue)
                                    .textRole(.data)
                                    .foregroundStyle(Theme.Colors.inkSecondary)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(HandleButtonStyle())
                        .accessibilityLabel(link.line)
                        .accessibilityHint("Opens its inspector")
                    }
                }
            }
            .entrance(4)
        }

        if !inspection.views.isEmpty {
            Hairline()
            MarginSection(label: "Views") {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(inspection.views.enumerated()), id: \.offset) { _, name in
                        Text(name)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
            }
            .entrance(5)
        }

        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Hairline()
            if let importLine {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Text(importLine)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Theme.Spacing.s)
                    if importRecord != nil {
                        Button("Undo", action: undoImport)
                            .buttonStyle(.labelWord(Theme.Colors.inkSecondary, silent: true))
                    }
                }
                .transition(.opacity)
            }
            HStack(spacing: Theme.Spacing.xl) {
                ShareLink(item: ClassPackageExport(file: ClassPackageFile.make(classDef, model: model)),
                          preview: SharePreview(ClassPackageCopy.shareTitle(classDef.name)))
                {
                    Text("Export")
                }
                .buttonStyle(.labelWord)
                .accessibilityHint("Shares this class and its objects as one file")
                Button("Import") { importing = true }
                    .buttonStyle(.labelWord)
                    .accessibilityHint("Picks a class file and shows what it adds first")
            }
        }
        .entrance(6)
    }
}

private extension ClassInspector {
    /// UNDO under an import's line: its objects come back out through the op log; the line says so, thing first.
    func undoImport() {
        guard let record = importRecord else { return }
        model.engine.undo(record)
        model.touch()
        undos += 1
        let thing = importLine.map(UndoCopy.takenBack(after:)) ?? "Taken back."
        withTesseraAnimation(reduceMotion: reduceMotion) {
            importLine = thing
            importRecord = nil
        }
    }
}

/// One field: its name and its type word to the right; a computed field adds its formula underneath.
private struct FieldLine: View {
    let field: ClassInspection.FieldRow
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            layout {
                Text(field.name).textRole(.body).foregroundStyle(Theme.Colors.ink)
                if !stacked {
                    Spacer(minLength: Theme.Spacing.m)
                }
                Text(field.type).textRole(.data).foregroundStyle(Theme.Colors.inkSecondary)
            }
            if let formula = field.formula {
                Text(formula)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, Theme.Spacing.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(field.voiceOver)
    }
}

/// Opens a class's inspector on a long press, when the switch is on (sheet 113: "Long press on a class title").
/// VoiceOver gets the same door as a named action.
struct InspectOnLongPress: ViewModifier {
    let classID: UUID?
    @State private var target: InspectorTarget?

    func body(content: Content) -> some View {
        if let classID, ClassInspectorSwitch.isOn {
            content
                .onLongPressGesture { open(classID) }
                .accessibilityAction(named: "Inspect") { open(classID) }
                .navigationDestination(item: $target) { target in
                    ClassInspector(classID: target.id)
                }
        } else {
            content
        }
    }

    private func open(_ id: UUID) {
        target = InspectorTarget(id: id)
    }
}

extension View {
    func inspectsClass(_ classID: UUID?) -> some View {
        modifier(InspectOnLongPress(classID: classID))
    }
}
