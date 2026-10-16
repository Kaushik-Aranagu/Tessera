# Next build after pin a36b161: the Catalog v10 list (Product item AL)

For: Product, Core, Builder A, Builder B, QA. Owner: Research lab. Fri Oct 16, 2026 (Pacific).
Read by hand on `origin/master` at `751b373` (Merge #506). Nothing was built or run. Every value is a placeholder.

**The pin today.** a36b161 (#498 M1), Catalog v9, named 1:08 pm (decisions.md). It carries #475 (B5/B6, the newer
store and newer backup refusal) and #498 (M1, no daily copy from a store with no file). It does not carry P14, ", best",
the pre-#422 note pass, #403 or #407. On master the board still says Builder A runs the v9 gate, then installs; this
read found no line saying the pin is on his phone yet.

**The next build.** Catalog v10, from #407 (`core/tess-eyes`). It also carries what merged after the pin and the items
below that land before it is named.

**Merged after the pin** (`git log --oneline --first-parent a36b161..origin/master`):

| Merge | PR | What | Code? |
|---|---|---|---|
| dda42e6 | #499 | Kitchen week rulings in the meal plan acceptance | docs |
| 9b3319c | #500 | Kitchen week day one and Shutdown evening fixtures | docs |
| 80b4765 | #501 | Pin named, board and checklist | docs |
| cb9b1d7 | #503 | v9 phone page, Kitchen week rulings | docs |
| a88a1ed | #403 | Tess's eyes, off by default (rebased by a master merge, 15160e0) | **app** |
| 134759f | #504 | ", best" in DayStory and Review (Core 0w) | **app + engine** |
| 7ee602e | #505 | Phone page names the two private-note gaps | docs |
| 751b373 | #506 | Settings day one and Notes day one fixtures | docs |

**Open branches checked** (`git branch -r --no-merged origin/master`): `core/tess-eyes` (#407, 2 commits, base
5af8f2c, not rebased), `core/clock-format` (Core 0q), `ios/voiceover-time-words` (Builder A 0g/0h), `ios/tess-wake`
(Tess picks 18a, carries #403's commits), plus three docs or tooling branches. None of them touches N13, N15, P14 or
the HW rows.

## 1. The required items

Status words: **merged after the pin**, **open PR**, **not started** (no branch and no commit on master).

| # | Item | Why it matters | Owner | Board | PR | Gate step that proves it | Status today |
|---|---|---|---|---|---|---|---|
| R1 | **N13**: a private note's list row shows only "Private note". `NoteRow` drops the body's second line, and VoiceOver's `.combine` reads only the title and time (`Features/Notes/NotesView.swift:186-216`; `:196` prints `rest`). | Today a code added to a note ("gate code 4417") shows on the Notes list and is read aloud. | Builder B | B 0p | none | Fixture N13 (`fixtures/notes-day-one.md`); proposed script row **NP1** (section 3) | not started (master `:196` still prints `rest` under the title) |
| R2 | **N15**: a one-time pass at launch sets `isPrivate` on any note from before #422 whose title or body holds a secret word with a value. | His phone has notes written on 7b321d2 and earlier. The Day log prints them: "Note: Wifi password is hunter2" (`DayStory.swift:347`). | Core | Core 0aa (and the older Secret-word follow-ups rider) | none | Fixture N15; proposed row **NP2** | not started |
| R3 | **P14**: Siri's Add a Task checks `PrivateFacts.isWalled(title)`, saves a walled title as a private note and never reads it back (`TesseraCore/Sources/TesseraIntents/Intents.swift:136-145`). "pay rent 2100 friday" stays a task. | Siri is the one write path that still skips the money and body wall. It says the phrase out loud. | Core | Core 0l (test target 0l-2, `fixtures/siri-privacy-parity.md`) | none | Script row **P14** (`next-build-script-v9.md`, Siri section), now required, not skip-if-not-in; fixture N43, S2 to S19 | not started (master `:140` still checks only `SecretWords.hasValue`) |
| R4 | **", best"** in place of ", PR" in the Day log line and Review's tapped-day hero (`DayStory.swift:225`, `ReviewWeek.swift:174-175`). | House word is "best"; the pin's Day log still says ", PR". | Core | Core 0w | #504 | Proposed row **DB1**; tests `DayStoryTests`, `WeekFactsTests` | merged after the pin (134759f, 1:17 pm) |
| R5 | **#403 Tess eyes, rebased**: two ink dots, blink and glance, off by default. | First half of the eyes; safe on any store (no catalog change). | Builder A | A 0j | #403 | Proposed row **E1** (eyes off with no flag); `TesseraTests/SoulEyesTests.swift` | merged after the pin (a88a1ed, 1:16 pm). Checked on master: MotionPolicy used (`TessSoul.swift:99`, `:101`), eyes hidden while working (`:97`). The phone still can't turn them on (`AppModel.swift:99` reads only `LaunchFlags.has("-tessEyes")`). |
| R6 | **#407 Catalog v10, `tessEyes`**: one optional `.bool` on Settings, `showsTessEyes = tessEyes ?? false`, catalog 9 to 10. | It is what makes this build v10. Merge only once a36b161 is on his phone. | Core | A 0j (the #407 steps; Core's board has no line of its own) | #407 | **V0-10** and **U1 to U4** (section 3) | open PR, not rebased. Base 5af8f2c. A merge onto master conflicts at `SystemCatalog.swift:350`: keep #475's `nonisolated` and set `version: 10`. The "v9 code opens a v10 store" test that decisions 12:58 pm asked for isn't on the branch yet. |
| R7 | **Flag to setting**: `AppModel.tessHasEyes` reads `settings.showsTessEyes`, not `LaunchFlags.has("-tessEyes")`. | Without it the setting does nothing on the phone. | Builder A | A 0j ("After both") | none | Proposed rows **E2**, **E3** | not started (waits on #407) |
| R8 | **Design 70 row**: "Tess has eyes: **no**." as LOOK's third sentence, bound to `tessEyes`, default no. There's no Settings page on master yet, so LOOK sits at the foot of The week (`ReviewView.swift:220-236`). | The only way he can turn the eyes on. | Builder B | B 0k (Settings sheet work also on B 0o) | none | Fixture S11, S13 (`fixtures/settings-day-one.md`); proposed row **E2** | not started (waits on #407 and R7) |

**Merge order** (decisions 12:58 pm and 1:08 pm, unchanged):
1. #403 rebased. **Done** (a88a1ed).
2. #407, only once a36b161 is on his phone, rebased on master with `nonisolated` kept and the v9-opens-v10 test added.
3. Builder A's flag-to-setting PR (R7).
4. Builder B's Design 70 row in LOOK (R8).

P14, N13, N15 and the section 2 items have no catalog change, so they can merge in any order around steps 2 to 4.

## 2. Next build first: the habits and weight week privacy rows

From `docs/research/fixtures/habits-weight-week.md` (working tree, not yet on master). The coordinator puts HW19,
HW13 and HW9 first in the next build (pin-checklist "Next build first", not on master yet). Product 1:23 pm:
"meditated monday" logs to the Monday just gone.

| # | Item | Why it matters | Owner | Board | PR | Gate step | Status today |
|---|---|---|---|---|---|---|---|
| H1 | **HW19**: add "sick", "unwell" and "feeling sick" to `PrivateFacts.symptoms` (`TesseraCore/Sources/TesseraCore/Tess/PrivateFacts.swift:55-58`). | "feeling sick, no gym" isn't walled today, so the router lets it reach Claude (`TessModel.swift:77-79`). High: a health fact leaves the phone. | Core | Core 0ac | none | Fixture HW19; proposed row **HP1** | not started (master's list has no "sick" or "unwell") |
| H2 | **HW13** (rides P14): Siri Add a Task with "weighed 82.2" saves a private note and says only "Private note, kept." | Today it makes a task "weighed 82.2" and Siri reads the weight aloud (`Intents.swift:140`, `TrainingActions.swift:445`). | Core | Core 0ac (with 0l) | none | Fixture HW13; script row **P14** gains this phrase | not started |
| H3 | **HW9** (P16): `requiresAuthentication` on Tell Tess and Add a Task (`Intents.swift:118`, `:149`). | A locked phone in the gym mount can write through Siri today. | Core | Core 0ac (P16 under 0l) | none | Fixture HW9; proposed row **HP2** | not started |
| H4 | **HW11** (with N18): the body check runs before `parsePastLog`, so "weighed 82.3 yesterday" and "slept 6 hours last night" become private, not a plain dated note. | Today the weigh-in is an ordinary note, so it shows in the Day log and rides iCloud backups unmarked (`TessGrammar.swift:126-127` before `:141`, `:153`). | Core | Core 0l-2 (0j R1); notes half on Core 0aa | none | Fixtures HW11, N18; proposed row **HP3** | not started |

The rest of the habits gaps stay on Core 0ac, Builder A 0m and Builder B 0q; they aren't gate rows for this build.

## 3. Top privacy and undo fixes from Research fixtures (12)

Picked from `fixtures/notes-day-one.md`, `fixtures/settings-day-one.md`, `fixtures/shutdown-evening.md`,
`fixtures/kitchen-week-day-one.md`, `undo-windows-audit.md` and `post-pin-403-407.md`. Ranked by harm: anything that
leaks a private word or undoes the wrong thing first, then missing ways back from a destructive write, then window and
line fixes. All 12 are **not started** on master (no branch, no PR); each is in a board item that names it.

| # | Item | Why it matters | Owner | Board | Gate step (fixture row) |
|---|---|---|---|---|---|
| F1 | Capture UNDO takes back a Home "done" while a new capture's line shows (`BottomChrome.swift:728-744` prefers `TessVoice.note`). | An UNDO key must take back what its line names. Today it can undo the wrong thing. | Builder B | B 0i | X13 race (`undo-windows-audit.md`), N6 |
| F2 | One shared `UndoWindow`: 4 s new, 10 s change or destructive, 10 s for all under VoiceOver, paused in background or lock. Replaces 6 hard-coded 4 s and 5 hard-coded 10 s. | Nothing on master reads VoiceOver, and every window keeps running while the phone is locked. | Core (constant), then Builders A and B wire it | Core 0s; A 0i; B 0i | X1 to X14, SH16, N6 |
| F3 | Deleting a note gets a line and a 10 s UNDO, "Note, taken back." (`NoteEditor.swift:170-175`). | The only destructive write with no way back. | Builder B | B 0i, B 0p | X11, N35 |
| F4 | Routines and the editor get real windows, and the lines read "Push A, taken back." (`RoutinesPage.swift:255`, `:267`; `RoutineEditor.swift:215`, `:221`). | Their UNDO never expires, so it can replay over later writes, and the `.partial` outcome is dropped. | Builder A | A 0i, A 0f | X6, X7 |
| F5 | Undoing a finish removes the Health workout; plain hold-to-finish gets the same 10 s UNDO as LOG AND FINISH. | Today an undone finish leaves a workout in Health, and hold-to-finish has no UNDO at all. | Core (Health hook), Builder A (UNDO) | Core 0s; A 0i | X5 |
| F6 | "paid rent 2100 fri" becomes a private dated note, and no money phrase ever lands in the miss log (`TessCaptureEngine.swift:58`). "bought 2 lemons sat" is a plain dated note. | Money text is written to the miss log today, the one log the team reads in the first days. | Core | Core 0aa (0j R2) | N29, N28 |
| F7 | A walled or secret-word task title reads "Private task" wherever it leaves the row: the tomorrow hero, widget, Lock Screen and Live Activity (`PrivateFacts.isPrivateTitle`). | The 9 pm "tomorrow, first" hero and the Live Activity can show "Change the gate code to 4417" on a locked screen. | Core (helper), Builder A (Live Activity), Builder B (hero) | Core 0y and 0l; A 0e; B 0n | SH14 |
| F8 | RenameObject gets the Claude key guard and the private check (`Actions/TrainingActions.swift:501-503`). | It is registered in the action registry with no guard; any future rename path could store a key. | Core | Core 0k (with Core 0aa) | N24 |
| F9 | Writing on the Notes page says "Note, kept." or "Private note, kept." in the context line, with a 4 s UNDO. | A secret line typed there turns private silently, and there is no way back from a new note. | Builder B | B 0p | N3, N7 |
| F10 | A Claude-key paste on the Notes writing line strips only the key and keeps the rest; the editor's key line clears on the next edit (`NotesView.swift:82-83`, `NoteEditor.swift:26`, `:35`, `:132-137`). | Today the whole draft is lost, and the warning never goes away. | Builder B | B 0p (0k, 0j R3) | N21, N22 |
| F11 | Recipe to Groceries and recipe paste get the ruled windows and thing-first lines: "Tacos, 10 added." with 10 s, "Tacos, nothing to add." with no UNDO, paste 4 s not 2 s (`RecipePage.swift:184-229`, `PasteRecipe.swift:216`). | Today a 2 s or 4 s window, and an UNDO shown when nothing was added. | Builder B | B 0m, B 0i | KW5, KW7, X9, X10 |
| F12 | Backups: "Stop using it" clears `backupFolderName`, its line names the thing, and its UNDO sits under the line it answers (`BackupKeeper.swift:142`, `BackupView.swift:92-93`, `:110-116`, `:288-303`). | After stopping, the page shows the after-restore line and tells him to choose a folder he just dropped. | Builder B | B 0o | S59, S60, X18 |

Left out on purpose: S23 (a 401 keeps the key; needs a Product call first), S35 and S36 (cap and spend, not privacy),
X14 (one UNDO under two lines at 4 am; needs a Simulator run first), KW2 and KW26 (Kitchen week planning, a feature).

## 4. Gate changes for v10

The v10 script is `next-build-script-v9.md` copied and changed as below. Row ids marked "new" are proposals.

**Change**
- **V0 becomes V0-10.** `git log --oneline a36b161..<new pin>` lists the #403 merge (a88a1ed) and the #407 merge;
  `SystemCatalog.swift` at the pin reads `CatalogPackage(id: "system", version: 10, ...)`, and nothing at 11. Keep
  `nonisolated` on that line. Fail: no install.
- **V1 to V3 move up one step.** The upgrade source is a copy of his real shape: a36b161's v9 store (seeded on the
  Simulator with notes, a private note, a body weight and a best set), not only the v5 copy. Count every v9 row before
  and after (all byte-identical; `tessEyes` added empty). Keep the v5 chain once (v5 to v10 in one jump), since the
  phone may still be on 7b321d2 if the pin never got installed.
- **V3 timed restore.** Restore a v9 copy into the v10 build. Builder A sets the limit from a fresh before-restore time
  on the pin (the 3.23 s limit was for v5 into v9).
- **V4 is retired.** 7b321d2 is never installed over a v10 store (section 5). In its place, U3 and U4.
- **B5 wording.** Master's launch note is "Your data is from a newer Tessera, so I left it untouched. Update the app to
  open it. Nothing you do this time will be kept." (`TesseraSchema.swift:54-55`, after #498). The v9 script still
  shows the older semicolon form.
- **M1 and P14 lose "skip if not in".** M1 is in every build from a36b161 on. P14 is required for v10 (it missed the
  pin) and gains "weighed 82.2" (HW13).
- **pin-checklist section 7** names a36b161 as the rollback once v10 is installed, with the limit in section 5.

**Add**

| New row | Do | Expect |
|---|---|---|
| U1 | Install the v10 build over a36b161's v9 store without deleting the app. | Clean launch. All rows identical. Settings has `tessEyes` empty. No launch note. |
| U2 | Back up on v10, then restore that copy on v10. | Round-trips; `tessEyes` comes back as set. A pre-v10 copy reads `tessEyes` as no (S13). |
| U3 | Sim: install a36b161 over the v10 store (the rollback). | B5's launch note. The v10 file's checksum is unchanged. Background twice: no new copy in Documents/Backups (M1). |
| U4 | Sim: on a36b161, restore a v10 copy. | "That copy is from a newer Tessera. Update first." Nothing restored (B6). |
| E1 | Phone build, no flags, fresh and upgraded store. | No eyes on the soul anywhere (Home, live workout corner). `showsTessEyes` is false. |
| E2 | LOOK at the foot of The week (Settings once it exists): read the third sentence, cycle it. | "Tess has eyes: **no**." Cycling to yes shows the eyes at once; one op with UNDO; back to no hides them. |
| E3 | Sim: launch with `-tessEyes` and the setting at no. | Decide in R7's PR whether the flag still forces eyes on the Simulator; the row checks whichever is ruled. On the phone the flag is ignored (LaunchFlags). |
| E4 | Eyes on, ask Tess something that goes to Claude (fake key on the Sim). | Eyes hide while she works and come back after; Reduce Motion keeps the blink, no glance. |
| DB1 | Log a set that beats his best, open the Day log, then Review and tap that day. | "Bench 85 × 8, best." in the Day log; the tapped-day hero says "Bench best". Never ", PR". |
| NP1 | Notes: add "gate code 4417" as a second line to a plain note, go back to the list; VoiceOver on. | The row reads "Private note" and the time, nothing under it. VoiceOver reads the same. |
| NP2 | Sim: on 7b321d2 write the note "wifi password is hunter2", then install v10 over it. | After the first launch the note is private: the Notes row and the Day log read "Private note". The pass runs once (a second launch writes nothing). |
| HP1 | Sim with the Claude spy: type `feeling sick, no gym`, `unwell today`. | Zero requests; nothing sent holds "sick". (The sick day mark is a later row.) |
| HP2 | Lock the phone; Siri: Add a Task and Tell Tess. | Siri asks for Face ID before writing. |
| HP3 | Type `weighed 82.3 yesterday`, then `slept 6 hours last night`. | Each is private on the phone: "Private note, kept." or the weigh-in ghost for yesterday, never "Noted for Tuesday." with the number in a plain note. |
| UW1 | VoiceOver on: Home swipe done, a capture, delete a note. | Every UNDO stays 10 s, and each says "X, taken back." (F2, F3). |

Fixture rows F1 to F12 run as their own ids (X, N, SH, KW, S) on the PR that closes them, and on the build if the
PR is in. A row whose PR isn't in the build is skipped, not failed.

`scripts/test.sh` on the new pin still ends "All green" before anything installs.

## 5. Rollback after the v10 build

**Short version.** After v10 is installed, 7b321d2 is not safe. a36b161 is the only rollback, and it is safe
because it refuses the v10 store, not because it opens it. It will not show his data.

**What #407's diff does** (`git diff 5af8f2c origin/core/tess-eyes`, 3 files, +47/-1):
- `SystemCatalog.swift`: one `FieldSpec(key: "tessEyes", name: "Tess's eyes", kind: .bool)` on Settings, and
  `version: 9` to `version: 10`.
- `TesseraSettings.swift`: `tessEyes: Bool?`, `showsTessEyes` (nil is no), read and written by `SettingsStore` and
  `WriteSettings`.
- `SettingsTests.swift`: the off-until-on and rollback tests.
- No GRDB migration, no new table or column, no rename or drop. The migration list at the pin (3 registered) is
  unchanged. So yes, v10 is additive.

**Why a36b161 still won't open it.** Additive doesn't make the store readable by v9. Seeding v10 stamps every system
class with `packageVersion` 10 (`SystemCatalog.swift:436`). a36b161's `TesseraDatabaseSchema.isNewer`
(`TesseraDatabaseSchema.swift:13-22`) sees 10 > 9 and calls the store newer. `TesseraSchema.open` then leaves the file
untouched, runs the session in memory and shows the launch note (`TesseraSchema.swift:53-56`). #498 makes
`writeRolling` return early when the store has no file (`TesseraBackup.swift:123-125`), so his seven good copies
aren't rolled away by empty ones. A v10 backup restored on a36b161 is refused (`TesseraBackup.swift:214`).

So rolling back to a36b161 means: nothing is damaged, but the app opens empty with the note, and nothing he does is
kept. Getting his data back means rolling forward to a fixed v10 build, or (last resort, his call) restoring the
Step 0 copy saved on a36b161 before the v10 install, losing everything since.

**Why 7b321d2 is no longer safe.** 7b321d2 is Catalog v5 and has no newer-store check at all (`git grep isNewer
7b321d2` finds nothing). It would open the v10 store, write to it with code that doesn't know the v8, v9 or v10
fields, take its daily copies from it, and restore any copy. It was only ever tested on the v9 store (V4). It must
not be installed after v10.

**One more catch.** a36b161 is only a real rollback if it is on his phone before #407's build goes on. If the phone
is still on 7b321d2 when v10 is ready, v10 waits (decisions 12:58 pm), because the only build behind it would be
7b321d2.

**Proposed pin-checklist section 7 line:** "Once the v10 build is installed, the rollback is a36b161. It refuses the
v10 store and runs in memory with the launch note (U3); it does not show his data. 7b321d2 and 444e72b are never
installed after v10. Step 0 SAVE A COPY runs on a36b161 before the v10 install."

## 6. Blocking and open

- **#407 is held** until a36b161 is on his phone. No install line is on master yet.
- **#407 needs a rebase** (`SystemCatalog.swift:350`, keep `nonisolated`) and the v9-opens-v10 test (decisions
  12:58 pm). `docs/qa/review-407.md`'s title still says "Catalog v9"; QA re-reviews the rebased head (QA board item 4).
- **R7 and R8 wait on #407.** Until R7 merges, the v10 build has eyes code and a setting that do nothing on the phone.
  Product may want R7 and R8 in the same build as #407, or hold #407 until both are ready.
- **Board ids not on master yet:** Core 0aa, 0ac; Builder B 0p, 0o, 0q; and the pin-checklist "Next build first"
  section. This list uses the ids the coordinator gave.
- **habits-weight-week.md** is in the working tree, not on master; its row ids (HW9, HW11, HW13, HW19) are cited from it.
