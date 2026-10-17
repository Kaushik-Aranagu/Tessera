# What Tess knows: the data contract (ship list AI-9)

For: Builder B (the page), Core (the lens and the forget helpers). Owner: AI architecture. Date: Oct 16, 2026 (Pacific).
Base: `memory-store.md` (record, walls, forget, restore), `architecture.md` sections 4 and 7, Research's
`tess-knows-trace.md` (rows M1 to M12) and `copy-one-voice.md` section 49. Design 49 (`docs/design/tess-knows.md`,
512ec3e, d73cba4) is not on this tree; the words below follow Research's trace of it. "New" marks what isn't built.

## 1. What the screen reads

One read-only lens, **`TessKnows`** (new, Core, in `TesseraCore/Tess/`), built from `TessMemoryStore` over
`ObjectStore`. The page never reads `Memory` objects, `valuesData` or the op log itself. Builder B wraps it in an
`@Observable` view model that rebuilds on the store's revision and on the day turning (for "today", "yesterday").

`TessKnows(now:)` gives `countLine` ("12 things. 4 you told me, 8 I noticed." or "Nothing kept yet."; day lines never count), `countWord`
(Settings' "12 things" or "Nothing yet"), `groups: [Group(area, word, rows)]` and `atCap` (40 told lines, so the
page says the cap line once). The `source` string folds in `createdAt`, a day line's `day` and `lastUsedAt`.

Each `Row`:

| Field | From | Shown as |
|---|---|---|
| `id` | the object | not shown; the FORGET target |
| `text` | `title`, stored in the second person, 80 characters | the line: "You train after work on weekdays." |
| `kind` | `told`, `noticed`, `recent` | not shown as a word; drives the source line |
| `area` | `training`, `kitchen`, `people`, `about`, `days` | the group it sits in |
| `source` | `sourceLine(now:)`, computed, never stored | "you said so on Oct 9, used today", "from 14 workouts", "from the day log" |
| `pinned` | `pinned` | not drawn this slice (section 3) |
| `isPrivate` | `isPrivate` | words only: the source line ends ", stays on this phone". No lock, no dot, no colour |
| `valueRanges` | **new**, Core | his own words, bold, on told lines only, once the field exists |

## 2. Grouping and order

Groups in this order, each only when it has a line: Training, Kitchen, People, About you, The last 14 days. Told
and noticed lines share their area's group, newest first (`grouped()`); day lines sit only in The last 14 days,
newest day first, 14 at most. Kinds are never mixed into separate headings. Forgotten hash objects and redacted
lines never reach the lens.

## 3. What each action writes

All writes are his, through `ActionEngine.perform(_, by: .user)`. Nothing on this page sends anything anywhere.

| Gesture | Action | Writes | Receipt (thing first) | UNDO |
|---|---|---|---|---|
| Swipe left, FORGET | `ForgetMemory(memory:)` | soft delete, one op | "Left shoulder, forgotten." (the value words; a noticed line uses its first words) | 10 s |
| Hold, FORGET EVERYTHING | `ForgetAllMemory()` | every line deleted, one op | "12 things, forgotten." | 10 s, one UNDO brings all back in order |
| After the window | `sweepForgotten(now:)` then `redact` | words scrubbed from ops and receipts, hash to the forget log, rule ids stay suppressed | none | none |
| Pin | none this slice | nothing | none | none |
| Edit a told line | none this slice | nothing | none | none |

- **Redaction is Core's, not the page's.** The page calls `sweepForgotten` when it leaves and when the window ends;
  the 04:00 turnover runs it too, so a quit inside the window still ends in redaction. **New (Core):** redact the
  capture op and the ghost-row op that carried his words, lines whose `derivedFrom` names it, and drop cached Claude
  lines of every item that read it (H-M4, H-M5).
- **A day line** forgotten leaves the day log untouched.
- **Pin.** Nothing sets the field and no PIN word is drawn, so AI-9 has none. If Design adds one: a new
  `PinMemory`, 10 s UNDO, "Rest on Sundays, pinned.", and the 40-line rule never drops a pinned line.
- **Edit.** Design 49 makes his bold value words editable, but there is no `valueRanges` field and no edit action.
  Default: AI-9 ships without edit; he forgets the line and says it again. When Core adds `EditMemory`, the edit
  runs the same `RememberFact` screen: a health word keeps it private ("Kept, on this phone only."), money or a
  place springs the old words back with no UNDO and her refusal line (S6). Noticed and day lines are never editable.

New lines come from capture: "Rest on Sundays, kept." with a 4 s UNDO, "Kept, on this phone only." if private.
The cap line ("I keep 40 things. Forget one to make room.") shows once, as her line, with no UNDO.

## 4. Empty and switch-off states

- **Nothing at all:** Settings "Nothing yet."; the page "Nothing kept yet." and 'Say "remember that" and I'll
  keep it here.' Asked "what do you know": 'Nothing yet. Say "remember that" and I'll keep it.'
- **Only day lines (week one, S2):** "Nothing kept yet." then The last 14 days with its lines.
- **After forget everything:** the empty page, with noticed rules still suppressed. **New:** a way to let her notice
  again from the empty page (architecture 4); no action exists for it yet.
- **"Tess asks Claude: no":** the page is the same. Memory is counted and kept on the phone; only packs stop.
  "used today" can still change, since on-phone rules read lines too (S10).
- **Settings door, third person**, in ink: "Tess remembers 12 things." Her receipts keep her voice.

## 5. What never shows, and what Claude never sees from here

- **Never on the page:** secret-word notes or their values (they are private notes, never memory, SW2); forgotten
  hash objects; "[forgotten]" placeholders; evidence titles (the source line is a count); the Claude key or any
  part of it (a key-shaped line is refused before it is written); money, places, measured health values (refused).
- **Claude never sees:** this page, its gestures, its receipts, private lines, forgotten words or their hashes, the
  count line. Claude has **no forget tool** (decisions, 2:52 AM PT Oct 16): `forgetMemory` and `forgetAllMemory`
  must never be listed in `TessTools`, and Claude's `remember` only proposes a ghost row (AI-8).

## 6. Who builds what

- **Core:** the `TessKnows` lens; thing-first receipts; the new redaction reach; later `valueRanges`, `EditMemory`
  and unsuppress; the guard that `TessTools` holds no forget.
- **Builder B:** the page on Design 49, the two doors (‹ SETTINGS, ‹ TODAY), swipe and hold, the UNDO band,
  `sweepForgotten` on leave, VoiceOver ("You said so on October 9, used today. Actions: Forget."; the hold has a
  plain action too), Reduce Motion, one haptic at the swipe threshold. No business rules in the view.

## 7. Tests

Core (Swift Testing, a new `TessKnowsTests`):
1. Group order and in-group order on a fixture with all five areas; empty groups absent.
2. A private line's `source` ends ", stays on this phone"; a forgotten hash object and a redacted line never appear.
3. Only day lines: `countLine` is "Nothing kept yet." and The last 14 days has them (M9).
4. FORGET, 10 s, sweep: line gone, its words in no op summary, its rule suppressed at the next Sunday recompute (M2, M3).
5. FORGET EVERYTHING then UNDO inside 10 s: every line back, same order (M7); after 10 s, all redacted.
6. Receipts: "Left shoulder, forgotten.", "12 things, forgotten.", "Rest on Sundays, kept."
7. `TessTools` lists no forget action; an action call from Claude naming `forgetMemory` is refused.
8. A secret-word "remember" leaves the lens unchanged (no row, no count).

Builder B: a snapshot per state (full, day lines only, empty, at cap); a 60 fps recording of swipe, UNDO and hold.

## Where code and docs differ

- **Receipts.** Code says "Kept. You rest on Sundays.", "Everything forgotten, 12 things." and "...Forget one and
  say it again."; the rules want "Rest on Sundays, kept.", "12 things, forgotten." and "Forget one to make room."
- **No lens.** The page would have to call `grouped()`, `countLine()` and `sourceLine` itself; `TessKnows` is new.
- **Pin and edit.** `pinned` is a stored field with no action and no meaning; `valueRanges` and an edit don't exist.
- **Forget-everything count** comes from `recentlyDeleted(within: 5)` on the wall clock, not the op's own count.
- **No unsuppress.** Architecture says the empty page lets her notice again; nothing can clear suppressed rules.
- **No page yet.** Only `AppModel`'s restore check uses `TessMemoryStore`; nothing in `Features/` does.
