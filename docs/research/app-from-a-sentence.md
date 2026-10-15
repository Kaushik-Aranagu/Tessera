# App from a sentence: "I want to track my plants"

For: Product lead, Core engine, Design studio
Date: 2026-10-15. Checked against origin/master `5956550`.

**The idea in one line.** Tess (Claude, through the model layer) turns a sentence into one `proposeClass` tool call; the kernel validates it and applies it as one pending op group; the person sees the new class as a ghost of its own page and accepts with one tap. Reuse comes before creation, and a List comes before a class.

**What master has, and what this needs (verified).**
- `ClassDef` (name, parent, traits, symbolName, colorRole, systemKey, packageID/Version, isUserModified), `FieldDef` (stable id, `key`, kind, isRequired, unit, enumOptions, targetClassID, expression, overridesFieldID, isUserModified), `ViewDef` (layout `list | board | calendar | gallery`, `filterData`; no sort or group yet).
- `FieldKind`: text, number, bool, date, duration, mass, choice, ref, refList, classRef, computed, richText. `ClassTrait`: schedulable, timed, trackable, measurable.
- `ObjectStore.createClass(name:parent:...)` exists for the class editor, but it writes straight to the context. **`Op` has no schema cases** (only create, softDelete, restore, setTitle, setSortIndex, setValue, setLinks), so creating a class or field today is not in the op log, cannot be a ghost and cannot be undone. Slice A1 fixes this first.
- `ActionDescriptor.Parameter` is flat (`string | number | integer | boolean | date | object | classRef | json`) and `TessTools` hides `.json` parameters. A nested tool like `proposeClass` needs `.json` parameters to carry a JSON Schema (slice A2), so the "no hand-written Claude tools" rule from `tess-model-layer.md` section 11 still holds.
- No `Habit` or `Chore` class on master yet (M3 slice 2, M5 Upkeep slice 1). Reuse rows below that name them apply once those land; until then the matcher simply cannot pick them.

## What others do (lessons, not a survey)

- **Notion "Build with AI"** shows suggested properties first; you add, remove or re-prompt, press Continue, then choose a view. It cannot edit an existing database or create rows. Lesson: schema preview, then view; we also extend existing classes (`proposeFields`).
- **Airtable Omni** builds the base, interface and automations from a prompt, then you review; automations stay off until you switch them on. Lesson: anything that acts on its own ships off; and we preview before the write, not after.
- **Tana** autotag picks only from tag candidates you list, and all AI output goes through Tana Paste before insertion. Lesson: give the model the catalog as candidates and force every output through one parser (our `ActionRegistry.decode`).
- **Capacities** says to make a new object type only when a group has its own properties; otherwise use tags or collections. Lesson: that is our matching rule, with List as the "collection".
- **Google Opal** turns a prompt into a visual workflow you then edit by prompt or by hand. Lesson: the generated thing is the editable thing; the preview is the real page, not a summary card.
- **Our own `add-a-field.md`**: Tana's data-first gentle slope and Bret Victor's "show the data". Lesson: sample rows in the preview make an abstract schema concrete.

## 1. The flow

1. **Sentence.** Typed or spoken into the ghost row: "I want to track my plants". The grammar has no parse for "track my X" / "I want to log X" / "make an app for X", so it marks the request `TessUse.buildClass` and routes straight to Claude (the on-device model is skipped: the catalog alone is ~2K tokens, as with questions).
2. **Local pre-match** (section 2) runs on the phone first. An exact hit ("track my weight" with BodyWeight present) never calls Claude.
3. **Claude** (Sonnet 5.5, `effort: low`, about $0.01 a call) gets the sentence and the catalog pack, and answers with exactly one of `proposeClass`, `proposeFields`, `proposeList`, `useExisting` or `clarify`.
4. **Kernel validates** (section 4). A rejection goes back to Claude as the tool's "Error: ..." string for one retry, as in `tess-model-layer.md` pitfall "invents names"; a second rejection shows the reason to the person.
5. **Ghost preview.** The action runs `pending: true`: class, fields and starter view exist as ghosts. The preview is the class's own future page, drawn faint: the name in the hero tier, each field as a row with its kind word ("Location · choice: kitchen, bedroom, balcony"), the parent as a breadcrumb (`Thing / Plant`), and 2 or 3 sample objects in the starter view. Tapping a kind word cycles it (the add-a-field rule); swiping a field away drops it from the pending record before accept.
6. **One tap to accept** commits the record. **No auto-commit after 2 s** here, unlike capture ghosts: schema is a bigger write, so it waits for the tap. Dismiss discards everything.
7. **Undo** stays one tap away afterwards (section 5).

**Sample objects are preview-only.** They are rendered from the proposal in memory and never written, so a fake "Monstera" never lands in his data. The exception: real names in the sentence ("track my monstera and pothos") become real objects in the same op group.

## 2. Reuse first: the matching rule

Runs in this order; the first rule that fires wins. Names are normalized (lowercased, trailing "s"/"es" dropped, "my"/"the" stripped) and compared to class names, field names and a small alias table shipped with the system package (Chore: chores, upkeep, cleaning; Habit: habit, x times a week; BodyWeight: weight, bw).

1. **Same class exists** (normalized name or alias equal): `useExisting`, open it, no write. "track my plants" when Plant exists opens Plant.
2. **It is a flat collection of names to tick off** (to watch, to buy, to pack, ideas, wishlist): `proposeList`. The phone matches the name against existing List objects itself (list names are never sent) and reuses or copies, per `lists-templates.md`.
3. **A recurring action with an interval** ("water", "clean", "every N days"): a `Chore` object, not a class. With a weekly count ("4 times a week"): a `Habit` object. These are objects of system classes, created through their existing actions.
4. **A one-off dated thing** ("call mom sunday"): a Task through normal capture, not this use.
5. **A thing with its own properties**: `proposeClass`, parent = the nearest system class that already carries some of the fields (Activity for things with a date and duration, Note for dated text, else Thing). Fields that exist on the parent are inherited, not repeated. A proposed field whose normalized name matches a field anywhere in the catalog reuses that field's kind, unit and options ("rating" is always the same shape).
6. **A property for a class that exists** ("add a rating to my books"): `proposeFields`.

Plants combine rules 5 and 3: a `Plant` class (Thing) plus, once Chore lands, one ghost Chore "Water plants" with `about` linking to all plants, in the same op group. The plants example is deliberately close to Upkeep: the watering lives in Chore, the plant only holds what a plant is.

## 3. Tool schema

Strict JSON, generated from the descriptor (all properties required, optional ones nullable, `additionalProperties: false`, 6 nullable fields, under the 24-optional limit). `kind` is the real `FieldKind` minus `computed`, `classRef` and `richText` in v1.

```json
{ "name": "proposeClass", "strict": true,
  "description": "Propose ONE new class for what the person wants to track. Prefer existing classes; never repeat inherited fields.",
  "input_schema": { "type": "object", "additionalProperties": false,
    "required": ["name","parent","traits","fields","view","examples"],
    "properties": {
      "name":   { "type": "string", "description": "Singular, Title Case, max 32 chars" },
      "parent": { "type": ["string","null"], "description": "Existing class name; null means Thing" },
      "traits": { "type": "array", "items": { "enum": ["schedulable","timed","trackable","measurable"] } },
      "fields": { "type": "array", "items": { "type": "object", "additionalProperties": false,
        "required": ["name","kind","required","unit","options","target"],
        "properties": {
          "name": { "type": "string" },
          "kind": { "enum": ["text","number","bool","date","duration","mass","choice","ref","refList"] },
          "required": { "type": "boolean" },
          "unit":    { "type": ["string","null"] },
          "options": { "type": ["array","null"], "items": { "type": "string" } },
          "target":  { "type": ["string","null"], "description": "Class name for ref/refList" } } } },
      "view": { "type": "object", "additionalProperties": false, "required": ["layout","sort","group"],
        "properties": { "layout": { "enum": ["list","board","calendar","gallery"] },
          "sort":  { "type": ["string","null"], "description": "Field name, prefix '-' for descending" },
          "group": { "type": ["string","null"], "description": "A choice or ref field name" } } },
      "examples": { "type": "array", "items": { "type": "object", "additionalProperties": false,
        "required": ["title","values"], "properties": { "title": { "type": "string" },
          "values": { "type": "array", "items": { "type": "string" }, "description": "One per field, in order; '' for empty" } } } }
} } }
```

Siblings, same rules: `proposeFields {class, fields[]}` (same field item), `proposeList {name, items[]}`, `useExisting {class}`, `clarify {question, options[2..3]}`. `clarify` and `useExisting` write nothing. `examples.values` is an array, not a map, because strict mode forbids open objects.

```swift
public struct ProposeClass: EngineAction {
    public struct Field: Codable, Sendable { var name: String; var kind: FieldKind; var required: Bool
                                             var unit: String?; var options: [String]?; var target: String? }
    public struct View: Codable, Sendable { var layout: ViewDef.Layout; var sort: String?; var group: String? }
    public struct Example: Codable, Sendable { var title: String; var values: [String] }
    var name: String; var parent: String?; var traits: [ClassTrait]
    var fields: [Field]; var view: View; var examples: [Example]   // examples never reach apply()

    public static let descriptor = ActionDescriptor(name: "proposeClass", summary: "Propose one new class",
        parameters: [.init("proposal", .json, "The class", schema: ClassProposalSchema.json)])   // A2 adds `schema:`

    @MainActor public func apply(_ tx: inout Transaction) throws -> ClassDef {
        let plan = try ClassProposalValidator(store: tx.store).validate(self)   // throws ProposalRejection
        let cls = tx.createClass(name: plan.name, parent: plan.parent, traits: plan.traits)  // Op.createClass
        for f in plan.fields { tx.addField(f, to: cls) }                         // Op.addField, key made by the engine
        tx.createView(plan.view, for: cls)                                       // Op.createView, sort/group in filterData
        for title in plan.realObjects { _ = tx.create(cls, title: title) }      // only names from the sentence
        return cls
    }
}
```

## 4. What the kernel validates

`ClassProposalValidator` is pure engine code, runs inside `apply`, and is the real gate whatever the model or schema mode does. Every rejection is a `ProposalRejection` with one plain line that is both the tool error Claude retries on and the line shown to the person.

| Check | Rule | Reason line |
|---|---|---|
| Name unique | Normalized name differs from every class and alias, and edit distance > 1 from each | "Plant already exists. Open it, or add fields to it." |
| Reserved names | Not Class, Field, View, Op, Tess, System, Me, nor any system class name; field names not title, id, name, created, updated, deleted, parent, class | "Title is built in; every object has one." |
| Name shape | 1 to 32 chars; letters, digits, spaces, `'`, `&`, `-`; no control characters, newlines or `( ) { } = + * / $ @ :` | "Names can only be words." |
| Kinds valid | Decodes to `FieldKind` and is in the v1 allow-list | "Computed fields come later; I left Volume as a number." |
| No formula injection | No `computed` kind and no `expression` anywhere; `FieldDef.key` is generated by the engine (camelCase of the name), never taken from the model; default values not accepted | "Formulas are yours to write, not mine." |
| Field limit | At most 8 own fields; field names unique within the class and not repeating an inherited field | "Eight fields is the limit. Pick the ones that matter." |
| Parent exists | Resolves by name to one class; not a composition part (Set, Exercise Entry, Recipe Line, Recipe Step, Slot, List Item, Process) | "Plants can't sit under Set." |
| Refs resolve | `target` names an existing class or the new class itself | "No class called Pot; add it first." |
| Traits compatible | Known trait; `timed` needs a date or duration field (own or inherited), `measurable` a number, mass or duration, `schedulable` a date; inherited traits dropped quietly | "Timed needs a date or a duration." |
| Units and options | Unit only on number, mass, duration, and from the unit table; `options` only on choice, 2 to 12 options of 1 to 30 chars, unique | "Choice needs at least two options." |
| View valid | `sort` and `group` name a field of the class; `board` needs a choice or ref group; `calendar` needs a date | "A calendar needs a date field." |
| Size caps | Whole call under 4 KB; at most 3 examples; at most one class per call; at most 2 pending schema records at once | "One new thing at a time." |

## 5. Undo and evolution

- **One op group.** A1 adds `Op.createClass(id, name, parent, traits, symbol, colorRole)`, `Op.addField(field: FieldSnapshot)`, `Op.createView(...)`, with inverses `retireClass`, `retireField`, `retireView` (soft, like objects: a `retiredAt` date on ClassDef, FieldDef and ViewDef; hard delete only in `resetUserData`). The whole proposal is one `OpRecord`, `action: proposeClass`, `actor: .tess`, `route: claude` (T1 columns), so "what Tess did" lists it as one line: "Made Plant: 5 fields, a list by location."
- **Undo before anything else happens** reverts the record: class, fields, view and any real objects it made are retired or soft-deleted. Redo brings them back with the same ids.
- **Undo after he added objects.** The guarded replay finds live objects of the class that the record did not create, and does not overwrite them: the outcome is a conflict, and the page says "Plant has 4 plants you added. Delete Plant and them?" That is the delete below, run by him, never by Tess.
- **Deleting a class with objects** (user only; `DeleteObject` and class delete stay off every model route): one record that retires the class, its fields and views, and soft-deletes its objects and their links; undo restores all of it. Subclasses block the delete ("Move or delete Fern first"). A class still linked from other classes' ref fields keeps working links to retired objects, shown as "(deleted)".
- **Evolution.** A Tess-made class gets `packageID: "me"`, version 0; it is his from birth, so later edits are ordinary schema ops, not overlays. When the target is a shipped class, the existing overlay rule holds (`isUserModified`, package upgrades keep his edits). `proposeFields` only adds; it never renames, changes kind or removes. A kind change on a field with values is the add-a-field migration ("38 values convert, 2 stay as text"), one record, user only.

## 6. Fifteen sentences

Catalog: master plus Habit, Chore, BodyWeight (M3/M5), Recipe and List as on master, no Book or Money classes.

| # | Sentence | Expected | Why |
|---|---|---|---|
| 1 | I want to track my plants | `proposeClass` Plant (Thing): species text, location choice, light choice (low, medium, bright), got on date; list grouped by location. Plus ghost Chore "Water plants" about all plants | Rule 5 plus 3 |
| 2 | Track my plants (Plant exists) | `useExisting` Plant, open it, no write | Rule 1 |
| 3 | Track my weight | Open BodyWeight, no write (local pre-match, no Claude call) | Rule 1 via alias |
| 4 | Movies I want to watch | `proposeList` "Movies to watch" | Rule 2 |
| 5 | Packing list for Lisbon | `proposeList`; the phone sees reusable "Packing" and offers Copy as "Packing, Lisbon" | Rule 2, matched locally |
| 6 | I want to meditate 4 times a week | Habit "Meditate", target 4; no class | Rule 3 |
| 7 | Clean the bathroom every 2 weeks | Chore "Clean bathroom", interval 14 | Rule 3 |
| 8 | Remind me to call mom sunday | Not this use; capture makes a Task | Rule 4 |
| 9 | Log the books I read | `proposeClass` Book (Thing): author text, finished date, rating number, format choice (paper, ebook, audio); list sorted -finished. Reuse Book instead once Reading ships it | Rule 5 |
| 10 | Log my runs | `proposeClass` Run (Activity, timed, measurable): distance number km, time duration, feel choice (easy, ok, hard); list sorted -date | Parent reuse |
| 11 | Add a rating to my books | `proposeFields` Book: rating number (reuses the catalog's rating shape) | Rule 6 |
| 12 | Recipes I want to try | `proposeFields` Recipe: "to try" bool; view filter later | Recipe exists; no duplicate class |
| 13 | Track my coffee | `clarify` "Each cup you drink, or the beans you buy?" Cup leads to Coffee (Activity: drink choice, at date); beans to Beans (Thing: roaster, origin, roast date, rating) | Ambiguous |
| 14 | Make me a CRM | `clarify` "That's a few apps. Start with the people you keep in touch with?"; yes leads to Person (Thing: last talked date, met how text, birthday date) | Too big; one class per call |
| 15 | Track my expenses | `clarify` "Money is coming as its own app. Make a simple Expense for now?"; yes leads to Expense (Thing: amount number, unit £, category choice, on date) | Overlaps M5 Money; ask, don't fork |

Eval target (in the T5 harness): these 15 plus 25 more, 0 duplicate classes, 0 rejected proposals reaching the person on the first 15, and every List-shaped sentence routed to a List.

## 7. Privacy: what is sent

| Leaves the phone | Never sent |
|---|---|
| The sentence | Any object: titles, values, list names, list items, notes, sets, health |
| The catalog: class names with parent, traits, own field names, kinds, units and choice options; the alias table | Counts of objects, dates, the op log |
| The tool schemas and stable instructions (cached prefix) | The API key outside the auth header |

List matching (rule 2) and BodyWeight-style exact hits run on the phone, which is why list names never need to leave. The context pack for `buildClass` gets its own snapshot test (T4). The cloud mark shows on the bloom during the call. Offline or capped: "Needs a connection. Start from a shape?" opens M3 slice 10's Tracker / List / Log with the name from the sentence.

## 8. Smallest first version

**v1:** "track my X" makes one `proposeClass` call to Claude with the class catalog; the kernel validates it (the section 4 table), applies class, up to 8 fields and a list view as one pending op group, shows it as the ghost of its own page with preview-only samples, and one tap commits it, with undo removing it all. Reuse in v1 is rules 1, 2 and 6 only; Chore and Habit routing follows when those classes exist.

| # | Slice | Done when | Type |
|---|---|---|---|
| A1 | **Schema ops in the op log** | `Op` gains createClass, addField, createView and their retire inverses; ClassDef, FieldDef, ViewDef get `retiredAt` (GRDB migration); class editor and add-a-field (M3 3, 6) write through them. Tests: a pending class with 3 fields and a view, discarded, leaves no trace; commit then undo then redo keeps ids; undo with a foreign object returns a conflict and changes nothing | Engine |
| A2 | **Validator and tools** | `ClassProposalValidator` with every row in section 4 as a Swift Testing row (40 rows, each asserting its reason line); `.json` parameters carry a JSON Schema; `proposeClass`, `proposeFields`, `proposeList`, `useExisting`, `clarify` in `ActionRegistry` with decoders; `definitionsJSON(for: .buildClass)` passes the strict-schema registry test | Engine |
| A3 | **Build-class route** | Local pre-match (rules 1, 2), `TessUse.buildClass` on Sonnet 5.5 with the catalog pack, one retry on rejection, offline falls back to slice 10 shapes; the 15 sentences pass in `swift run tess-eval --route claude` with 0 duplicate classes; pack snapshot test proves no object data is sent | Engine |
| A4 | **Ghost class page** | The proposal drawn as its own future page, faint: hero name, breadcrumb parent, field rows with tappable kind words, samples in the starter view; accept is one tap, dismiss discards; no auto-commit; no form, no cards, per `tessera-design` | Feature screen |
| A5 | **Evolve and delete** | `proposeFields` on existing and shipped classes (overlay with `isUserModified`); user-only class delete with objects as one undoable record; subclasses block it | Engine + Feature screen (rough) |

**Order and dependencies.** After M3 slice 3 (add a field: inference, the reuse-by-name rule), slice 6 (class inspector: where an accepted class lives) and slice 10 (starting shapes: the offline fallback and the List rule), and after model-layer T1 (router, `route`/`model` columns), T2 (shared registry, strict schemas) and T3 (Claude route, key, cap). Then A1, A2, A3, A4, A5. Chore and Habit reuse rows wait on M3 slice 2 and M5 Upkeep slice 1; they are not blockers.

## Defaults taken

- DEFAULT: one class per call; "CRM"-sized asks clarify toward the first class.
- DEFAULT: samples are preview-only; only names written in the sentence become objects.
- DEFAULT: schema ghosts never auto-commit; one tap accepts.
- DEFAULT: no computed fields, classRef or richText from Tess in v1; formulas stay his.
- DEFAULT: Sonnet 5.5 for `buildClass` (rare, quality matters, about $0.01 a call).
- DEFAULT: ViewDef sort and group live in `filterData` JSON in v1; no new columns.

## Unverified

- Whether the Claude for Foundation Models package sends nested `DynamicGenerationSchema` arguments as strict tools; `ActionRegistry.decode` plus the validator are the gate either way.
- Sonnet 5.5 token counts for the catalog pack (~2K estimated; measure in A3).

## Sources

- [Notion: Create a database (Build with AI)](https://www.notion.com/help/create-a-database), [Notion AI for databases](https://www.notion.com/help/autofill)
- [Airtable Omni builds bases, interfaces and automations from prompts](https://createwith.com/tool/airtable/updates/airtable-omni-builds-bases-interfaces-and-automations-from-prompts), [Maginative on Omni](https://www.maginative.com/article/airtable-bets-big-on-ai-agents-with-omni-reboots-as-an-ai-native-app-platform/)
- [Tana: AI for builders](https://outliner.tana.inc/learn/features/ai-for-builders), [Tana supertags](https://tana.inc/docs/supertags)
- [Capacities: when to create a new object type](https://docs.capacities.io/tutorials/when-to-create-new-object-type)
- [Google Opal launch](https://the-decoder.com/google-launches-opal-build-ai-mini-apps-with-natural-language-no-coding-needed/)
