import Foundation

// The object model, held in memory by a `TesseraContext` and written through to SQLite (GRDB).
//
// Relationships keep their inverses in step the moment they're set (`object.parent = workout` also appends to
// `workout.children`), so reads never query the database. Every stored property marks its model dirty, so a save
// writes only what changed. Delete rules (cascade / nullify) are applied by `TesseraContext.delete`.

/// Interface-like mixins a class can adopt. Features key off these
/// (e.g. anything `schedulable` can sit in Now / Next / Later or a plan).
public enum ClassTrait: String, Codable, CaseIterable, Sendable {
    case schedulable
    case timed
    case trackable
    case measurable
}

/// A model that lives in a `TesseraContext`.
@MainActor
public protocol TesseraModel: AnyObject {
    var id: UUID { get }
    var context: TesseraContext? { get }
}

/// The context sets itself on the models it holds.
@MainActor
protocol AttachableModel: TesseraModel {
    var context: TesseraContext? { get set }
}

extension TesseraModel {
    func didChange() {
        context?.markDirty(self)
    }
}

/// Inverse maintenance. Callers append only when a relationship actually changes, so no duplicate check
/// (a check would make loading a long history quadratic).
extension Optional {
    mutating func append<Element: AnyObject>(_ element: Element) where Wrapped == [Element] {
        if self == nil {
            self = []
        }
        self?.append(element)
    }

    mutating func remove<Element: AnyObject>(_ element: Element) where Wrapped == [Element] {
        self?.removeAll { $0 === element }
    }
}

// MARK: ClassDef

/// A user-definable kind of object ("Exercise", "Bench Press", "Workout", "Book").
/// Single inheritance through `parent`; fields are inherited down the chain.
@MainActor
public final class ClassDef: TesseraModel, AttachableModel {
    public internal(set) weak var context: TesseraContext?

    public var id: UUID {
        didSet { context?.rekey(self, from: oldValue) }
    }

    public var name: String {
        didSet { didChange() }
    }

    public var symbolName: String {
        didSet { didChange() }
    }

    /// Semantic color role resolved by the design system (e.g. "training", "planning"), never a raw color.
    public var colorRole: String {
        didSet { didChange() }
    }

    public var traitsRaw: [String] {
        didSet { didChange() }
    }

    /// Stable key for built-in classes (e.g. "system.benchPress"); nil for user classes.
    public var systemKey: String? {
        didSet { didChange() }
    }

    public var sortIndex: Int = 0 {
        didSet { didChange() }
    }

    public var createdAt: Date = .now {
        didSet { didChange() }
    }

    /// The package that ships this class ("system" for built-ins), and the package version last applied.
    public var packageID: String? {
        didSet { didChange() }
    }

    public var packageVersion: Int = 0 {
        didSet { didChange() }
    }

    /// Set when the person edits a shipped class; package upgrades then leave its name, symbol and traits alone.
    public var isUserModified: Bool = false {
        didSet { didChange() }
    }

    public var parent: ClassDef? {
        didSet {
            guard oldValue !== parent else { return }
            oldValue?.subclasses.remove(self)
            parent?.subclasses.append(self)
            didChange()
        }
    }

    /// Inverses, maintained automatically.
    public internal(set) var subclasses: [ClassDef]? = []
    public internal(set) var ownFields: [FieldDef]? = []
    public internal(set) var objects: [ObjectRecord]? = []
    /// Links that point at this class (classRef fields), e.g. every logged entry of Bench Press.
    public internal(set) var incomingLinks: [ObjectLink]? = []
    public internal(set) var views: [ViewDef]? = []

    public init(
        name: String,
        parent: ClassDef? = nil,
        symbolName: String = "circle",
        colorRole: String = "neutral",
        traits: [ClassTrait] = [],
        systemKey: String? = nil
    ) {
        id = .v7()
        self.name = name
        self.symbolName = symbolName
        self.colorRole = colorRole
        traitsRaw = traits.map(\.rawValue)
        self.systemKey = systemKey
        self.parent = parent
        parent?.subclasses.append(self)
    }

    /// Own traits only. Use `ClassResolver.traits(of:)` for the inherited set.
    public var ownTraits: Set<ClassTrait> {
        Set(traitsRaw.compactMap(ClassTrait.init(rawValue:)))
    }
}

// MARK: FieldDef

/// A property declared by a class. Values are stored by `id`, never by name.
@MainActor
public final class FieldDef: TesseraModel, AttachableModel {
    public internal(set) weak var context: TesseraContext?

    public var id: UUID {
        didSet { context?.rekey(self, from: oldValue) }
    }

    /// Display name, freely renamable.
    public var name: String {
        didSet { didChange() }
    }

    /// Identifier used by formulas and code (e.g. "weight"). Values are still stored by `id`.
    public var key: String {
        didSet { didChange() }
    }

    public var kindRaw: String {
        didSet { didChange() }
    }

    public var sortIndex: Int {
        didSet { didChange() }
    }

    public var isRequired: Bool = false {
        didSet { didChange() }
    }

    public var unit: String? {
        didSet { didChange() }
    }

    public var enumOptions: [String] = [] {
        didSet { didChange() }
    }

    /// For `.ref`, `.refList`, `.classRef`: the target class (subclasses are accepted too).
    public var targetClassID: UUID? {
        didSet { didChange() }
    }

    /// For `.computed`: a `Formula` over other field keys, e.g. `weight * (1 + reps / 30)`.
    public var expression: String? {
        didSet { didChange() }
    }

    public var defaultValueData: Data? {
        didSet { didChange() }
    }

    /// When set, this field doesn't add a new property: it overrides the default of an inherited field.
    public var overridesFieldID: UUID? {
        didSet { didChange() }
    }

    /// Set when the person edits a shipped field (the user overlay); package upgrades then leave it alone.
    public var isUserModified: Bool = false {
        didSet { didChange() }
    }

    public var owner: ClassDef? {
        didSet {
            guard oldValue !== owner else { return }
            oldValue?.ownFields.remove(self)
            owner?.ownFields.append(self)
            didChange()
        }
    }

    public init(
        name: String,
        key: String,
        kind: FieldKind,
        sortIndex: Int = 0,
        unit: String? = nil,
        defaultValue: FieldValue? = nil
    ) {
        id = .v7()
        self.name = name
        self.key = key
        kindRaw = kind.rawValue
        self.sortIndex = sortIndex
        self.unit = unit
        defaultValueData = defaultValue.flatMap { try? JSONEncoder().encode($0) }
    }

    public var kind: FieldKind {
        get { FieldKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    public var defaultValue: FieldValue? {
        get { defaultValueData.flatMap { try? JSONDecoder().decode(FieldValue.self, from: $0) } }
        set { defaultValueData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }
}

// MARK: ObjectRecord

/// An instance of a class: a logged set, a workout, a muscle, a note.
/// Objects compose through `parent`/`children` (Workout → exercise entries → sets).
@MainActor
public final class ObjectRecord: TesseraModel, AttachableModel {
    public internal(set) weak var context: TesseraContext?

    public var id: UUID {
        didSet { context?.rekey(self, from: oldValue) }
    }

    public var title: String {
        didSet { didChange() }
    }

    public var sortIndex: Int = 0 {
        didSet { didChange() }
    }

    public var createdAt: Date = .now {
        didSet { didChange() }
    }

    public var updatedAt: Date = .now {
        didSet { didChange() }
    }

    /// Soft delete; hidden from normal queries, recoverable.
    public var deletedAt: Date? {
        didSet { didChange() }
    }

    public var valuesData: Data? {
        didSet { didChange() }
    }

    /// The class's own object (like a metaclass instance): holds class-level values such as
    /// Bench Press's muscles or cues, which every object of the class and its subclasses inherits.
    public var isClassObject: Bool = false {
        didSet { didChange() }
    }

    public var classDef: ClassDef? {
        didSet {
            guard oldValue !== classDef else { return }
            oldValue?.objects.remove(self)
            classDef?.objects.append(self)
            didChange()
        }
    }

    public var parent: ObjectRecord? {
        didSet {
            guard oldValue !== parent else { return }
            oldValue?.children.remove(self)
            parent?.children.append(self)
            didChange()
        }
    }

    /// Inverses, maintained automatically.
    public internal(set) var children: [ObjectRecord]? = []
    public internal(set) var outgoingLinks: [ObjectLink]? = []
    public internal(set) var incomingLinks: [ObjectLink]? = []

    public init(title: String = "", classDef: ClassDef?, parent: ObjectRecord? = nil) {
        id = .v7()
        self.title = title
        self.classDef = classDef
        self.parent = parent
        classDef?.objects.append(self)
        parent?.children.append(self)
    }

    public var isDeleted: Bool {
        deletedAt != nil
    }

    /// Raw stored values; prefer `ObjectStore` accessors, which apply defaults and computed fields.
    public var values: FieldValues {
        get {
            // Decoding JSON on every read dominated long histories; keep the last decode until the data changes.
            let data = valuesData
            if let decoded, decoded.data == data {
                return decoded.values
            }
            let values = data.flatMap { try? JSONDecoder().decode(FieldValues.self, from: $0) } ?? FieldValues()
            decoded = (data, values)
            return values
        }
        set {
            // No-op writes don't dirty the record (and don't create sync traffic).
            guard newValue != values, let data = try? Self.encoder.encode(newValue) else { return }
            valuesData = data
            decoded = (data, newValue)
            updatedAt = .now
        }
    }

    private var decoded: (data: Data?, values: FieldValues)?

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    /// Live children in order, excluding soft-deleted ones.
    public var orderedChildren: [ObjectRecord] {
        (children ?? []).filter { !$0.isDeleted }.sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
    }
}

// MARK: ObjectLink

/// A typed reference from one object's field to another object or to a class.
/// Stored as rows so backlinks ("used in 12 workouts") are an index lookup, not a scan of JSON.
@MainActor
public final class ObjectLink: TesseraModel, AttachableModel {
    public internal(set) weak var context: TesseraContext?

    public var id: UUID {
        didSet { context?.rekey(self, from: oldValue) }
    }

    /// The `FieldDef.id` this link belongs to.
    public var fieldID: UUID {
        didSet { didChange() }
    }

    public var sortIndex: Int {
        didSet { didChange() }
    }

    public var createdAt: Date = .now {
        didSet { didChange() }
    }

    public var from: ObjectRecord? {
        didSet {
            guard oldValue !== from else { return }
            oldValue?.outgoingLinks.remove(self)
            from?.outgoingLinks.append(self)
            didChange()
        }
    }

    /// Exactly one of `toObject` / `toClass` is set.
    public var toObject: ObjectRecord? {
        didSet {
            guard oldValue !== toObject else { return }
            oldValue?.incomingLinks.remove(self)
            toObject?.incomingLinks.append(self)
            didChange()
        }
    }

    public var toClass: ClassDef? {
        didSet {
            guard oldValue !== toClass else { return }
            oldValue?.incomingLinks.remove(self)
            toClass?.incomingLinks.append(self)
            didChange()
        }
    }

    /// An unrelated link; set `from` and a target afterwards.
    public init(fieldID: UUID, sortIndex: Int = 0) {
        id = .v7()
        self.fieldID = fieldID
        self.sortIndex = sortIndex
    }

    public convenience init(
        from: ObjectRecord,
        fieldID: UUID,
        toObject: ObjectRecord? = nil,
        toClass: ClassDef? = nil,
        sortIndex: Int = 0
    ) {
        self.init(fieldID: fieldID, sortIndex: sortIndex)
        self.from = from
        self.toObject = toObject
        self.toClass = toClass
    }
}

// MARK: ViewDef

/// A saved presentation of a class's objects (list, board, calendar…).
@MainActor
public final class ViewDef: TesseraModel, AttachableModel {
    public enum Layout: String, Codable, CaseIterable, Sendable {
        case list, board, calendar, gallery
    }

    public internal(set) weak var context: TesseraContext?

    public var id: UUID {
        didSet { context?.rekey(self, from: oldValue) }
    }

    public var name: String {
        didSet { didChange() }
    }

    public var layoutRaw: String {
        didSet { didChange() }
    }

    public var sortIndex: Int = 0 {
        didSet { didChange() }
    }

    public var filterData: Data? {
        didSet { didChange() }
    }

    public var classDef: ClassDef? {
        didSet {
            guard oldValue !== classDef else { return }
            oldValue?.views.remove(self)
            classDef?.views.append(self)
            didChange()
        }
    }

    public init(name: String = "", layout: Layout = .list) {
        id = .v7()
        self.name = name
        layoutRaw = layout.rawValue
    }

    public var layout: Layout {
        get { Layout(rawValue: layoutRaw) ?? .list }
        set { layoutRaw = newValue.rawValue }
    }
}

// MARK: OpRecord

/// One entry in the append-only operation log: a typed action, who did it, and the ops it applied.
/// State tables (objects, links) are the fast cache; this log is the history behind undo, receipts and export.
@MainActor
public final class OpRecord: TesseraModel, AttachableModel {
    public internal(set) weak var context: TesseraContext?

    public var id: UUID {
        didSet { context?.rekey(self, from: oldValue) }
    }

    /// The typed action's name, e.g. "logSet".
    public var action: String {
        didSet { didChange() }
    }

    public var actorRaw: String {
        didSet { didChange() }
    }

    public var stateRaw: String {
        didSet { didChange() }
    }

    /// One line, in Tess's voice, for receipts: "Logged bench press 82.5 × 8".
    public var summary: String {
        didSet { didChange() }
    }

    public var createdAt: Date = .now {
        didSet { didChange() }
    }

    public var updatedAt: Date = .now {
        didSet { didChange() }
    }

    /// The encoded `[Op]`, in the order applied.
    public var opsData: Data? {
        didSet { didChange() }
    }

    /// Objects this action touched, for "what changed this?" lookups.
    public var objectIDs: [UUID] = [] {
        didSet { didChange() }
    }

    /// For Tess's actions: which route produced it (grammar, on-device, Claude). Nil for everything else.
    public var routeRaw: String? {
        didSet { didChange() }
    }

    /// For model routes: the model's name, e.g. "claude-haiku-5-5".
    public var model: String? {
        didSet { didChange() }
    }

    /// The time zone it was logged in ("America/New_York"); nil for rows from before v3, meaning the device's zone.
    public var zone: String? {
        didSet { didChange() }
    }

    public var route: OpRoute? {
        routeRaw.flatMap(OpRoute.init(rawValue:))
    }

    public init(action: String, actor: Actor, summary: String, ops: [Op], state: OpState) {
        id = .v7()
        self.action = action
        actorRaw = actor.rawValue
        self.summary = summary
        stateRaw = state.rawValue
        opsData = try? JSONEncoder().encode(ops)
        var seen = Set<UUID>()
        objectIDs = ops.map(\.objectID).filter { seen.insert($0).inserted }
    }

    public var actor: Actor {
        Actor(rawValue: actorRaw) ?? .user
    }

    public var state: OpState {
        get { OpState(rawValue: stateRaw) ?? .committed }
        set {
            stateRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    public var ops: [Op] {
        opsData.flatMap { try? JSONDecoder().decode([Op].self, from: $0) } ?? []
    }
}

/// Which of Tess's routes performed an action, kept on its op record for receipts ("via Claude") and evals.
public enum OpRoute: String, Codable, Sendable, CaseIterable {
    case grammar, onDevice, claude
}
