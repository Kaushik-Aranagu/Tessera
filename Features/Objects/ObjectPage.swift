import SwiftUI
import TesseraCore

/// One page for every class and object: path, hero name, class line, summary numbers, properties (inherited
/// ones marked ↑), contents, history, subclasses and backlinks — all rendered from the object model.
struct ObjectPage: View {
    let route: Route
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        // Exercises and plans have their own object pages (Features/Exercise, Features/Plans).
        if case let .classDef(id) = route, let classDef = model.classDef(id: id),
           ExerciseRouting.isExercise(classDef, classes: model.classes)
        {
            ExercisePage(exercise: classDef)
        } else if let plan = ExerciseRouting.plan(for: route, model: model) {
            PlansView(plan: plan.object)
        } else if case let .object(id) = route, let routine = model.object(id),
                  routine.classDef?.id == model.classDef(.routine)?.id
        {
            // A routine's page is its editor (Features/Plans/RoutineEditor).
            RoutineEditor(routine: routine)
        } else {
            generic
        }
    }

    private var generic: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                switch route {
                case let .classDef(id):
                    if let classDef = model.classDef(id: id) {
                        ClassBody(classDef: classDef)
                    }
                case let .object(id):
                    if let object = model.object(id) {
                        InstanceBody(object: object)
                    }
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

// MARK: - Class page

private struct ClassBody: View {
    let classDef: ClassDef
    @Environment(AppModel.self) private var model

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

        if let notes = prototype.flatMap({ model.store.value("notes", of: $0)?.stringValue }) {
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
                        ObjectRow(title: item.workout.title, route: .object(item.workout.id)) {
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
                withTesseraAnimation(reduceMotion: false) { model.isCommandExpanded = true }
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
        var counts: [String: (ObjectRecord, Int)] = [:]
        for session in history {
            let key = session.workout.title
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
            Stat(label: "Best e1RM", value: best.map { "\(Format.kilograms(($0.e1RM * 10).rounded() / 10))kg" } ?? "—",
                 tint: Theme.Colors.ink)
            Stat(label: "Last top set", value: top.map { "\(Format.kilograms($0.weight))×\(Int($0.reps))" } ?? "—")
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

        Header(
            path: lineage.map { ($0.name, Route.classDef($0.id)) },
            title: object.title.isEmpty ? "Untitled" : object.title,
            classLine: "object \(Format.identifier(object.title, upperFirst: false)) : "
                + Format.identifier(object.classDef?.name ?? "Thing", upperFirst: true)
        )

        if let notes = model.store.value("notes", of: object)?.stringValue {
            Text(notes).textRole(.body).foregroundStyle(Theme.Colors.inkSecondary).entrance(4)
        }

        if let classDef = object.classDef {
            PropertyList(classDef: classDef, object: object).entrance(5)
        }

        if !children.isEmpty {
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

        if !backlinks.isEmpty {
            MarginSection(label: "Linked from") {
                VStack(spacing: 0) {
                    ForEach(backlinks) { source in
                        if let classDef = source.classDef, model.prototype(of: classDef)?.id == source.id {
                            ObjectRow(title: classDef.name, route: .classDef(classDef.id))
                        } else {
                            ObjectRow(title: source.title, route: .object(source.id))
                        }
                    }
                }
            }
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
            ObjectRow(
                title: child.title.isEmpty ? child.classDef?.name ?? "Item" : child.title,
                route: .object(child.id)
            )
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
                            if index < shown.count - 1 {
                                Text("/").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
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
                .foregroundStyle(Theme.Colors.training)
                .entrance(3)
        }
    }
}

private struct PropertyList: View {
    let classDef: ClassDef
    let object: ObjectRecord?
    @Environment(AppModel.self) private var model

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

    private func row(_ field: ResolvedField) -> some View {
        let inherited = field.declaringClassID != classDef.id
        return HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(field.name).textRole(.body).foregroundStyle(Theme.Colors.inkSecondary)
                if inherited {
                    Text("↑").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
                        .accessibilityLabel("inherited")
                }
            }
            Spacer(minLength: Theme.Spacing.m)
            value(field).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, Theme.Spacing.m)
    }

    @ViewBuilder private func value(_ field: ResolvedField) -> some View {
        switch field.kind {
        case .ref, .refList:
            let targets = object.map { model.store.linkedObjects(field.key, of: $0) } ?? []
            if targets.isEmpty {
                dash
            } else {
                VStack(alignment: .trailing, spacing: Theme.Spacing.s) {
                    ForEach(targets) { target in ObjectHandle(title: target.title, route: .object(target.id)) }
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
                Text(field.kind == .computed ? "ƒ \(field.expression ?? "")" : "—")
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkTertiary)
            }
        }
    }

    private var dash: some View {
        Text("—").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Hairline()
            ForEach(items, id: \.self) { item in
                Button { perform(item) } label: {
                    HStack(spacing: Theme.Spacing.s) {
                        Text(item)
                        Image(systemName: "arrow.right").font(.system(size: 17, weight: .semibold))
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
