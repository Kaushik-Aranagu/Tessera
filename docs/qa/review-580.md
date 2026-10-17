# QA review: #580 Core 0ai part 1, private-field mask on the object page

Reviewed static (no Swift toolchain). Full depth (privacy). Merge-tree clean on master.

## 5e54dbf (first head)
- F1 (closed in e54cbdd): a workout's notes were omitted; walls-ui PM21-PM24, PM33, PM34 expect exactly one line "Note kept private" (no words, no count), never on PM25-PM27.
- Design F (closed in e54cbdd): "Linked from" still printed on a private object's own page.
- F2 (OPEN, see below).

## e54cbdd (delta, PASS)
- ObjectPage.swift InstanceBody: notes slot now prints `ObjectPrivacy.keptNoteLabel` ("Note kept private") for a workout and the notes for anything else; still gated by `privateLabel == nil`. One line, same text whatever the note says, no count.
- Linked from gated by `privateLabel == nil`. A private object shows its label, class line and breadcrumb only.
- Labels: "Private note" (SecretWords.title), "Private memory", "Private task". No Catalog or migration change. Tests: memories, notes, tasks, workout notes, plus the new label constant.

## F2 (low, one line, fix when next in the file)
PropertyList `.ref` / `.refList` (ObjectPage.swift:396) still prints `target.title` for the target of a ref. A non-private object whose ref points at a private task, memory or note shows the real title. Fix: `ObjectPrivacy.label(of: target, ...) ?? target.title` (also for the hint). Not a spec row today (PM28 covers workout-note words, which the row doesn't carry), so not blocking.

## Lows
- A plain note whose body alone holds a walled word is "Private note" on the object page while the Notes list may show it in the clear. Check the lists use the same predicate.
- The label check runs regexes per row; fine at this size.
- "Note kept private" uses inkSecondary; the spec says muted. Design's call.

Verdict: PASS on e54cbdd, F2 and lows carried.
