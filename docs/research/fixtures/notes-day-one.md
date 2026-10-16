# Notes, day one (Product item AH)

For: Builder B (Notes UI) and Core (grammar, router, privacy walls, backups). Owner: Research lab.
Date: Fri Oct 16, 2026 (Pacific). Read by hand on `origin/master` at `4545922`, after #471 (B1 plus the privacy
follow-ups, `68c9a19`) and #451 (PrivateFacts, `bf2a4bb`). Nothing was built or run. Every value is a placeholder.

**Setup.** Fri Oct 16, 6:10 pm. He has never opened Notes. "Tess asks Claude" is on and his key is stored. VoiceOver
is off unless a step says so. Notes opens from Home's foot line (`HomeSpatialView.swift:350`). Paths are under
`Features/Notes/` or `TesseraCore/Sources/`. KEY stands for any text holding the Claude key prefix.

**Rule sources.** The brief named `docs/ops/decisions.md`; that file doesn't exist. The log is
`docs/product/decisions.md` (cited as `decisions.md`). Design's notes beat is `docs/design/next-build-walk.md:23`, and
the title cut is `docs/design/audit-ui-bar.md` E2.

**Linked, not repeated.** This walk reuses these files instead of copying them:
- [secret-words.md](secret-words.md), [secret-words-check.md](../secret-words-check.md) and
  [secret-words-paste.md](secret-words-paste.md) cover the secret-word rule row by row.
- [money-body-wall.md](money-body-wall.md) covers the money and body walls.
- [siri-privacy-parity.md](siri-privacy-parity.md) covers Siri. [spotlight-widgets-privacy.md](spotlight-widgets-privacy.md) covers out-of-app surfaces.
- [note-task-list-edges.md](note-task-list-edges.md) covers where a typed line lands.
- [undo-windows-audit.md](../undo-windows-audit.md) covers undo windows (rows X11, X13).
- [receipts-thing-first.md](../receipts-thing-first.md) covers receipts (RC17, RC18).
- [accessibility.md](../accessibility.md) covers VoiceOver, Dynamic Type and Reduce Motion (Notes C16, C17, B14).
- [backup-cases.md](backup-cases.md) covers backups.

## Counts

| Status | Steps | Ids |
|---|---|---|
| pass | 21 | N1, N2, N4, N8, N9, N11, N12, N14, N16, N17, N19, N20, N23, N25, N26, N27, N30, N33, N38, N39, N40 |
| wrong (built, not as ruled) | 14 | N5, N6, N7, N10, N13, N18, N21, N22, N24, N28, N29, N34, N36, N42 |
| miss (ruled, nothing does it) | 4 | N3, N15, N35, N43 |
| not built | 4 | N31, N32, N37, N41 |
| **Total** | **43** | |

## Gaps by owner

**Builder B (Notes UI)**
- N13: a private note's row shows its second line on the Notes list, and VoiceOver reads it too (`NotesView.swift:186`, `:196`, `:216`).
- N35: deleting a note gives no line and no 10 s UNDO (`NoteEditor.swift:170-175`). This is board item 0i.
- N7, N3: writing on the Notes page gets no receipt. A secret line gets no "Private note, kept." line, unlike Design walk row 7 (`NotesView.swift:118-127`).
- N6: the capture UNDO under the Ask bar isn't timed from its line, doesn't stretch to 10 s under VoiceOver, and says nothing when used (`BottomChrome.swift:736-744`).
- N21, N22: KEY on the writing line clears the whole draft. In the editor, the key line never clears (`NotesView.swift:82-83`, `NoteEditor.swift:132-137`). These are board items 0k and 0j R3.
- N36: Notes time words say "1 hours ago", cut hours down instead of rounding, and take weekdays from the wall clock (`NotesView.swift:267`, `:273`). This is board item 0g.
- N34 (editor half): the title is cut at 59 characters plus "…" (`NoteEditor.swift:200`).
- N42: the new-row push skips Reduce Motion, and AX5 cuts the rows (C16, C17).

**Core (grammar, router, privacy walls, backups)**
- N18: a past-tense body fact with a day becomes a plain dated note, not a private one (`TessGrammar.swift:127` runs before `:141` and `:153`).
- N28, N29: "bought 2 lemons sat" and "paid rent 2100 fri" fall to the model or the miss line, not a dated note (N29 should be a private dated note, Product 1:15 pm). The second also lands in the miss log (`TessGrammar.swift:116-120`, `TessCaptureEngine.swift:58`). These are board item 0j R2 and the 12:11 pm ruling.
- N15: notes written before #422 keep their words. There is no mark-private pass at launch, so `DayStory.swift:347` prints them.
- N43: Siri's Add a Task never checks PrivateFacts (`Intents.swift:136-145`). This is the P14 rider.
- N5, N10: Tess's note receipts are verb-first, and the "remember" secret line has the old wording (`TessCaptureEngine.swift:300`, `:304`, `:313`).
- N24: RenameObject has no key guard (`Actions/TrainingActions.swift:501-503`). This is board item 0k.
- N34 (engine half): `Notes.swift:128`.
- N6 (engine half): there is no shared `UndoWindow`. The 4 s is hard-coded at `App/AppModel.swift:276`.

## The walk

### Capture by typing (Notes page)

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N1 | Opens Notes for the first time | Empty page with a voice line, no cards | Context line "A place for loose thoughts", hero "Notes", the writing line, then "Nothing written yet." with the Tess hint (`NotesView.swift:239`) | pass |
| N2 | Types "bar felt heavy on the third set", Return | Return saves (Kaushik, 12:01 am Oct 16, board B 00) | A typed newline submits (`NotesView.swift:152-156`). `CreateNote` writes it (`:118-127`). The row arrives with "now" in cobalt and dries (`:207`) | pass |
| N3 | Looks for a receipt or an UNDO after N2 | AQ15: a new capture gets a 4 s UNDO. Every receipt names the thing (`decisions.md:255`, `:277`) | Nothing is said and there is no UNDO. The only sign is the cobalt time. See Q1 on whether AQ15 covers this page | miss |
| N4 | Types "@Bench Press felt heavy" | @ links to the thing. Backlinks appear on its page | Links set (`Notes.swift:118`, `:192-207`). Mention in cobalt (`NotesView.swift:279`). The editor's Links section (`NoteEditor.swift:73-91`) and Bench Press's backlinks (`Objects/ObjectPage.swift:222`) | pass |

### Capture by Tess (Ask bar)

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N5 | "note: bar felt heavy", then "note: @Bench Press felt heavy" | Thing first: "Note, kept." and "Note, linked." (RC18). A dated note reads "Note, for Friday." (RC17) | "Noted." / "Noted, linked." (`TesseraTess/TessCaptureEngine.swift:313`). "Noted for Saturday." (`:304`). The routes are right (`TessGrammar.swift:333-339`) | wrong |
| N6 | Taps UNDO under "Noted." | 4 s, counted from when the line shows. 10 s with VoiceOver on. Pauses in background. Says "Note, taken back." (`decisions.md:58-71`, `:86`) | 2 s ghost, then a fixed 4 s sleep after commit (`App/AppModel.swift:276`), about 6 s from the line. No VoiceOver stretch and no pause. Undo is silent (`BottomChrome.swift:736-744`). Audit X13 | wrong |

### Note privacy: secret words and isPrivate

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N7 | On the Notes page types "wifi password is tacocat4417" | Private note. The row reads "Private note" and Tess says "Private note, kept." (Design walk row 7, `next-build-walk.md:23`) | `CreateNote` forces private and sets no links (`Notes.swift:111-119`), so the row reads "Private note". The page has no line for it: the context line only ever shows the key line or the count (`NotesView.swift:65`) | wrong |
| N8 | Ask bar: "door code 4417" | Private note. Never the model, Claude or the miss log (NE1/NE2) | Grammar first (`TessGrammar.swift:488-510`). The router keeps it on the grammar (`TessModel.swift:74-79`). The miss log skips it (`TessCaptureEngine.swift:58`). "Private note, kept." (`:300`) | pass |
| N9 | "pw for gym locker 4417" | Private too (#454, `decisions.md:189`) | "pw" and "pwd" are in the word list, and tokens split on newlines (`Notes/SecretWords.swift:11-12`, `:17`) | pass |
| N10 | "remember the wifi password is hunter2" | SW3: "Private note, kept. It stays out of my memory." (`secret-words-check.md` rulings) | "Private note, kept. I don't keep passwords." (`TessCaptureEngine.swift:300`) | wrong |
| N11 | "what's the wifi password?" | Answered on the phone, never sent | "It's in your private notes." (`TessGrammar.swift:497-498`) | pass |
| N12 | Opens N2's note and adds a second line, "gate code 4417" | A code added to a plain note makes it private (QA F1 on #422). Its links are cleared | `EditNote` sets `isPrivate`, clears `about` and sets the title to "Private note" (`Notes.swift:159-175`) | pass |
| N13 | Back on the list, looks at that row (and hears it with VoiceOver) | Outside its own page, a private note reads "Private note" and nothing more (NE1, `SecretWords.swift:3-5`; DayStory SW2) | The title reads "Private note", but `NoteRow` prints the body's second line under it: "gate code 4417" (`NotesView.swift:186`, `:196`). `.combine` reads it aloud (`:216`) | wrong |
| N14 | Deletes the code line again | A private note stays private (F1) | `wasPrivate` keeps it private (`Notes.swift:161-162`). Q4 asks whether he can ever undo it | pass |
| N15 | His phone has a note from before #422: "wifi password is hunter2" | Launch pass sets `isPrivate` on old notes with a secret and a value (board Core, pin rider) | Not merged (`oct-22-list.md:15`). The Day log prints "Note: Wifi password is hunter2" (`DayLog/DayStory.swift:347`). Memory is guarded (`TessMemory+Turnover.swift:67`) | miss |
| N16 | (store) | Note gets an additive `isPrivate` (SW4, #422) | Field on Note (`Catalog/SystemCatalog.swift:220`). Catalog v9 (`:350`) | pass |

### Note privacy: money and body facts never reach Claude

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N17 | Ask bar: "knee hurts" | A body fact with no number stays on the phone as a private note (L1, `decisions.md:179`) | `parseBodyFact` (`TessGrammar.swift:153-157`). The router skips Claude for a walled phrase (`TessModel.swift:77-79`), and Claude refuses it again (`ClaudeTessModel.swift:54`). Tested at `PrivacyFollowupTests.swift:37-43` | pass |
| N18 | Ask bar: "slept 6 hours last night" | Same as N17: private note, "Private note, kept." (P15a, ruled 12:30 pm) | `parsePastLog` runs first (`TessGrammar.swift:127`), so this becomes a plain note dated Thursday with "Noted for Thursday.". I read the title as "Slept 6 hours"; siri-privacy-parity S10 reads it as "6 hours". It isn't private, so the title shows in the Day log | wrong |
| N19 | On the Notes page types "took 2 advil" | Body facts never go to Claude | A plain note: `CreateNote` has no PrivateFacts check. No Claude caller reads notes today: Plan my day never sends notes (`decisions.md:307`), and the memory screen refuses health words (`Tess/TessMemory.swift:144`). See Q2 | pass |
| N20 | Ask bar: "note: took 2 advil" | Never to Claude | `parseNote` takes it as a plain note (`TessGrammar.swift:333-339`). Walled, so Claude is skipped anyway (`TessModel.swift:77`). Q2 applies | pass |

### Notes refuse a Claude key

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N21 | Pastes KEY on the writing line | B1-11: Notes refuse any text with the Claude key prefix, using the shared guard (`decisions.md:159`). Board 0k: strip only the key and keep the rest of the draft | Refused with the shared guard. The context line turns to the key line in cobalt. But the whole draft is cleared (`NotesView.swift:82-83`) | wrong |
| N22 | In the editor types "router in the hall KEY" | Same. 0j R3: the key line clears on the next edit | Key stripped, rest kept, key line shown (`NoteEditor.swift:132-137`). `refusedKey` is never set back, so the key line stays until he leaves (`:26`, `:35`) | wrong |
| N23 | Engine path: a note or edit holding KEY, including "wifi password is tacocat KEY" | Never stored, so it never rides in a backup (QA B1) | `CreateNote` refuses before the private branch (`Notes.swift:107`, before `:111`). `EditNote` refuses too (`:156`). Tested at `PrivacyFollowupTests.swift:83-100` | pass |
| N24 | (any route that renames a note) | Same guard on RenameObject (board 0k) | `RenameObject.apply` sets any title, with no key check and no private check (`Actions/TrainingActions.swift:501-503`). It is registered in `ActionRegistry.swift:9`. No screen calls it today | wrong |
| N25 | Ask bar: "note: KEY" | Refused, nothing written, nothing logged | The router returns the key line before any route (`TessModel.swift:69-71`). The miss log skips it (`TessCaptureEngine.swift:58`) | pass |

### Past-tense notes and the money rule

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N26 | Ask bar: "paid rent fri" | An ordinary dated note for Friday. Not private, so it can show in Spotlight and reach Claude (`decisions.md:164`) | `isMoney` needs an amount or a currency sign (`TesseraTess/TessGrammar+Kitchen.swift:81-87`), so `parsePastLog` makes a dated note. Tested at `PrivacyFollowupTests.swift:70`. The receipt is N5's | pass |
| N27 | "bought milk sat" | Same | Same path. Tested at `PrivacyFollowupTests.swift:71` | pass |
| N28 | "bought 2 lemons sat" | Same: a count is not an amount (`decisions.md:164`, board 0j R2) | "bought" plus "2" counts as money (`TessGrammar+Kitchen.swift:85-86`), so `parse` returns nil at `TessGrammar.swift:116-120`. Then the on-device model or "Didn't catch that.". `isMoneyShaped` also walls it from Claude (`Tess/PrivateFacts.swift:30`), which the rule says it shouldn't | wrong |
| N29 | "paid rent 2100 fri" | The day wins: a **private** dated note for a past tense, on the phone, and the amount never goes to Claude (12:11 pm; private per Product 1:15 pm, the same routing as Siri). Money never goes in the miss log (12:30 pm) | Nil at `TessGrammar.swift:116-120`, so no dated note. Claude is walled (pass), but when nothing reads it, `TessCaptureEngine.swift:58` logs it to the miss log (no PrivateFacts check there) | wrong |
| N30 | "pay rent fri" | A task, not a note (12:04 pm) | A task. Tested at `PrivacyFollowupTests.swift:69` | pass |

### Search and Spotlight

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N31 | Looks for an older note inside Notes | No ruling on in-app search | No search field. The list stops at the 200 newest (`NotesView.swift:62`), so note 201 can't be reached from Notes. Q8 | not built |
| N32 | Searches iPhone Spotlight for a note's words | Walled titles are hidden from Spotlight (12:26 pm). Private notes are never in Spotlight. Ordinary notes may show (12:21 pm) | Nothing is indexed: no CoreSpotlight and no IndexedEntity. `TesseraIntents/Entities.swift` has only exercises and routines. "Private notes never in Spotlight" holds only because there is no index. Guard rows are in spotlight-widgets-privacy.md | not built |

### Editing, deleting and UNDO

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N33 | Opens a note and edits it | Autosave is a silent write (`decisions.md:410`). Return in the first line moves to the rest | The first line is its own field, and Return moves focus (`NoteEditor.swift:51-56`). Saves 800 ms after typing stops and on leave (`:144-168`). Nothing written if untouched (`:160`) | pass |
| N34 | Writes a first line longer than 60 characters | Cut at the last whole word at or before 60, with no glyph (Design E2) | `prefix(59) + "…"` (`Notes.swift:128`, `NoteEditor.swift:200`) | wrong |
| N35 | Taps "Delete note" | 10 s UNDO. The line names the thing and the undo answers "X, taken back." (`decisions.md:69`, `:414-415`) | `DeleteObject`, then dismiss. No line, no UNDO (`NoteEditor.swift:170-175`). Audit X11, board B 0i | miss |
| N36 | Reads the times on rows and in the editor | "ago" rounds to the nearest hour, with "1 hour" singular. Weekdays from the 4 am day (12:35 pm) | `Int(seconds / 3600)` truncates and prints "1 hours ago" (`NotesView.swift:267`). The weekday comes from the wall clock (`:273`) | wrong |

### Links and paste

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N37 | Pastes three lines (a packing list) on the writing line | No ruling for Notes (Lists has "a preview before saving a paste", `decisions.md:517`) | The newline counts as Return: the lines are joined with spaces and saved at once (`NotesView.swift:152-156`). Q5 | not built |
| N38 | Pastes a URL on the writing line | Nothing fetched, nothing sent (NE12 proposal, note-task-list-edges E26) | Kept as plain text. Not tappable, not fetched. The same URL said to Tess goes to the model, then Claude (E26). Q6 | pass |
| N39 | Pastes a block into the editor with "Costco member # 4417 4417 4417" | No ruling for notes. PL4 cuts account lines only from recipe pastes and fetched pages | `SecretWords.mentions` ignores account words, so it stays a plain note. `cut` runs only on recipes and pages (`SecretWords.swift:73-81`). Q7 | pass |

### VoiceOver basics

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N40 | With VoiceOver, moves through Notes and a note | Labeled fields, a header, rows as one element with a hint | "Notes" is a header (`NotesView.swift:74`). Writing line labeled "New note" (`:158`). Rows combined with "Opens the note" (`:216-217`). Seams hidden (`:229`). Editor fields "First line" and "Note text" (`NoteEditor.swift:58`, `:70`). Delete has a hint (`:101`) | pass |
| N41 | With VoiceOver, pastes KEY or writes a note | Not ruled. accessibility.md B11 proposes announcing Tess lines | Nothing is announced. The key line changes silently (`NotesView.swift:65-69`), and a new row says nothing. Q9 | not built |
| N42 | AX5 text, Reduce Motion, two-finger scrub to close | Reduce Motion goes through MotionPolicy (CLAUDE.md, DESIGN_MOTION) | Open in accessibility.md: C17 (the `.push(from: .top)` insertion at `NotesView.swift:100` has no Reduce Motion swap), C16 (`lineLimit(1)` rows at AX5), B14 (no `.escape` on the cover) | wrong |

### Siri

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| N43 | Siri, Add a Task: "venmo sam 25 for pizza" | P14 rider: Add a Task checks PrivateFacts, saves a walled title as a private note and doesn't read it back (12:26 pm) | Checks only the key and `SecretWords.hasValue` (`TesseraIntents/Intents.swift:136-145`). A walled title becomes a plain task and is spoken back. siri-privacy-parity S2 to S19 | miss |

## Questions for Product

1. **Does writing on the Notes page get a receipt and an UNDO (N3, N7)?** AQ15 says a new capture gets 4 s. The Notes page has no line at all.
   *Pick:* yes. Use the context line slot, as the key line does. "Note, kept." or "Private note, kept.", with a 4 s UNDO ("Note, taken back."). That matches Design walk row 7.
2. **Should a body fact typed on the Notes page, or after "note:", be private like one said to Tess (N19, N20)?**
   *Pick:* yes. Use one rule whoever writes it, like secret words: a body-shaped note gets `isPrivate`. A money-shaped note stays plain, since nothing that reads notes goes to Claude and the 12:26 pm Spotlight rule already hides its title.
3. **Once N29 is fixed, is "paid rent 2100 fri" a private note or a plain dated note?** *Ruled 1:15 pm: a private dated note.*
   *Pick:* a plain dated note, amount kept. The router already walls it from Claude, and the 12:26 pm title check keeps it out of Spotlight.
4. **Can he make a private note ordinary again, or mark a note private by hand (N14)?**
   *Pick:* not for v1. F1 stands, so a private note stays private. A hand gesture waits for Design.
5. **What does a multi-line paste on the writing line do (N37)?**
   *Pick:* keep its lines and open it in the editor as a new note. Don't save on the spot. "Return saves" applies to a typed Return only.
6. **A bare URL said to Tess (NE12, N38): a note, or the model?**
   *Pick:* a note holding the link as pasted. Nothing fetched, nothing sent (NE12 as proposed).
7. **An account-number line in a pasted or typed note (N39)?**
   *Pick:* the whole note becomes private, using PL4's account shape. Never cut, since he wrote it.
8. **In-app note search (N31)?**
   *Pick:* lift the 200-note cap now (one line). Park search until Spotlight lands as an IndexedEntity, with private and walled notes never indexed.
9. **Should Tess's lines in Notes be announced to VoiceOver (N41)?**
   *Pick:* yes. Post an announcement for the key line and for Q1's receipt, as accessibility.md B11 proposes. Use the same 10 s UNDO under VoiceOver.
