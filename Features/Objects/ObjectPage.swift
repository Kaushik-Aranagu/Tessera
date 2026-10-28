import SwiftUI
import TesseraCore

/// The page a page was pushed from: its name for the back word and its own colour (sheet 378).
struct PageSource: Equatable {
    let name: String
    let color: Color
}

/// One page for every class and object: path, hero name, class line, summary numbers, properties (inherited
/// ones marked ↑), contents, history, subclasses and backlinks — all rendered from the object model.
struct ObjectPage: View {
    let route: Route
    /// The page this one was opened from, when it names itself in its back word (sheet 378): "Orchid" in olive on
    /// the routine the orchid's page opened.
    var from: PageSource?
    @Environment(AppModel.self) private var model
    /// Whether this note opens in the editor, decided once per appearance so typing a walled word into a plain
    /// note cannot swap the editor for the masked page mid-sentence.
    @State private var noteLatch: Bool?

    var body: some View {
        content
            .onAppear { latchNoteChoice() }
            .onChange(of: route) { noteLatch = nil; latchNoteChoice() }
    }

    private func latchNoteChoice() {
        guard noteLatch == nil, case let .object(id) = route, let note = model.object(id) else { return }
        noteLatch = Self.opensAsNote(note, model: model)
    }

    @ViewBuilder private var content: some View {
        let _ = model.revision
        // Exercises and plans have their own object pages (Features/Exercise, Features/Plans).
        if case let .classDef(id) = route, let classDef = model.classDef(id: id),
           ExerciseRouting.isExercise(classDef, classes: model.classes)
        {
            ExercisePage(exercise: classDef)
        } else if PagesV2Switch.isOn, case let .object(id) = route, let workout = model.object(id),
                  Self.isFinishedWorkout(workout, model: model)
        {
            FinishedWorkoutPage(workout: workout)
        } else if case .routinesLanding = route {
            // The woodland landing on the shared kit (248); the route only opens while "Landing pages" is On.
            if LandingSwitch.isOn {
                RoutinesWoodlandLandingPage()
            } else {
                RoutinesLandingPage()
            }
        } else if case .routinesBrowse = route {
            RoutinesBrowsePage()
        } else if case let .routines(id) = route, let plan = model.object(id) {
            RoutinesPage(plan: plan)
        } else if let plan = ExerciseRouting.plan(for: route, model: model) {
            PlansView(plan: plan.object)
        } else if case let .object(id) = route, let routine = model.object(id),
                  routine.classDef?.id == model.classDef(.routine)?.id
        {
            // A routine's page is its editor (Features/Plans/RoutineEditor).
            RoutineEditor(routine: routine, from: from)
        } else if case let .object(id) = route, let note = model.object(id),
                  Self.resolveOpensAsNote(latched: noteLatch, live: { Self.opensAsNote(note, model: model) })
        {
            // A note opens as itself, as from Notes, never as a property list of its text (PN-MENTION).
            NoteEditor(noteID: note.id)
        } else {
            generic
        }
    }

    /// A plain note opens in the note editor. A private note stays on the generic page, where Core's mask
    /// shows only the label "Private note" and none of its text.
    static func opensAsNote(_ note: ObjectRecord, model: AppModel) -> Bool {
        note.classDef?.id == model.classDef(.note)?.id
            && ObjectMask.label(of: note, in: model.store, classes: model.classes) == nil
    }

    /// A workout that has ended: its page is the finished workout's page when Pages v2 is on.
    static func isFinishedWorkout(_ object: ObjectRecord, model: AppModel) -> Bool {
        guard let workoutClass = model.classDef(.workout), let objectClass = object.classDef,
              ClassResolver.isSubclass(objectClass, of: workoutClass) else { return false }
        return model.store.value("endedAt", of: object) != nil
    }

    /// The object a link opens, or nil when it is deleted or not on this phone (OL28, OL29).
    static func live(_ object: ObjectRecord?) -> ObjectRecord? {
        object.flatMap { $0.isDeleted ? nil : $0 }
    }

    /// The latched choice once made; the live check only before the first appearance.
    static func resolveOpensAsNote(latched: Bool?, live: () -> Bool) -> Bool {
        latched ?? live()
    }

    private var generic: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                switch route {
                case let .classDef(id):
                    if let classDef = model.classDef(id: id) {
                        ClassBody(classDef: classDef)
                    } else {
                        GoneBody()
                    }
                case let .object(id):
                    // A link to something deleted, or gone from this phone, says so rather than drawing a blank
                    // page (OL28, OL29).
                    if let object = Self.live(model.object(id)) {
                        InstanceBody(object: object)
                    } else {
                        GoneBody()
                    }
                case .routines, .routinesLanding, .routinesBrowse:
                    EmptyView()
                }
            }
            .padding(.leading, Theme.Spacing.gutter - 6)
            .padding(.trailing, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, 180)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
    }
}

// MARK: - Gone

/// What a link opens when its object is deleted or not on this phone: one line, focused for VoiceOver, and a back
/// word (OL28, OL29).
private struct GoneBody: View {
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text(ObjectPageCopy.gone)
                .textRole(.title)
                .wordFit(ObjectPageCopy.gone)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityFocused($focused)
                .accessibilityAddTraits(.isHeader)
            Button(ObjectPageCopy.back) { dismiss() }
                .buttonStyle(.labelWord)
                .frame(minHeight: 44)
        }
        .padding(.top, Theme.Spacing.xxl)
        .onAppear { focused = true }
    }
}

// MARK: - Class page

private struct ClassBody: View {
    let classDef: ClassDef
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let lineage = ClassResolver.lineage(of: classDef)
        let prototype = model.prototype(of: classDef)
        let isExercise = model.classDef(.exercise).map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        let history = isExercise ? model.history(of: classDef) : []
        let subclasses = (classDef.subclasses ?? []).sorted { $0.name < $1.name }
        let workouts = uniqueWorkouts(history)

        Header(path: lineage.dropLast().map { ($0.name, Route.classDef($0.id)) }, title: classDef.name,
               classLine: classLine(lineage))

        if isExercise {
            ExerciseSummary(history: history).entrance(4)
        }

        // The class page's notes pass the same mask as an object's (OL08): a private note reads its label.
        if let notes = ObjectNotes.shown(prototype.flatMap {
            ObjectPrivacy.notesLine(of: $0, in: model.store, classes: model.classes)
        }) {
            Text(notes)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .entrance(5)
        }

        PropertyList(classDef: classDef, object: prototype).entrance(6)

        if !history.isEmpty {
            MarginSection(label: "History") {
                VStack(spacing: 0) {
                    ForEach(Array(history.prefix(5).enumerated()), id: \.element.id) { index, session in
                        HistoryRow(session: session)
                        if index < min(history.count, 5) - 1 {
                            RowSeparator()
                        }
                    }
                }
            }
            .entrance(7)
        }

        if !subclasses.isEmpty {
            MarginSection(label: "Subclasses") {
                VStack(spacing: 0) {
                    ForEach(subclasses) { subclass in
                        ObjectRow(title: subclass.name, route: .classDef(subclass.id)) {
                            Text("\((subclass.subclasses ?? []).count)").textRole(.label)
                                .foregroundStyle(Theme.Colors.inkTertiary)
                                .opacity((subclass.subclasses ?? []).isEmpty ? 0 : 1)
                        }
                    }
                }
            }
            .entrance(8)
        }

        if !workouts.isEmpty {
            MarginSection(label: "Used in") {
                VStack(spacing: 0) {
                    ForEach(workouts, id: \.workout.id) { item in
                        ObjectRow(object: item.workout, in: model) {
                            Text("×\(item.count)").textRole(.data).foregroundStyle(Theme.Colors.inkSecondary)
                        }
                    }
                }
            }
            .entrance(9)
        }

        Actions(items: isExercise ? ["Log a set", "New subclass"] : ["New subclass"]) { action in
            switch action {
            case "Log a set":
                model.commandDraft = "log \(classDef.name.lowercased()) "
                withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = true }
            default:
                // Through the store, so its caches see the new class. (Schema changes join the op log with Build A1.)
                let subclass = model.store.createClass(name: "New \(classDef.name)", parent: classDef,
                                                       symbolName: classDef.symbolName, colorRole: classDef.colorRole)
                model.touch()
                model.open(.classDef(subclass.id))
            }
        }
        .entrance(10)
    }

    private func classLine(_ lineage: [ClassDef]) -> String {
        let name = Format.identifier(classDef.name, upperFirst: true)
        let parent = lineage.dropLast().last.map { " : " + Format.identifier($0.name, upperFirst: true) } ?? ""
        return "class \(name)\(parent)"
    }

    private func uniqueWorkouts(_ history: [AppModel.SessionSummary]) -> [(workout: ObjectRecord, count: Int)] {
        // Grouped by the routine (else the workout) by id, never by the shown word: two private routines both read
        // "Private workout" and stay two rows (OL02).
        var counts: [UUID: (ObjectRecord, Int)] = [:]
        for session in history {
            let key = model.store.linkedObjects("routine", of: session.workout).first?.id ?? session.workout.id
            counts[key] = (counts[key]?.0 ?? session.workout, (counts[key]?.1 ?? 0) + 1)
        }
        return counts.values.map { (workout: $0.0, count: $0.1) }.sorted { $0.count > $1.count }
    }
}

private struct ExerciseSummary: View {
    let history: [AppModel.SessionSummary]

    var body: some View {
        let best = history.flatMap(\.sets).max { $0.e1RM < $1.e1RM }
        let top = history.first?.sets.max { $0.weight * 100 + $0.reps < $1.weight * 100 + $1.reps }
        VStack(spacing: Theme.Spacing.m) {
            // An empty value drops out; no lone dash (decisions 5:57).
            if let best {
                Stat(label: "Best e1RM", value: "\(Format.kilograms((best.e1RM * 10).rounded() / 10))kg",
                     tint: Theme.Colors.ink)
            }
            if let top {
                Stat(label: "Last top set", value: "\(Format.kilograms(top.weight))×\(Int(top.reps))")
            }
            Stat(label: "Sessions", value: "\(history.count)")
        }
    }
}

/// Label left, number hanging right.
private struct Stat: View {
    let label: String
    let value: String
    var tint: Color = Theme.Colors.ink

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).textRole(.body).foregroundStyle(Theme.Colors.inkSecondary)
            Spacer(minLength: Theme.Spacing.m)
            Text(value).textRole(.titleNumber).foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HistoryRow: View {
    let session: AppModel.SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(Format.shortDay(session.date))
                .textRole(.labelStrong)
                .foregroundStyle(Theme.Colors.inkSecondary)
            Text(session.sets.map { "\(Format.kilograms($0.weight))×\(Int($0.reps))" }.joined(separator: "  "))
                .textRole(.data)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.Spacing.m)
    }
}

// MARK: - Object page

private struct InstanceBody: View {
    let object: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        let lineage = object.classDef.map(ClassResolver.lineage(of:)) ?? []
        let backlinks = model.store.backlinks(to: object)
        let children = object.orderedChildren
        // A private object shows only its label: no title, fields, notes or contents (board 0ai mask).
        let privateLabel = ObjectMask.label(of: object, in: model.store, classes: model.classes)
        let shownTitle = ObjectTitle.shown(object, in: model.store, classes: model.classes)

        Header(
            path: lineage.map { ($0.name, Route.classDef($0.id)) },
            title: shownTitle,
            classLine: privateLabel == nil
                ? "object \(Format.identifier(shownTitle, upperFirst: false)) : "
                + Format.identifier(object.classDef?.name ?? "Thing", upperFirst: true)
                : Format.identifier(object.classDef?.name ?? "Thing", upperFirst: true)
        )
        .modifier(AskPageHook(object: object))

        // A workout's notes are a body fact: they read "Note kept private" (Product 5:20 PM PT).
        // The list engine's flag lines ("#reusable", "#pick-one", "picked: …") are the engine's, never shown (QA, K88).
        if privateLabel == nil, let notes = ObjectNotes.shown(ObjectPrivacy.notesLine(
            of: object,
            in: model.store,
            classes: model.classes
        )) {
            Text(notes)
                .textRole(.body).foregroundStyle(Theme.Colors.inkSecondary).entrance(4)
        }

        if privateLabel == nil, let classDef = object.classDef {
            PropertyList(classDef: classDef, object: object).entrance(5)
        }

        if privateLabel == nil, !children.isEmpty {
            MarginSection(label: "Contents") {
                VStack(spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                        ChildRow(child: child)
                        if index < children.count - 1 {
                            RowSeparator()
                        }
                    }
                }
            }
            .entrance(6)
        }

        // A private object lists nothing that links to it either (Design on #580).
        if privateLabel == nil, !backlinks.isEmpty {
            MarginSection(label: "Linked from") {
                VStack(spacing: 0) {
                    ForEach(backlinks) { source in
                        if let classDef = source.classDef, model.prototype(of: classDef)?.id == source.id {
                            ObjectRow(title: classDef.name, route: .classDef(classDef.id))
                        } else {
                            ObjectRow(object: source, in: model)
                        }
                    }
                }
            }
            .entrance(7)
        }

        // Away (187): an occasion's page can quiet Home for its days.
        if privateLabel == nil, AwayHome.isOn, let occasionClass = model.classDef(.occasion),
           let objectClass = object.classDef, ClassResolver.isSubclass(objectClass, of: occasionClass)
        {
            AwayWord(occasion: object).entrance(7)
        }

        // Together (135 §3): what mentions it from other apps, above the doors; none for a private object.
        if privateLabel == nil, Together.isOn(Together.linkColours) {
            MentionedIn(lines: Mentions.lines(of: object, store: model.store, classes: model.classes))
                .entrance(7)
        }

        if let workoutClass = model.classDef(.workout), let objectClass = object.classDef,
           ClassResolver.isSubclass(objectClass, of: workoutClass), model.store.value("endedAt", of: object) == nil
        {
            Actions(items: ["Start workout"]) { _ in model.startWorkout(object) }.entrance(8)
        }
    }
}

private struct ChildRow: View {
    let child: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        if let exercise = model.store.linkedClass("exercise", of: child) {
            ObjectRow(title: exercise.name, route: .classDef(exercise.id)) {
                Text(target(child)).textRole(.data).foregroundStyle(Theme.Colors.inkSecondary)
            }
        } else {
            ObjectRow(object: child, in: model)
        }
    }

    private func target(_ entry: ObjectRecord) -> String {
        let logged = entry.orderedChildren.count
        let sets = Int(model.store.number("targetSets", of: entry) ?? 0)
        let reps = Int(model.store.number("targetReps", of: entry) ?? 0)
        let weight = model.store.number("targetWeight", of: entry).map { "  \(Format.kilograms($0))kg" } ?? ""
        return logged > 0 ? "\(logged) logged" : "\(sets)×\(reps)\(weight)"
    }
}

// MARK: - Shared pieces

private struct Header: View {
    let path: [(String, Route)]
    let title: String
    let classLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            if !path.isEmpty {
                // Long lineages show "… / parent's parent / parent"; "…" goes up to the root.
                let shown = path.count > 2 ? [("…", path[0].1)] + path.suffix(2) : path
                FlowLayout(spacing: Theme.Spacing.s) {
                    ForEach(Array(shown.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: Theme.Spacing.s) {
                            ObjectHandle(title: item.0, route: item.1, relation: .up, role: .label,
                                         color: Theme.Colors.inkSecondary)
                                // "…" is read as where it goes: "Up to Thing" (OL22).
                                .accessibilityLabel(item.0 == "…" ? "Up to \(path[0].0)" : item.0)
                            if index < shown.count - 1 {
                                Text("/").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
                .entrance(1)
            }

            RevealingHero(text: title)
                .accessibilityAddTraits(.isHeader)
                .entrance(2, hero: true)

            Text(classLine)
                .textRole(.data)
                .padding(.top, Theme.Spacing.s)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .entrance(3)
        }
    }
}

private struct PropertyList: View {
    let classDef: ClassDef
    let object: ObjectRecord?
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let fields = ClassResolver.effectiveFields(of: classDef).filter { $0.key != "notes" }
        if !fields.isEmpty {
            MarginSection(label: "Properties") {
                VStack(spacing: 0) {
                    ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                        row(field)
                        if index < fields.count - 1 {
                            RowSeparator()
                        }
                    }
                }
            }
        }
    }

    /// One element per plain property (OL23): "Weight, 60 kg"; a link property contains its handles. At
    /// accessibility sizes the value stacks under its name rather than squeezing beside it (OL24).
    private func row(_ field: ResolvedField) -> some View {
        let inherited = field.declaringClassID != classDef.id
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        return layout {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(field.name).textRole(.body).foregroundStyle(Theme.Colors.inkSecondary)
                if inherited {
                    Text("↑").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
                        .accessibilityLabel("inherited")
                }
            }
            if !stacked {
                Spacer(minLength: Theme.Spacing.m)
            }
            value(field).multilineTextAlignment(stacked ? .leading : .trailing)
        }
        .padding(.vertical, Theme.Spacing.m)
        // A link row keeps each handle its own stop, so every target can be reached (Design on #1075).
        .accessibilityElement(children: [.ref, .refList, .classRef].contains(field.kind) ? .contain : .combine)
    }

    @ViewBuilder private func value(_ field: ResolvedField) -> some View {
        switch field.kind {
        case .ref, .refList:
            let targets = object.map { model.store.linkedObjects(field.key, of: $0) } ?? []
            if targets.isEmpty {
                dash
            } else {
                VStack(alignment: .trailing, spacing: Theme.Spacing.s) {
                    // A private target shows its label, never its words (QA on #580).
                    ForEach(targets) { target in
                        ObjectHandle(object: target, in: model)
                    }
                }
            }
        case .classRef:
            if let target = object.flatMap({ model.store.linkedClass(field.key, of: $0) }) {
                ObjectHandle(title: target.name, route: .classDef(target.id))
            } else {
                dash
            }
        default:
            let value = object.flatMap { model.store.value(field.key, of: $0) } ?? field.defaultValue
            if let value {
                Text(describe(value, unit: field.unit)).textRole(.data).foregroundStyle(Theme.Colors.ink)
            } else {
                // A cell that must show something says "none", never a lone dash (decisions 5:57).
                Text(field.kind == .computed ? "ƒ \(field.expression ?? "")" : ObjectCopy.none)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkTertiary)
            }
        }
    }

    private var dash: some View {
        Text(ObjectCopy.none).textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
    }

    private func describe(_ value: FieldValue, unit: String?) -> String {
        switch value {
        case let .duration(seconds): Format.duration(seconds)
        case let .mass(kg): "\(Format.kilograms(kg))\(unit ?? "kg")"
        case let .number(number): Format.kilograms(number) + (unit ?? "")
        case let .bool(flag): flag ? "yes" : "no"
        case let .date(date): "\(Format.shortDay(date)) \(Format.clock(date))"
        case let .text(text), let .choice(text), let .richText(text): text
        }
    }
}

private struct Actions: View {
    let items: [String]
    let perform: (String) -> Void
    /// The arrow grows with the words beside it (OL25).
    @ScaledMetric(relativeTo: .body) private var arrowSize: CGFloat = 17

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Hairline()
            ForEach(items, id: \.self) { item in
                Button { perform(item) } label: {
                    HStack(spacing: Theme.Spacing.s) {
                        Text(item)
                        Image(systemName: "arrow.right").font(.system(size: arrowSize, weight: .semibold))
                            .accessibilityHidden(true)
                    }
                    .textRole(.bodyStrong)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
            }
        }
    }
}

/// Wraps children onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0,
                      height: rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [(indices: [Int], width: CGFloat, height: CGFloat)] {
        var rows: [(indices: [Int], width: CGFloat, height: CGFloat)] = []
        var current: (indices: [Int], width: CGFloat, height: CGFloat) = ([], 0, 0)
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = ([index], size.width, size.height)
            } else {
                current = (current.indices + [index], needed, max(current.height, size.height))
            }
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

/// The notes an object page prints: his words only. The list engine keeps small flags on the same notes line (the
/// catalog is frozen, so no new field): a whole "#reusable" or "#pick-one" line, or a "picked: <date>" stamp. Those
/// lines never show; nil when nothing else is left.
enum ObjectNotes {
    /// Only the engine's exact stamp, "picked: " and an ISO 8601 date, as Core matches it; a line he typed that
    /// merely starts "picked: " stays (Kitchen on #809).
    static func isPickedStamp(_ line: String) -> Bool {
        guard line.hasPrefix("picked: ") else { return false }
        return (try? Date(String(line.dropFirst("picked: ".count)), strategy: .iso8601)) != nil
    }

    static func shown(_ notes: String?) -> String? {
        let kept = (notes ?? "").split(separator: "\n", omittingEmptySubsequences: false).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed != "#reusable" && trimmed != "#pick-one" && !isPickedStamp(trimmed)
        }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return kept.isEmpty ? nil : kept
    }
}

/// The object page's words.
enum ObjectCopy {
    /// An empty cell that must show something (decisions 5:57): never a lone dash.
    static let none = "none"

    /// A cell's value, or "none" when it has none.
    static func cell(_ value: String?) -> String {
        value ?? none
    }
}

/// What an object page prints in place of a private object's title (G141): Core's label, plus the kinds it doesn't
/// cover yet. An ingredient or a list item with a secret word, money, a body fact or a medicine reads "Private item";
/// such a list reads "Private list". Masked at the source: every row, link and header on the page goes through here,
/// and only the live text field ever shows the raw words.
/// The one shown title for an object on the object page and every row that names it (OL03, OL11): its private
/// label, else its title, else its class name and place ("Set 3"), never blank and never "Untitled".
enum ObjectTitle {
    @MainActor
    static func shown(_ object: ObjectRecord, in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> String {
        if let label = ObjectMask.label(of: object, in: store, classes: classes) {
            return label
        }
        if !object.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return object.title
        }
        let name = object.classDef?.name ?? "Item"
        guard let place = object.parent?.orderedChildren.firstIndex(where: { $0.id == object.id }) else { return name }
        return "\(name) \(place + 1)"
    }
}

enum ObjectMask {
    @MainActor
    static func label(of object: ObjectRecord, in store: ObjectStore,
                      classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        // A private routine or workout reads "Private workout" here too, by Tess's own check (G274, hunt 22).
        let isTraining = [SystemCatalog.Key.workout, .routine].contains { key in
            guard let target = classes[key], let def = object.classDef else { return false }
            return ClassResolver.isSubclass(def, of: target)
        }
        if isTraining, ObjectPrivacy.routineTitle(object.title, in: store) == ObjectPrivacy.routineLabel {
            return ObjectPrivacy.routineLabel
        }
        if let core = ObjectPrivacy.label(of: object, in: store, classes: classes) {
            return core
        }
        if let part = KitchenMask.label(of: object, in: store, classes: classes) {
            return part
        }
        guard let classDef = object.classDef else { return nil }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        // The same set as AddListItem's private item: secret words, money, body facts and medicines (QA on #912).
        let walled = ObjectPrivacy.isPrivateWord(object.title, in: store)
        guard walled else { return nil }
        if isA(.ingredient) || isA(.listItem) {
            return ShopTrip.privateLabel
        }
        return isA(.list) ? "Private list" : nil
    }
}

/// The object page's own words.
enum ObjectPageCopy {
    /// A link whose object is deleted or not on this phone (OL28, OL29).
    static let gone = "Not on this phone anymore"
    static let back = "Back"
}
