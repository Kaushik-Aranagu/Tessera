# Review: #471 core/privacy-followups (B1, L1, L3, W10, bare-verb isMoney, buy pins, pull-ups)

QA, Oct 16 2026, ~12:40 PM PT. Head **6a5db77**, merges cleanly onto master (merge-tree clean). Static review; no Swift toolchain here.

## Verdict: PASS

Every row the coordinator listed is covered in code and in `PrivacyFollowupTests`.

| Ask | Where | Result |
|---|---|---|
| B1: Notes refuses a Claude key in the engine | `Notes.swift` CreateNote + EditNote guard body and title on `looksLikeClaudeKey`, throw `invalidArguments("refused: looksLikeKey")` | ok |
| B1: writing line | `NotesView.swift` onChange clears the draft, sets `refusedKey`, context line shows `claudeKeyLine` in `Theme.Colors.tess` | ok |
| B1: editor | `NoteEditor.swift` strips keys from heading and text via `withoutClaudeKeys`, keeps the rest, shows `claudeKeyLine` | ok |
| L1: health without a number is private | `PrivateFacts` symptoms list widened (hurts/hurt/aches/sore/injured/sprained/slept/cramping...), body fat regex, `parseBodyFact` gives `.privateNote(remembered: false)` | "slept badly", "knee hurts", "headache", "body fat 18%", "resting heart rate 58" all private in tests |
| L3: paid/spent + amount is money | `PrivateFacts` `spent` + `hasAmount`, overrides `isTraining` | ok |
| W10 | `parseRememberedMoney`: "remember my rent is 2100" gives "I don't keep sums of money." | ok |
| Bare verb isMoney | `TessGrammar+Kitchen.swift` ^verb rule now also needs `hasAmount` | "pay rent fri" is a task; "paid rent fri", "bought milk sat" are notes |
| buy pins / combination lock | `parseSecret` returns nil for buy/get/grab/pick up/add shapes with no value | both land on Groceries |
| pull-ups alias | "pull-ups" -> "pull-up" | ok |
| Near misses stay unwalled | tests: "bench 80 x 8", "knee day at the gym", "weigh the flour 500 g", "Costco run saturday", "budget meeting 3pm", "pay rent fri 7:30" | ok |

Plan pack: `PlanPack.isPrivate` already calls `PrivateFacts.isWalled` (PlanWording.swift:37), so the wider body words also keep task titles out of the Sonnet pack.

## Lines he sees that are new or changed (for Design)

1. Notes index writing line and NoteEditor context line: **"That looks like a Claude key. It goes in Review, under Claude."** in Tess colour. In the index the pasted draft is cleared; in the editor only the key is cut, the rest stays.
2. A body or health fact said to Tess: **"Private note, kept."** (new path for no-number facts).
3. "remember ... <money>": **"I don't keep sums of money."**
4. Changed routing he will notice: "paid rent fri" / "bought milk sat" become private notes instead of tasks; "pay rent fri" stays a task; "buy pins" goes to Groceries.

## Lows (no fix needed for the pin)

- **R1** `parseBodyFact` runs only after `parseTask` returns nil (TessGrammar.swift:141), so a dated body fact ("headache since tuesday", "knee hurts tomorrow") becomes a task titled with the body fact. It stays on the phone and the plan pack sends it as "task", but it lands in the task list, not a private note.
- **R2** "bought 2 lemons" is now money-shaped (`spent` + amount) and grammar-isMoney, so it misses instead of reaching Groceries or a note. Product may want the amount rule to need a currency sign or money word when the verb is "bought".
- **R3** NoteEditor `refusedKey` is never reset, so the key line stays after he keeps typing (NotesView resets it; the editor should match).
- **R4** `withoutClaudeKeys` (a case-insensitive match on the Claude key prefix followed by non-space characters) leaves fragments when a pasted key is split by a space or newline. The engine guard still refuses the saved text if the prefix remains, so this is cosmetic.
- **R5** The new `claudeKeyLine`/`withoutClaudeKeys` doc comment sits inside `looksLikeClaudeKey`'s comment block in ClaudeKeyGuard.swift (nit).
- **R6** New symptom words may over-wall: "doesn't hurt to ask", "sore loser", "slept on it". They go private (safe direction), so a miss rather than a leak.
