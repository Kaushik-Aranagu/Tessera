# Next build after pin a36b161: the v9 riders pin (Product item AT)

For: Product, Core, Builder A, Builder B, QA. Owner: Research lab. Fri Oct 16, 2026 (Pacific).
Read by hand on `origin/master` at `5984f40` (Merge #523). Nothing was built or run. Every value is a placeholder.

**The ruling (Product item AT, 1:43 pm).** The next pin after a36b161 carries the v9 riders only. The Catalog stays
v9. v10 (#407 `tessEyes`, then flag to setting, then the Design 70 LOOK row) ships alone in a later pin, written up
in `next-build-v10.md`. This page is the riders pin: its list, its gate and its rollback.

**The pin today.** a36b161 (#498 M1), Catalog v9, named 1:08 pm. No line on master says it is on his phone yet
(the QA board still calls it the install candidate, `docs/ops/board/qa.md:9`).

**Due date.** Core 0ae (Review's trip bands) is due before the Oct 26 trip. **The riders pin must be on his phone
before Oct 26**, so it is named, gated and installed by Sun Oct 25 at the latest. If 0ae misses that day, Product
decides whether the pin goes without it (the trip week then reads wrong in Review) or waits.

## 0. Rider status (for the Thu Oct 22, 9:30 am branch call)

Refreshed Fri 1:55 pm PT against master ba86ff4 (Merge #524).

**Order (Product, decisions 1:56 pm).** Merged rows first, then the open riders in build order. Core: 0ad, 0ae, 0ag,
HW19 with CR1, N15, P14 with HW13, HW9, 0af (HW11 rides with the 0ac work). Builder B: 0r, then 0t and 0u. Builder A:
0n first. The UNDO slot (F1 to F3) goes in only if it is already done by Oct 22.

**First rider in order with no PR: R8 PN-MENTION (Core 0ad, Builder B 0r).**

**The rule (Product, 1:51 pm).** The riders pin carries whatever has merged and passed QA by the branch call. It does
not wait for any single rider. At the call, the pin SHA is the newest first-parent merge on master at or after the
last row below that reads "merged" with a QA PASS. A rider still open at 9:30 am goes to the next pin.

How this was filled: `git log --first-parent a36b161..origin/master` (28 merges), open PRs on GitHub (four open: #407,
#525, #527, #528; none is a rider), `git branch -r --no-merged origin/master` (no rider branch exists), QA verdicts
from the QA board and `docs/qa/review-*.md` on master. "none yet" means nothing was found; nothing is guessed.

| Rider | Owner / board item | PR (state) | QA verdict | Merged SHA on master | Gate row | Note |
|---|---|---|---|---|---|---|
| R5 | **N13**: private note rows. | Builder B | B 0p | **merged** (#508, e1e3e37) | **NP1** |
| R9 | **", best"** | Core | Core 0w | **merged** (#504, 134759f) | **DB1** |
| R10 | **#403 eyes, inert**: in the build, off, nothing on the phone turns them on. | Builder A | A 0j | **merged** (#403, a88a1ed), inert | **EY0** |
| R8 | **PN-MENTION**: an "@Private note" mention never resolves to a private note (Core half: `NoteList.resolve`, `Notes.swift:35-43`, has no `isPrivate` filter today), and the object page never shows a private note's body (Builder B half: `InstanceBody`, `ObjectPage.swift:348`). | Core, Builder B | Core 0ad, B 0r | not started | **MN1** |
| R11 | **Trip bands**: Review's task and cooking bands count by each item's own op zone (`OpZones`), not the phone's zone (`ReviewWeek.swift:53-65` today). Rides along: G1, The week page (`ReviewView.swift:62-90`); G2, a cook files on its finish day everywhere, so the Day log changes (`DayStory.swift:241-249`, decisions 1:40 pm). Spec: `fixtures/trip-week.md`, 13 `ReviewTripWeekTests` names. | Core | Core 0ae | not started | **TB1** |
| R14 DST: DS8 repeated 1:30 am, with DS29, DS36 (new, 1:52 pm) | Core 0ag | none yet | none yet | none yet | none yet (fixture DS8, DS29, DS36) | `TessGrammar.swift:672-677` `bySettingHour` picks the PDT 1:30. Due before Oct 31 night. |
| R1 | **HW19**: "sick", "unwell" and "feeling sick" walled in `PrivateFacts.symptoms` (`PrivateFacts.swift:55-58` has none of them today). Ships only with the CR1 sick-slang mask (decisions 1:36 pm), so "sick of this" stays plain. | Core | Core 0ac, slice 1 | not started | **HP1** |
| R6 | **N15**: a one-time launch pass marks notes from before #422 private when they hold a secret word with a value. Today `DayStory.swift:345-347` still prints "Note:" and an old note's title; no such pass exists in `App/` or `TesseraCore/Sources/`. | Core | Core 0aa | not started | **NP2** |
| R7 | **P14**: Siri's Add a Task checks `PrivateFacts.isWalled(title)`. Master's `Intents.swift` still checks only `SecretWords.hasValue`. "pay rent 2100 friday" stays a task. | Core | Core 0l (tests 0l-2) | not started | **P14**, now required |
| R2 | **HW13** (rides P14): Siri Add a Task with "weighed 82.2" saves a private note and replies "Body weight logged." without the number. | Core | Core 0ac (with 0l) | not started | **P14** gains this phrase |
| R3 | **HW9** (P16): `requiresAuthentication` on Tell Tess and Add a Task. | Core | Core 0ac (P16 under 0l) | not started | **HP2** |
| R4 | **HW11** (with N18): the body check runs before `parsePastLog`, so "weighed 82.3 yesterday" is private. | Core | Core 0ac "Then", 0l-2, notes half 0aa | not started | **HP3** |
| R12 | SAVE A COPY's default name becomes "Before update <day>.tessera" (today "Tessera-<day>", `Features/Backup/BackupKeeper.swift:170`), and rotation and pruning touch only the rolling prefix, with a test. | Core | Core 0af | not started | **SC1** |
| R13 | SAVE A COPY warns "This is the Backups folder. Daily copies here get replaced. Save somewhere else?" when he picks the Backups folder. After R12. | Builder B | B 0t | not started | **SC2** |
| Possible: DS37 | Builder B 0u | none yet | none yet | none yet | none yet | Rider only if Product names it. `NotesView.swift:272`. |
| Possible: DS18, DS35 | Builder A 0n | none yet | none yet | none yet | none yet | Rider only if Product names it. `WorkoutFinishView.swift:96`, `ExerciseDigest.swift:106`. |

**Realistic F fixes**

| Fix | Owner / board item | PR (state) | QA verdict | Merged SHA on master | Gate row | Note |
|---|---|---|---|---|---|---|
| F1 one UNDO slot | Core 0s; B 0i; A 0i | none yet | none yet | none yet | UW1 | No `UndoWindow` or `UndoSlot` on master. |
| F2 shared `UndoWindow` | Core 0s; A 0i; B 0i | none yet | none yet | none yet | UW1, X1 to X14 | With F1. |
| F3 note delete UNDO | B 0i, 0p | none yet | none yet | none yet | X11, N35 | Needs F2. |
| F4 Routines windows | A 0i, 0f | none yet | none yet | none yet | X6, X7 | `ios/receipts-thing-first` (0f, no PR) has receipts only, not windows. |
| F6 "paid rent 2100 fri" | Core 0aa | none yet | none yet | none yet | N28, N29 | With R6. |
| F7 "Private task" titles | Core 0y, 0l; A 0e; B 0n | none yet | none yet | none yet | SH14 | No `isPrivateTitle` on master yet. |
| F8 RenameObject key guard | Core 0k | none yet | none yet | none yet | N24 | |
| F9 Notes writing line | B 0p | none yet | none yet | none yet | N3, N7 | |
| F10 pasted key stripped | B 0p | none yet | none yet | none yet | N21, N22 | |
| F12 Backups "Stop using it" | B 0o | none yet | none yet | none yet | S59, S60, X18 | |

**Counts at 1:55 pm.** Riders R1 to R14: 3 merged and QA PASS (R5, R9, R10), 0 open PR, 11 not started. F fixes:
0 merged, 0 open PR, 10 not started. Also merged since a36b161 and QA PASS but not riders: #507 (a5f9787, PASS at
90c9833) and #512 (fbede70, PASS at 04eda7c). Both ride in any pin cut from master now.

## 1. What is already in (merged after a36b161)

`git log --oneline --first-parent a36b161..origin/master` lists 24 merges. Only three touch app or engine code; the
rest are docs and the Plan my day eval script (`scripts/ai/plan_my_day_eval.py`, not in the app).

| Merge | PR | What | Checked on master |
|---|---|---|---|
| a88a1ed | #403 | Tess's eyes, off by default. **Inert on the phone.** | `App/AppModel.swift:98-99`: `tessHasEyes` is only `LaunchFlags.has("-tessEyes")`, and LaunchFlags works only on the Simulator. Nothing sends `.backgrounded` to the soul router (`Features/Tess/SoulRouter.swift:180-182` handles it; no `soul.handle(.backgrounded)` anywhere). |
| 134759f | #504 | ", best" in the Day log and Review's tapped day (Core 0w) | `DayStory.swift:225` writes `", best"`; `ReviewWeek.swift:175` finds `", best."`; `WeekFactsTests.swift:109`. |
| e1e3e37 | #508 | N13: a private note's row shows only "Private note" (Builder B 0p) | `Features/Notes/NotesView.swift:186` uses `NotesCopy.preview`, which is empty for a private note (`:290-292`); test in `TesseraTests/NoteEditorTests.swift`. |

Docs and scripts: #499, #500, #501, #502, #503, #505, #506, #509, #510, #511, #513, #514, #515, #516, #517, #518,
#519, #520, #521, #522, #523. Catalog on master: `SystemCatalog.swift:350` reads `nonisolated ... version: 9`.

**Open branches** (`git branch -r --no-merged origin/master`): none of them carries a rider below. `core/tess-eyes`
(#407) is v10 and stays out of this pin. `core/thing-first-lines` (#512, Core 0p) and `ios/receipts-thing-first`
(Builder A 0f) are receipt work, in only if merged before the pin is named.

## 2. The riders

Status words: **merged**, **open PR**, **not started** (no branch and no commit on master).

### Next build first

| # | Item | Owner | Board | PR or status | Gate step |
|---|---|---|---|---|---|
| R1 | **HW19**: "sick", "unwell" and "feeling sick" walled in `PrivateFacts.symptoms` (`PrivateFacts.swift:55-58` has none of them today). Ships only with the CR1 sick-slang mask (decisions 1:36 pm), so "sick of this" stays plain. | Core | Core 0ac, slice 1 | not started | **HP1** |
| R2 | **HW13** (rides P14): Siri Add a Task with "weighed 82.2" saves a private note and replies "Body weight logged." without the number. | Core | Core 0ac (with 0l) | not started | **P14** gains this phrase |
| R3 | **HW9** (P16): `requiresAuthentication` on Tell Tess and Add a Task. | Core | Core 0ac (P16 under 0l) | not started | **HP2** |
| R4 | **HW11** (with N18): the body check runs before `parsePastLog`, so "weighed 82.3 yesterday" is private. | Core | Core 0ac "Then", 0l-2, notes half 0aa | not started | **HP3** |
| R5 | **N13**: private note rows. | Builder B | B 0p | **merged** (#508, e1e3e37) | **NP1** |
| R6 | **N15**: a one-time launch pass marks notes from before #422 private when they hold a secret word with a value. Today `DayStory.swift:345-347` still prints "Note:" and an old note's title; no such pass exists in `App/` or `TesseraCore/Sources/`. | Core | Core 0aa | not started | **NP2** |
| R7 | **P14**: Siri's Add a Task checks `PrivateFacts.isWalled(title)`. Master's `Intents.swift` still checks only `SecretWords.hasValue`. "pay rent 2100 friday" stays a task. | Core | Core 0l (tests 0l-2) | not started | **P14**, now required |
| R8 | **PN-MENTION**: an "@Private note" mention never resolves to a private note (Core half: `NoteList.resolve`, `Notes.swift:35-43`, has no `isPrivate` filter today), and the object page never shows a private note's body (Builder B half: `InstanceBody`, `ObjectPage.swift:348`). | Core, Builder B | Core 0ad, B 0r | not started | **MN1** |
| R9 | **", best"** | Core | Core 0w | **merged** (#504, 134759f) | **DB1** |
| R10 | **#403 eyes, inert**: in the build, off, nothing on the phone turns them on. | Builder A | A 0j | **merged** (#403, a88a1ed), inert | **EY0** |

### Before Oct 26

| # | Item | Owner | Board | PR or status | Gate step |
|---|---|---|---|---|---|
| R11 | **Trip bands**: Review's task and cooking bands count by each item's own op zone (`OpZones`), not the phone's zone (`ReviewWeek.swift:53-65` today). Rides along: G1, The week page (`ReviewView.swift:62-90`); G2, a cook files on its finish day everywhere, so the Day log changes (`DayStory.swift:241-249`, decisions 1:40 pm). Spec: `fixtures/trip-week.md`, 13 `ReviewTripWeekTests` names. | Core | Core 0ae | not started | **TB1** |

### Step 0 renaming

| # | Item | Owner | Board | PR or status | Gate step |
|---|---|---|---|---|---|
| R12 | SAVE A COPY's default name becomes "Before update <day>.tessera" (today "Tessera-<day>", `Features/Backup/BackupKeeper.swift:170`), and rotation and pruning touch only the rolling prefix, with a test. | Core | Core 0af | not started | **SC1** |
| R13 | SAVE A COPY warns "This is the Backups folder. Daily copies here get replaced. Save somewhere else?" when he picks the Backups folder. After R12. | Builder B | B 0t | not started | **SC2** |
| R15 Review foot line out of Tess's band (Design v9 walk, must land) | Builder B 0x | none yet | none yet | none yet | none yet | `HomeSpatialView` HomeLinkLine. |
| R16 Routines Tess line and "Add an exercise" out of the band, 84 pt inset (Design v9 walk, must land) | Builder A 0q | none yet | none yet | none yet | none yet | |
| R17 Resume key progress reads "sets", not "targetSets" (decisions 2:28 pm) | Builder A 0r | none yet | none yet | none yet | none yet | `NowPage.swift:209`; every exercise counts 3 planned sets today. |

### Fixes from the Research fixtures (F1 to F12)

All 12 are **not started** on master (no `UndoWindow` or `UndoSlot` type exists yet). None changes the catalog, so
each can ride. "Realistic" means small, already ruled, and owned by someone with the lane open; the rest wait for a
later build and are not gate rows here.

| # | Item | Owner | Board | Realistic for this pin? | Gate step |
|---|---|---|---|---|---|
| F1 | One UNDO slot: capture UNDO never takes back a Home "done" (decisions 1:35 pm). The top fix after the next-build-first rows. | Core, then Builder B and Builder A | Core 0s; B 0i; A 0i | yes | **UW1**, `fixtures/undo-collision.md` |
| F2 | One shared `UndoWindow`: 4 s new, 10 s change, 10 s for all under VoiceOver, paused in the background. | Core, then Builders | Core 0s; A 0i; B 0i | yes, with F1 | **UW1**, X1 to X14 |
| F3 | Deleting a note gets "Note, taken back." and a 10 s UNDO. | Builder B | B 0i, B 0p | yes | X11, N35 |
| F4 | Routines and the editor get real windows and "Push A, taken back." | Builder A | A 0i, A 0f | yes | X6, X7 |
| F5 | Undoing a finish removes the Health workout; hold-to-finish gets UNDO. | Core, Builder A | Core 0s; A 0i | no, needs the Health delete path and a device check | (later) |
| F6 | "paid rent 2100 fri" is a private dated note; no money phrase in the miss log. | Core | Core 0aa | yes, with N15 | N28, N29 |
| F7 | A walled task title reads "Private task" on the hero, widget, Lock Screen and Live Activity. | Core, Builder A, Builder B | Core 0y and 0l; A 0e; B 0n | yes, the helper rides with P14 | SH14 |
| F8 | RenameObject gets the Claude key guard and the private check. | Core | Core 0k | yes | N24 |
| F9 | Notes writing line says "Note, kept." or "Private note, kept." with a 4 s UNDO. | Builder B | B 0p | yes | N3, N7 |
| F10 | A pasted Claude key is stripped and the rest kept. | Builder B | B 0p | yes | N21, N22 |
| F11 | Recipe to Groceries and paste windows and lines. | Builder B | B 0m, B 0i | no, Kitchen work; next Groceries change | (later) |
| F12 | Backups "Stop using it" clears `backupFolderName` and its UNDO sits under its line. | Builder B | B 0o | yes | S59, S60, X18 |

**Count.** 13 riders (R1 to R13: 3 merged, 10 not started) plus 10 realistic F fixes. Two F fixes (F5, F11) wait.

**Not in this pin:** #407, the flag-to-setting PR, the Design 70 LOOK row and the `.backgrounded` sender. All four
are the v10 pin (`next-build-v10.md`).

## 3. The gate (changes vs the a36b161 script)

The riders script is `next-build-script-v9.md` copied and changed as below. Row ids marked "new" are proposals.

**Change**
- **V0.** `git log --oneline --first-parent a36b161..<riders pin>` lists #403, #504 and #508 and the rider merges,
  and **no #407 merge**. `SystemCatalog.swift` at the pin reads `CatalogPackage(id: "system", version: 9, ...)` with
  `nonisolated`, and nothing at 10. Fail: no install.
- **V1 to V3.** The upgrade source is a36b161's v9 store (seeded on the Simulator with notes, a private note, a body
  weight and a best set). The catalog doesn't move, so every row is byte-identical and no field is added. Keep the
  v5 chain once (444e72b's copy into the riders pin), in case his phone never got a36b161. V3's restore time is set
  from a fresh run on a36b161.
- **V4 becomes "a36b161 over the riders pin".** Install a36b161 over the riders pin's store without deleting the app.
  Expect: opens his data normally, no launch note, every row unchanged, notes N15 marked private stay private (a36b161
  has #422's private notes). **7b321d2 is never installed again**: it predates #422, so it shows private notes in
  plain text, and it has no newer-store check (decisions 1:41 pm).
- **B5 wording.** Master's launch note is "Your data is from a newer Tessera, so I left it untouched. Update the app
  to open it. Nothing you do this time will be kept." (`TesseraSchema.swift:54-55`). B5 still makes its v10 store
  from #407's head, which is fine: it only proves the riders pin refuses a newer store.
- **M1 and P14 lose "skip if not in".** M1 is in every build from a36b161 on. P14 is required and gains "weighed
  82.2" (HW13).

**Add**

| New row | Do | Expect |
|---|---|---|
| EY0 | Phone-shaped build, no flags. Home, the live workout corner. | No eyes anywhere. No setting for them anywhere. |
| DB1 | Log a set that beats his best, open the Day log, then Review and tap that day. | "Bench 85 × 8, best." in the Day log; the hero says "Bench best". |
| NP1 | Notes: add "gate code 4417" as a second line to a private note, go back to the list; VoiceOver on. | The row reads "Private note" and the time, nothing under it. VoiceOver reads the same. |
| NP2 | Sim: on 7b321d2 write the note "wifi password is hunter2", install a36b161, then the riders pin. | After the first launch the note is private: Notes and the Day log read "Private note". A second launch writes nothing. |
| MN1 | Write a plain note "see @Private note"; tap the link. VoiceOver on. | The mention doesn't link to any private note. The object page never shows a private note's body or "Private: yes". |
| HP1 | Sim with the Claude spy: `feeling sick, no gym`, `unwell today`, then `sick of this traffic`. | Zero requests for the first two; the third stays plain (CR1). |
| HP2 | Lock the Simulator; Siri: Add a Task and Tell Tess. | Siri asks for Face ID before writing. |
| HP3 | Type `weighed 82.3 yesterday`, then `slept 6 hours last night`. | Each is private: never "Noted for Thursday." with the number in a plain note. |
| TB1 | `ReviewTripWeekTests` (13 names) pass; then the Sim with `-demoTime` on a trip week: a task done at 9 pm Pacific, a cook finished after midnight. | Each lands on its own zone's day in Review's bands, The week and the Day log. |
| SC1 | SAVE A COPY; read the suggested name. Background past the daily copy. | "Before update <day>.tessera". The rolling seven never replace or prune it. |
| SC2 | SAVE A COPY into the Backups folder. | The warning line; saving elsewhere is one tap. |
| UW1 | VoiceOver on: Home swipe done, a capture, delete a note. | Each UNDO stays 10 s and takes back what its line names: "X, taken back." |

Fixture rows for F1 to F12 run under their own ids on the PR that closes them, and on the pin if the PR is in. A row
whose PR isn't in is skipped, not failed.

`scripts/test.sh` on the riders pin ends "All green" before anything installs.

## 4. Rollback

**After the riders pin, the rollback is a36b161.** Both are Catalog v9, so a36b161 opens his data normally (V4),
with no launch note and nothing lost. This is true even if his phone never ran a36b161. Step 0 SAVE A COPY still runs
before the install, saved outside the Backups folder and named "Before <riders SHA>" (pin-checklist section 6).

**Never 7b321d2** (nor 444e72b): no newer-store check, and it predates #422.

**For the v10 pin later**, the riders pin becomes the rollback, so it must be on his phone before v10 goes on
(`next-build-v10.md` section 5).

## 5. Blocking and open

- **a36b161 isn't confirmed on his phone.** Not a blocker for the riders pin (same catalog), but the board needs the
  install line. His phone has 7b321d2 (installed Oct 16, 9:57 am), and its free signing lapses around Fri Oct 23, 9:57 am.
- **Oct 26.** The pin must reach his phone before the trip. Core 0ae is not started and its spec has 7 failing
  tests today.
- **HW19 needs CR1.** Slice 1 ships only with the sick-slang mask. If CR1 isn't ready, HW19 waits too.
- **Nothing from the list has a branch** except what is already merged. Ten riders are not started.
- **Board ids not on master yet:** none; Core 0aa to 0af and Builder B 0p, 0r, 0t are all on master's boards.
