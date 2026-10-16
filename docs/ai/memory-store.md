# `TessMemory` store and "remember that..." (ship list AI-7, AI-8, with AI-9's hooks)

One page for Core. It follows `architecture.md` sections 4 and 7, the AI-0 decision in `memory-experiment.md`
and the code on this tree (`TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift`, `TessMemory+Turnover.swift`).
"New" marks anything that doesn't exist yet. Where the docs and the code differ, the list at the end says so.

## 1. The record

One `Memory` object per line (`SystemCatalog` `.tessMemory`, under `/system/tess`), read as `TessMemory`:

| Field | Today | Note |
|---|---|---|
| `kind` | `told`, `noticed`, `recent`, `forgotten` | `forgotten` is a quiet hash object: never shown, never packed |
| `area` | `training`, `kitchen`, `people`, `about`, `days` | The page's group; `days` holds recent lines only |
| `title` (the text) | 80 characters, second person | "You train after work on weekdays." One text, no conversion |
| `evidence` | links to the objects behind it | Feeds the source line ("from 14 workouts") |
| `createdAt` | the object's own | A told line's "you said so on Oct 9"; the forget log compares against it |
| `lastUsedAt`, `pinned`, `isPrivate`, `day`, `rule` | yes | `rule` is the stable id of a noticed or recent line |
| source | computed by `sourceLine(now:)` | Not stored: "you said so today, used today, stays on this phone" |
| `derivedFrom`, `valueRanges` | **new** | Design 49 needs both (redaction of derived lines, bold value words) |

## 2. Who writes

Only the phone. Claude writes no memory (AI-0: 31 of 72 self-written notes failed the checks).

- **Told: his words.** "remember that ..." in his capture runs `RememberFact` as a pending ghost with the 2 s dry
  and UNDO. The receipt is "Kept. You train after work." or, for a private line, "Kept, on this phone only."
  **New (AI-8):** the grammar phrase. Today only the secret-word branch of `TessGrammar` reads "remember".
- **Told: Claude's `remember` on a miss (new, AI-8).** A tool in `TessTools` that proposes a ghost row with
  KEEP / NOT NOW. It never keeps on its own; only KEEP runs `RememberFact`. There is no forget tool, ever
  (decisions.md, 2:52 AM PT Oct 16).
- **Noticed: counted on the phone.** `recomputeNoticed` at the Sunday 04:00 turnover (and the first time ever),
  one rule id per pattern, updated in place, suppressed rules skipped. Lines carry no clock digits (AI-0):
  "You usually train after work.", not an hour span.
- **Recent: one line a day** from `DayStory` at the 04:00 turnover, counts and titles only, 14 days, no week lines.
- **Siri and Shortcuts never write memory** (new): they answer "Say that in Tessera and I'll keep it."

## 3. The walls on write

Every write goes through `TessMemoryScreen.refusal` first. In order:

1. **The Claude key.** `looksLikeClaudeKey` (any case) refuses, nothing written, no line echoed.
2. **SecretWords.** A "remember ..." with a secret word never becomes memory. The router turns it into a private
   note on the phone and Tess says **"Private note, kept. It stays out of my memory."** (Research 134 R7, SW3).
   The note rides in his own backup (Q1) but never enters memory, recent lines, packs or the miss log; the
   turnover skips private notes and any note holding a secret word (SW2).
3. **Money.** Amounts, currency signs and money words are refused: "I don't keep sums of money." Money never
   goes to Claude (MU2), so it has no business in a block that can.
4. **Places and shops.** Refused: "I don't keep places."
5. **Body and health.** A measured value (a unit, a weigh word, a health word within three words of a number)
   is refused whatever he says. A body word alone ("my left knee clicks on squats") or a health feeling keeps the
   line, marked `isPrivate`, and it never goes in any pack (F3, F5).
6. **Numbers.** A noticed or recent line may hold only digits its evidence licenses.
7. **The cap.** At 40 told lines nothing is written: "I keep 40 things. Forget one and say it again."

Saying a forgotten line again is consent: its `forgotten` hash object goes, and the new line is kept.

## 4. The profile block for a pack

Shape A (AI-0): one block, the same bytes for every job that reads memory, so it caches.

- Order: told lines, then up to 10 noticed lines, then the last 7 recent lines. Second person, introduced as
  "lines addressed to him". Private lines never.
- Cap: about 1,200 tokens (`packBudget`, characters over 4). Today's block is about 120 tokens.
- Each job names the kinds it reads (`Reads`). Home lines (AI-10) read every group but About you.
- **New:** a builder that returns the block as text plus its ids for `TessPack.touched` (`claude-client.md`
  section 5), and calls `markUsed` for the ids it packed. Today `pack(_:)` returns `[TessMemory]` and nothing
  marks lines used.
- The pack still passes `ClaudeClient`'s money and SecretWords walls; memory makes neither redundant.

## 5. Seeing and forgetting (AI-9 hooks)

- `grouped()` gives Design 49's groups; `countLine()` / `countWord()` give "12 things. 4 you told me, 8 I
  noticed." and Settings' "12 things". "Nothing kept yet." with only day lines.
- **FORGET** is his gesture only: `ForgetMemory` (10 s UNDO), then `sweepForgotten` / `redact` scrub the words
  from every op and receipt that carried them and write the hash to the forget log. A forgotten noticed line's
  rule stays suppressed. **Forget everything** is `ForgetAllMemory` behind a hold, one op, one UNDO.
- **New:** redact lines whose `derivedFrom` names the forgotten line, the capture op that carried his words, and
  the ghost-row op (F2); drop cached Claude lines of every item that read it (H-M4, H-M5).

## 6. Backups and restore

Memory lives in `tessera.sqlite`, so it rides in every `.tessera` backup. The forget log lives outside it, at
`Application Support/Tessera/tess-forgotten.json` (hashes and dates, no words, complete file protection), and is
never in a backup. `AppModel` calls `reapplyForgetsIfRestored(now:)` before `turnover(now:)`: on the first launch
after a restore (the `restored-at` marker beside the store) it redacts every line created before its words were
forgotten, once. A line he said again after the forget is newer, so it stays (F6). "Erase everything" must delete
the log too. The key and the miss log are never backed up.

## 7. Tests Core should write

1. "remember that I train after work" lands as a told line, "Kept. You train after work.", UNDO removes it.
2. "remember the wifi password is tacocat": a private note, the line "Private note, kept. It stays out of my
   memory.", no `Memory` object, no miss-log row, no op summary holding "tacocat".
3. Money ("remember rent is 2100 dollars"), a place, and a measured value ("resting heart rate is 52") are
   refused with their lines and write nothing. "my left knee clicks on squats" is kept private.
4. A key-shaped string in upper case is refused (today's screen checks one case only).
5. The profile block snapshot: told, noticed, recent in order, no private line, no secret word, no money word,
   under the budget; identical bytes for two jobs with the same reads.
6. Noticed templates: no line from `recomputeNoticed` contains a digit next to "am" or "pm".
7. Forget, then restore a backup from before the forget: the first launch redacts it, the second does nothing,
   and a line said again after the forget survives.
8. Forget a noticed line whose wording changes at the next recompute (3 days becomes 4), restore an old backup:
   the rule stays suppressed.
9. Claude's `remember` tool: NOT NOW writes nothing; only KEEP writes; Siri's "remember" writes nothing.
10. 41st told line: refused with the cap line, store unchanged.

## Where code and docs differ

- **The private-note line.** Code says "Private note, kept. I don't keep passwords." (`TessCaptureEngine.swift`
  line 300, `TessGrammar.swift` comment line 20). Research R7 and SW3 fixed it to "Private note, kept. It stays
  out of my memory." `Refusal.secret.line` also still says "I don't keep passwords.", and
  `RememberFact.refusalLine` returns nil for a secret refusal.
- **Clock digits.** `noticeTraining` writes "You usually train 6 pm to 8 pm." and `TessMemoryTests` line 172
  expects it. AI-0 decided no clock digits; the template and the test both change.
- **No "remember that ..." grammar.** `RememberFact` exists and is registered, but no plain phrase reaches it.
  `TessTools` has no `remember` tool; no Siri refusal line exists.
- **Key screen case.** `TessMemoryScreen.refusal` matches the key prefix in one case only; `looksLikeClaudeKey`
  is any case. Use the shared helper.
- **Missing fields.** `derivedFrom`, `valueRanges` and a stored `source` are in architecture section 4; the
  catalog has none of them. Docs say `group`; code says `area` with a fifth case `days`.
- **The forget log.** Architecture says it holds object ids and rule ids. Code stores SHA-256 hashes of the
  words; rule suppression lives only in deleted objects inside the store, so a restored backup plus a reworded
  noticed line can bring a pattern back (test 8). An unsalted hash of a short line is also guessable.
- **The pack.** Told lines are not filtered to "lines that match the job"; recent lines ignore `Reads.area`;
  there is no text block, no `touched`, and no `markUsed` caller. A comment on `Kind.recent` still mentions week
  lines kept 8 weeks; `foldRecent` (correctly) keeps none.
- **The page.** No What Tess knows screen exists in `Features/` yet (AI-9, Builder B).
