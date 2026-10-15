# QA: grammar collision rules 1-3, PR #115 (master 34665f0)

*Repo maintainer (QA), 2026-10-15 22:05 UTC. Static read against research/grammar-collisions.md and docs/qa/grammar-trace.md.* **PASS, with G1 and G2 as should-fix hotfixes.**

## Info.plist
`App/Info.plist` now matches the project.yml block from #112: CFBundleDocumentTypes (Owner, com.kaushikaranagu.tessera.backup), LSSupportsOpeningDocumentsInPlace, UIFileSharingEnabled, and UTExportedTypeDeclarations (public.data, extension `tessera`). OK.

## Rules
- The new parse order is: note → pasted recipe → **question guard (nil)** → **process-owned bare input** → relative set → comma sets → lift → kitchen → **reschedule** → task. grammar-trace.md line 5 needs this update (docs PR to follow).
- Rows 16-20 (questions) now decline to the model. Rows 34/35 (`timer 90` / `rest 90` in a workout) no longer become kitchen timers. Row 42 (`parmesan` while shopping) is now groceries. The cook "next"/"done" steps and the reschedule of a single matching open task are OK.
- "thu" on a Thursday now means today at the next whole hour (the Product decision). A passed explicit time still rolls to next week. "today" after 09:00 also moves to the next whole hour.

## Should-fix
- **G1: the question guard is wider than the spec, and it swallows common tasks.**
  - `isQuestion` (TessGrammar.swift) also takes `do`, `does`, `is`, `are`, `which`, `who`, `where` and `why`. Rule 2 lists only what, whats, when, how, did, am i, anything, everything and show.
  - So "do laundry thu", "do taxes sat" and "is renewal due fri"-style tasks now return nil and go to the model. Today that means no grammar task at all, and nothing on a phone without on-device AI or a Claude key.
  - Fix: use the rule-2 list, plus `?` at the end.
- **G2: the workout rest rule matches prefixes, not words.**
  - `text.hasPrefix("timer") || text.hasPrefix("rest")` catches "restock protein thu", "restaurant booking fri" and "timers for oven". While a workout runs, each of these throws "the rest timer lives on the workout screen" instead of becoming a task.
  - Fix: match `^(rest|timer)(\s+timer)?\s+\d` (rows 34/35 are all `rest|timer` + number).

## Low
- G3: the whole-word lift fallback drops words under 3 letters, so "ez curl" no longer resolves unless an exact name or alias hits. The equipment map keeps `ez` as two letters. Add an "ez curl" alias, or exempt the equipment words.
- G4: the shop rule takes any short phrase with no numbers. "call mum thu" or "dentist fri" said while shopping become grocery lines. Skip the rule when `TessDates` finds a date cue.
- G5: the comment on `parseReschedule` says it "never makes a task titled with the verb". When no task matches, `parseTask` still makes "move dentist" due Friday. Fix the comment, or decline to the model.

## Follow-up: #117 (master 3dbac3a), 2026-10-15 22:15 UTC. **G1-G5 closed.**
- **G1:** the lead words are now the spec list only (plus "am i" and a trailing "?"). "do laundry thu" is a task again.
- **G2:** the workout rule is now `^(rest|timer)(\s+timer)?\s+\d`. "restock protein thu" and "restaurant fri" fall through to the task rule.
- **G3:** gym shorthand (db/bb/kb/ez and their expansions) is exempt from the 3-letter floor. Whole-word matching now includes library aliases, so "ez curl" finds the EZ-Bar alias.
- **G4:** the shop rule skips phrases with a date cue. "call mum thu" stays a task.
- **G5:** a `move|push|shift|reschedule|put … to …` shape with no single matching task now declines to the model instead of making a "Move …" task.
- New lows:
  - G6: the shop date check also catches weekday-looking grocery words. "sun dried tomatoes" while shopping reads "sun" as Sunday, so it becomes a task "dried tomatoes" on Sunday. The same thing already happens outside a shop (pre-existing parseTask). A fix is to require the weekday cue at the end of the phrase, or to keep a small food-phrase exception list.
  - G7: the G5 decline also sends real tasks shaped like a reschedule to the model, for example "move money to savings fri". With no model available, nothing is captured. This is acceptable for now; logged.
