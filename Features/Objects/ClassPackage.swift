import CoreTransferable
import SwiftUI
import TesseraCore
import UniformTypeIdentifiers

/// One class as one JSON file (ship list M3 item 11): its own fields, and its objects with their plain values. A
/// private object stays on the phone, and so do links, which only mean something in this store.
struct ClassPackageFile: Codable, Equatable, Sendable {
    static let formatName = "tessera.class"
    static let currentVersion = 1

    struct Field: Codable, Equatable, Sendable {
        var key: String
        var name: String
        var kind: FieldKind
        var unit: String?
        var options: [String] = []
        var expression: String?
        /// The class a link field points at, by name.
        var target: String?
    }

    struct Object: Codable, Equatable, Sendable {
        var title: String
        var values: [String: FieldValue] = [:]
    }

    var format = formatName
    var version = currentVersion
    var name: String
    /// The parent class, by name; nil for a root class.
    var parent: String?
    var symbolName = "circle"
    var colorRole = "neutral"
    var fields: [Field] = []
    var objects: [Object] = []

    static func encode(_ file: ClassPackageFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    /// Nil when the data isn't a class file this version can read.
    static func decode(_ data: Data) -> ClassPackageFile? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(ClassPackageFile.self, from: data), file.format == formatName,
              file.version <= currentVersion,
              !file.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return file
    }

    /// The package for a class, read through ClassResolver and ObjectStore. Masked objects are left out.
    @MainActor
    static func make(_ classDef: ClassDef, model: AppModel) -> ClassPackageFile {
        let store = model.store
        let resolved = ClassResolver.effectiveFields(of: classDef)
        let own = resolved.filter { $0.declaringClassID == classDef.id }
        let fields = own.map { field in
            Field(key: field.key, name: field.name, kind: field.kind, unit: field.unit, options: field.enumOptions,
                  expression: field.expression,
                  target: field.targetClassID.flatMap { store.classDef(id: $0)?.name })
        }
        let scalar = resolved.filter { ![.ref, .refList, .classRef, .computed].contains($0.kind) }
        let prototype = model.prototype(of: classDef)?.id
        let objects = store.objects(of: classDef, includingSubclasses: false)
            .filter { !$0.isDeleted && $0.id != prototype }
            .filter { ObjectMask.label(of: $0, in: store, classes: model.classes) == nil }
            .sorted { $0.createdAt < $1.createdAt }
            .map { object in
                var values: [String: FieldValue] = [:]
                for field in scalar where store.hasOwnValue(field.key, on: object) {
                    values[field.key] = store.value(field.key, of: object)
                }
                return Object(title: object.title, values: values)
            }
        return ClassPackageFile(name: classDef.name, parent: classDef.parent?.name, symbolName: classDef.symbolName,
                                colorRole: classDef.colorRole, fields: fields, objects: objects)
    }
}

/// What importing a package would add, worked out before anything is written.
struct ClassPackagePreview: Equatable {
    /// The name the new class gets: the file's, or "Films 2" when a Films is already here.
    let name: String
    /// Set when the name had to change.
    let existingName: String?
    /// The class it goes under.
    let parentName: String
    /// The file's parent when it isn't on this phone (it then goes under Thing).
    let missingParent: String?
    let fields: [String]
    /// Link fields whose class isn't here: they are left out.
    let leftOutFields: [String]
    let objectCount: Int

    static let fallbackParent = "Thing"

    static func make(_ file: ClassPackageFile, classNames: Set<String>) -> ClassPackagePreview {
        let base = file.name.trimmingCharacters(in: .whitespacesAndNewlines)
        var name = base
        var number = 2
        while classNames.contains(name) {
            name = "\(base) \(number)"
            number += 1
        }
        let parentFound = file.parent.map(classNames.contains) ?? false
        let isLink: (ClassPackageFile.Field) -> Bool = { [.ref, .refList, .classRef].contains($0.kind) }
        let kept = file.fields.filter { !isLink($0) || $0.target.map(classNames.contains) == true }
        let left = file.fields.filter { field in !kept.contains(field) }
        return ClassPackagePreview(
            name: name, existingName: name == base ? nil : base,
            parentName: parentFound ? file.parent ?? fallbackParent : fallbackParent,
            missingParent: parentFound ? nil : file.parent,
            fields: kept.map(\.name), leftOutFields: left.map(\.name), objectCount: file.objects.count
        )
    }

    /// The preview in plain lines, thing first.
    var lines: [String] {
        var lines: [String] = []
        if let existingName {
            lines.append("\(name), a new class beside your \(existingName).")
        } else {
            lines.append("\(name), a new class.")
        }
        if let missingParent {
            lines.append("\(missingParent) isn't on this phone, so it goes under \(parentName).")
        } else {
            lines.append("Under \(parentName).")
        }
        lines.append(fields.isEmpty ? "No fields of its own." : "Fields: \(ClassPackageCopy.list(fields)).")
        if !leftOutFields.isEmpty {
            lines.append("Left out: \(ClassPackageCopy.list(leftOutFields)). Their classes aren't here.")
        }
        lines.append(objectCount == 0 ? "No objects." : "\(objectCount) object\(objectCount == 1 ? "" : "s").")
        return lines
    }
}

enum ClassPackageCopy {
    static func shareTitle(_ name: String) -> String {
        "\(name), a Tessera class"
    }

    static let unreadable = "This file isn't a Tessera class."
    static let failed = "Couldn't add it. Nothing changed."

    /// "Films, added with 12 objects."
    static func added(_ name: String, objects: Int) -> String {
        objects == 0 ? "\(name), added." : "\(name), added with \(objects) object\(objects == 1 ? "" : "s")."
    }

    /// "Rating, Seen and Year".
    static func list(_ names: [String]) -> String {
        switch names.count {
        case 0: ""
        case 1: names[0]
        default: names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
        }
    }
}

/// The share sheet's item: the package as a .json file named after the class.
struct ClassPackageExport: Transferable {
    let file: ClassPackageFile

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { try ClassPackageFile.encode($0.file) }
            .suggestedFileName { "\($0.file.name).json" }
    }
}

/// A picked file: the package and its preview, or the line saying it can't be read.
struct ClassPackageImport: Identifiable {
    let id = UUID()
    let file: ClassPackageFile?

    static func read(_ result: Result<URL, any Error>) -> ClassPackageImport? {
        guard case let .success(url) = result else { return nil }
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return ClassPackageImport(file: (try? Data(contentsOf: url)).flatMap(ClassPackageFile.decode))
    }
}

/// Adds a package as a new class, through the op log: its objects and values come back out with UNDO. The fields
/// themselves are schema, which the op log doesn't carry yet (Core has no field op), so an undone import leaves the
/// empty class behind.
struct ImportClassPackage: EngineAction {
    static let descriptor = ActionDescriptor(
        name: "importClassPackage",
        summary: "Import a class from a file",
        parameters: [],
        isOfferedToModel: false
    )

    var file: ClassPackageFile

    struct Output {
        let classDef: ClassDef
        let objects: Int
    }

    func apply(_ transaction: inout Transaction) throws -> Output {
        let store = transaction.store
        let names = Set(store.allClasses().map(\.name))
        let preview = ClassPackagePreview.make(file, classNames: names)
        let parent = store.classDef(named: preview.parentName) ?? transaction.classes[.thing]
        let classDef = transaction.createClass(name: preview.name, parent: parent, symbolName: file.symbolName,
                                               colorRole: file.colorRole)
        for (index, spec) in file.fields.enumerated() where preview.fields.contains(spec.name) {
            let field = FieldDef(name: spec.name, key: spec.key, kind: spec.kind, sortIndex: index, unit: spec.unit)
            field.enumOptions = spec.options
            field.expression = spec.expression
            field.targetClassID = spec.target.flatMap { store.classDef(named: $0)?.id }
            store.context.insert(field)
            field.owner = classDef
        }
        store.invalidateCaches()
        for object in file.objects {
            let made = transaction.create(classDef, title: object.title)
            for (key, value) in object.values.sorted(by: { $0.key < $1.key }) {
                try? transaction.set(key, to: value, on: made)
            }
        }
        return Output(classDef: classDef, objects: file.objects.count)
    }

    func summary(in _: ObjectStore) -> String {
        "Imported \(file.name)"
    }

    func summary(in _: ObjectStore, output: Output) -> String {
        "Imported \(output.classDef.name)"
    }

    func receipt(in _: ObjectStore, output: Output) -> String? {
        ClassPackageCopy.added(output.classDef.name, objects: output.objects)
    }
}

/// What a picked file will add, before anything is written: the lines, then Add or Not now.
struct ClassPackagePreviewSheet: View {
    let found: ClassPackageImport
    /// The receipt line, and the record UNDO takes back.
    let onAdded: (String, OpRecord?) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var failed = false
    @State private var added = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            if let file = found.file {
                let preview = ClassPackagePreview.make(file, classNames: Set(model.store.allClasses().map(\.name)))
                Text(preview.name)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    ForEach(Array(preview.lines.dropFirst().enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if failed {
                    Text(ClassPackageCopy.failed).textRole(.body).foregroundStyle(Theme.Colors.ink)
                }
                Hairline()
                HStack(spacing: Theme.Spacing.xl) {
                    Button("Add") { add(file) }
                        .buttonStyle(.labelWord(Theme.Colors.ink))
                    Button("Not now") { dismiss() }
                        .buttonStyle(.labelWord)
                }
            } else {
                Text(ClassPackageCopy.unreadable)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Back") { dismiss() }
                    .buttonStyle(.labelWord)
            }
        }
        .padding(Theme.Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .presentationDetents([.medium, .large])
        .tesseraFeedback(.made, trigger: added)
    }

    private func add(_ file: ClassPackageFile) {
        guard let result = try? model.engine.perform(ImportClassPackage(file: file), by: .user) else {
            failed = true
            return
        }
        model.touch()
        added += 1
        onAdded(result.record.receipt ?? ClassPackageCopy.added(result.output.classDef.name,
                                                                objects: result.output.objects),
                result.record)
        dismiss()
    }
}
