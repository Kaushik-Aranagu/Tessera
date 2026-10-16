# QA review: #422 Core secret words (Research 134) and the cap constant

Head `71be2af` on master b489ca5. Trial merge is clean. Twelve files, all in TesseraCore: SecretWords.swift (new), Notes, TessGrammar, TessCaptureEngine, TessModel (router), TessMemory and Turnover, DayStory, SystemCatalog (v9), ClaudeKey (cap), and tests. This is a static review; there is no Swift toolchain here.

## Verdict: FIX FIRST (two must-fixes: an edit turns a private note public, and the cap has no matching copy)

### F1. Editing a private note puts its words in the title, and editing a plain note never makes it private
`EditNote.apply` (Notes.swift:150-158) sets the body, runs `linkMentions`, and sets whatever title it's given. It never looks at `isPrivate` or `SecretWords`. The note editor always passes a title made from the body's first line: `EditNote(note:body:title: NotesEditorCopy.heading(from: trimmed, …))` (NoteEditor.swift:150-151).

Two paths follow:
- He opens "Private note" and fixes a typo. The title becomes "Wifi password is tiger42". From then on that title is shown in the Day log ("Note: …", DayStory.swift:345-347), the Notes list, receipts and search. The turnover's second guard still drops it from memory, because the line mentions a secret word, but SW2's "reads Private note everywhere outside its page" no longer holds. The body's @mentions are now linked, too.
- He adds "door code 4417" to an existing plain note. It stays public, with its title, its links and its Day log line.

Fix, in `EditNote.apply`: `let isPrivate = store.value("isPrivate", of: note) == .bool(true) || body.map(SecretWords.mentions) == true`. When it's private, keep the title `SecretWords.title`, set `isPrivate`, and skip `linkMentions`. Give `summary` the same rule. Add a test for each path: edit a private note, and add a code to a plain note.

### F2. The cap is $50 in code, but the Settings copy still says $10, and master still reads "proposed"
`TessUsageLedger.capNano` is now 50_000_000_000 (ClaudeKey.swift:88). Settings still hard-codes the old number in three places: " of $10." (ClaudeSection.swift:191, :459), "PAUSES AT $10" (:202), and the spoken "of 10 dollars this month" (:196). So on the phone the meter fills against $50 while the words say it pauses at $10. Meanwhile docs/product/decisions.md:79 on master (b489ca5) still says the $50 cap is "Proposed, waiting on his yes … until he answers, the cap stays $10". The comment's "decisions.md Oct 16" isn't on master yet.

- If he said yes: the three strings read `TessUsageLedger.capDollars`, and the decision line lands with this PR or before it. ClaudeSection is Builder B's file, so either Core makes the string change here or Builder B rides it in this pin.
- If he didn't: `capNano` goes back to 10_000_000_000, and the constant waits for his word.
- Either way the comments at ClaudeKey.swift:7 and :83 still say "$10".

## The four checks

1. **Catalog v9 and #407.** Both bump `version: 8 → 9` with different field rows (Note.isPrivate here, Settings.tessEyes there). In either order git merges the identical version line cleanly. The second field is still added on the next launch, because the field loop runs whatever the version (SystemCatalog.swift:388-421). But two different "v9" specs would break the rule "bump version whenever a spec changes", along with the gate's and rollback's naming of stores. Product's 10:18 AM call settles it: #422 takes v9, and #407, which lands second, moves to v10 (Core is renumbering). Rule for any second bump: take the next number, never share one. v9 itself is additive: one `.bool` field on Note, no GRDB schema change. A v8 build on a v9 store doesn't refresh (`packageVersion < version` is false) and leaves the row alone. A v8 build reads a private note as a note titled "Private note" with its body, which stays on the phone.
2. **Paths for secret words to leave the phone.**
   - Router: `SecretWords.mentions(request.text)` keeps every model but the grammar out, whatever the switch (TessModel.swift:73-75). The grammar's `parseSecret` runs first and always returns something (an ask, a task, or a private note), so nothing falls through.
   - CreateNote forces private for any body with a secret word, whoever writes it. That includes the Tess tool `createNote` (TessTools.swift:184).
   - Miss log: guarded in TessCaptureEngine (:58). **But the recipe paste path writes its own miss line**: `CaptureMissLog.beside(model.store)?.record(text, …, source: "paste")` (Features/Recipes/PasteRecipe.swift:204), with no check. A pasted text holding "door code 4417" that doesn't read as a recipe lands in the miss log file. Research 134 says the miss log never holds one. One guard there: `!SecretWords.mentions(text)`. That's F3, small, in Builder B's file.
   - Memory: refused with "I don't keep passwords." (TessMemory.swift:139-141), and the turnover skips private or secret lines (Turnover.swift:65-67).
   - Plan my day sends task titles, never notes (decisions.md:88). A secret line with no value that has a task shape stays a task by design (R-rows: "code review friday 3pm"), so "Code review" can reach Claude as a task title. That matches Research 134 as written.
   - Day log: a single private note reads "Private note"; several read "N notes".
   - Backups carry the body, by design (Q1).
   - Op log: the `set body` op holds the words. It stays in the store and backups, and summaries read "Private note".
   - No Spotlight or App Intents index of notes exists, so none is affected.
   - Not covered by Research 134, flagged for Product: a pasted recipe or a link fetch goes to ClaudeRecipeReader as text without this check. A pasted page that happens to hold a code would go out. That's the paste flow, not his lines.
3. **Day log budget under load average 550.** That's load, not this PR. The PR's only Day log change is one string comparison per notes group (DayStory.swift:345). `mentions()` runs in the turnover, not in the Day log build. 42 ms of a 50 ms budget alone leaves 16% headroom, and a load of about 550 is dozens of runnable threads per core. Worth a note for Core: a budget test that measures one sample at that headroom will keep failing in the full run, so take the median of 5.
4. **Data-safety grep.** There are no launch-flag, ProcessInfo, LaunchFlags or UITest changes. The migration is additive, as above. It's a TesseraCore-only diff: the app and the phone paths are untouched except through the engine.

## Lows
- L1: false positives become private notes without a word of warning. "Buy combination lock" and "pin the photos" have no task shape, so they turn into "Private note, kept." instead of groceries or a task. The receipt tells him, and nothing is lost. "promo code SAVE20" too.
- L2: `tokens` splits only on spaces, so "password:tiger42" works through the ":" rule, but "wifi-password tiger42" doesn't match. Fine for spoken and typed lines.
- L3: the gate rows: M4's rerun now runs at v9 and M5 adds the secret-word rows. Wording is in QA's docs PR (next-build-script.md).

## Addendum: re-check at `88423d3`

Verdict: **PASS**. One commit on top of 71be2af. Trial merge onto master 3fea869 is clean.

- F1 fixed (Notes.swift, `EditNote`). A note that was private, or whose new body or title mentions a secret word, keeps or gets `isPrivate` and the title "Private note". Its `about` links are cleared when it turns private, `linkMentions` never runs on it, and `summary` reads "Private note". Because `summary(in:)` runs after `apply`, a plain note turned private also gets "Private note" as its receipt. The editor's heading suggestion is ignored for private notes. Tests cover the private edit, a code added to a plain note, and a plain edit.
- F2 fixed: all four Settings strings read `TessUsageLedger.capDollars` (ClaudeSection.swift:191, :196-197, :203, :460). The decision is now on master: decisions.md:21, "The in-app Claude cap is $50 a month (9:27 AM PT Oct 16, Kaushik …)". There are no `$10` strings left in App or Features.
- F3 fixed: PasteRecipe skips the miss log when the text mentions a secret word (PasteRecipe.swift:204-207).
- The Day log budget test takes the median of 5 (ScaleTests.swift).
- Low (new): the comments at ClaudeKey.swift:7 and :83 still say "$10". They're comments only.
