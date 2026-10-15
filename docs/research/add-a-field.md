# Add a field without programming

For: Product lead, Core engine, Design studio
Date: 2026-10-15
Covers M3 slices 3 (add a field), 6 (Class inspector), 10 (class from a template).

## What the others do

- **Notion**: "Add a property", then pick a type from a long list before typing anything. Type first is the most programmer-like step in the flow. Changing type later works but can drop values. [1]
- **Airtable**: type first too, but paste and import guess types, and AI can suggest and fill fields. [2]
- **Tana**: type `weight::` on any node and the field exists right there, on that one object. You can later promote it to the supertag (class). Data first, schema later. This is the gentlest slope we found. [3]
- **Capacities**: properties live on the object type and are edited in its settings, with a few shown on each object page. Clean, but you leave the object to change the class. [4]
- **Anytype**: relations are shared objects you reuse across types; the format is chosen at creation. Reuse is great; locked format hurts later. [5]
- **Shortcuts / Numbers**: Numbers formats a cell from what you type (72 kg stays text, 72 becomes a number, 1/5 becomes a date). Shortcuts hides types behind "magic variables". Both infer instead of ask.
- **Research**: MacLean et al. call it a "gentle slope": each extra bit of tailoring should cost a small, matching bit of effort, with no cliff [6]. Ink and Switch's malleable software says edits should happen in place, in the thing you use [7]. Bret Victor: show the data and the result immediately, never an empty abstraction [8].

## What feels like programming vs natural

Programming: picking a type before having a value, naming things in a separate screen, irreversible choices, empty schema forms.
Natural: typing a value and the type follows, editing on the object you are looking at, seeing the result live, undo always one tap away, suggestions from what already exists.

## Proposed flows (smallest version)

**1. From an object page (main path).** A ghost row at the end of the fields: "add...". Kaushik types `sleep 7.5 h` or `mood: good`. Live preview under the row shows "Sleep, Duration, 7 h 30 min". Return commits: the field is added to this object's class as an overlay, value set on this object. A quiet line follows: "Added to all Days. Undo". Tap the type word in the preview to cycle to the next best guess. No type picker unless asked.

**2. Class inspector.** Fields listed in big type, inherited ones dimmed with their source class. Same ghost row at the bottom, but the value is optional: `rest time duration` or just `rest time`. Below it, up to 3 suggested fields from sibling and parent classes ("Notes, RPE, Location"), one tap to add. Long press a field: rename, change type, hide.

**3. Class from a template.** Three big words: Tracker, List, Log. Pick one, type a name ("Water"), and the first object page opens straight away with the template fields and the ghost row focused. Type `500 ml` and the Tracker's value field becomes Volume. The class is defined by the first entry, not a form.

## Type inference rules

| Input | Inferred type |
|---|---|
| `72`, `7.5` | Number |
| `72 kg`, `160 lb` | Mass (stored kg) |
| `45 min`, `1:30:00`, `7.5 h` | Duration (stored s) |
| `500 ml`, `2 l` | Volume |
| `today`, `fri`, `12 oct`, `2026-10-12` | Date |
| `yes`, `no`, `done` | Yes/no |
| `good` (one word, repeated later) | Choice, options grow as used |
| `@Bench Press` or a known object name | Link to that class |
| Anything else | Text |

Name rule: words before the value (or before `:`) are the name. If the name matches an existing field on this class or a related one, reuse it (and its ID), do not create a duplicate. Ambiguous cases default to the wider type (Text, Number) and say so in the preview.

## Pitfalls

1. **Renaming.** Names change, IDs do not. Rename is a label edit on the stable field ID, so formulas, views and Tess queries keep working. Keep old names as aliases so "bw" and "weight" both still parse.
2. **Type changes on existing data.** Changing Number to Mass or Text to Choice must convert in place with a preview ("38 values convert, 2 stay as text") and one undo for the whole change. Never drop a value: keep unconvertible ones as raw text flagged on the object. This is where Notion and Anytype bite.
3. **Field sprawl from inference.** Typing on the fly creates "sleep", "Sleep hrs" and "slept". Fuzzy match against existing fields before creating, and offer "use Sleep?" in the preview. Built-in class edits stay overlays so a package update never wipes them.

## Decisions for Kaushik (yes/no)

1. A field added from one object page is added to the whole class at once (Tana makes it object-only first). Proposed: yes, whole class, with undo.
2. Show a type picker only on request (tap the type word), never by default. Proposed: yes.

## Sources

1. Notion, Database properties: https://www.notion.com/help/database-properties
2. Airtable, Using Airtable AI in fields: https://support.airtable.com/docs/using-airtable-ai-in-fields
3. Tana, Fields: https://tana.inc/docs/fields and Supertags: https://tana.inc/docs/supertags
4. Capacities, Content types: https://docs.capacities.io/reference/content-types
5. Anytype, Relations: https://doc.anytype.io/anytype-docs/basics/relations
6. MacLean, Carter, Lovstrand, Moran, "User-tailorable systems: pressing the issues with buttons", CHI 1990: https://doi.org/10.1145/97243.97271
7. Ink and Switch, "Malleable software" (2025): https://www.inkandswitch.com/essay/malleable-software/
8. Bret Victor, "Learnable Programming" (2012): https://worrydream.com/LearnableProgramming/
