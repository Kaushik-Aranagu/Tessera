# The v10 pin, alone after the last v9 release on his phone (Product items AL and AT)

For: Product, Core, Builder A, Builder B, QA. Owner: Research lab. Fri Oct 16, 2026 (Pacific).
Read by hand on `origin/master` at `5984f40` (Merge #523). Nothing was built or run. Every value is a placeholder.
Rebased Fri Oct 16, about 5 pm PT, on decisions 3:03 pm (release on merge; 56dd028 is release 1 over a36b161).

**The ruling (Product item AT, 1:43 pm, rebased on decisions 3:03 pm).** Releases now go out on merge, all on v9
(`next-build-v9r.md`). v10 ships alone in a later pin, and its base is **the last v9 release on his phone (its SHA is named when #407 is ready), not a36b161**. Everything
else that isn't v10 moved to `next-build-v9r.md`.

**What makes this pin v10, in merge order:**
1. #407 rebased (Catalog v10, `tessEyes`), with the v9-opens-v10 test.
2. Flag to setting (Builder A).
3. The Design 70 LOOK row (Builder B).

Plus the `.backgrounded` sender for #403's settle fix, which only matters once the eyes can be on.

**Before #407 merges:** every rider is in a release on his phone (decisions 3:03 pm, (5)). The last v9 release on his phone (its SHA is named when #407 is ready) is this pin's only rollback.

## 1. The items

| # | Item | Owner | Board | PR or status | Gate step |
|---|---|---|---|---|---|
| V1 | **#407 Catalog v10, `tessEyes`**: one optional `.bool` on Settings, `showsTessEyes = tessEyes ?? false`, catalog 9 to 10. Rebase on master (after the last v9 release is on his phone): the conflict is `SystemCatalog.swift:350`; keep `nonisolated` and set `version: 10`. | Core | A 0j (the #407 steps) | **open PR, not rebased** (`core/tess-eyes`, 2 commits, base 5af8f2c) | **V0-10**, **U1 to U4** |
| V2 | **The v9-opens-v10 test** (decisions 12:58 pm): a test on #407 that the v9 code refuses a v10 store (`TesseraDatabaseSchema.isNewer`), leaves the file untouched and takes no daily copy. | Core | A 0j | not on the branch yet | Unit test in `scripts/test.sh`; **U3** |
| V3 | **Flag to setting**: `AppModel.tessHasEyes` reads `settings.showsTessEyes`, not `LaunchFlags.has("-tessEyes")` (master, `App/AppModel.swift:98-99`). | Builder A | A 0j ("After both") | not started (waits on V1) | **E1**, **E3** |
| V4 | **Design 70 LOOK row**: "Tess has eyes: **no**." as LOOK's third sentence, bound to `tessEyes`, default no. With no Settings page yet, LOOK sits at the foot of The week (`ReviewView.swift:220-236`). | Builder B | B 0k, B 0o (the eyes row after #407) | not started (waits on V1 and V3) | **E2** |
| V5 | **The `.backgrounded` sender**: the soul router settles Tess to rest on `.backgrounded` (`Features/Tess/SoulRouter.swift:180-182`, QA review-403 L6), but nothing sends it (no `soul.handle(.backgrounded)` on master). Send it from the scene-phase change. | Builder A | A board ("Rerun the router and working tests for .backgrounded", `ios-a.md:40`) | not started | **E5** |

**Count: 5 items**, none merged. #403 itself is already on master (a88a1ed) and ships, inert, in every v9 release from 56dd028 on.

**Nothing else rides.** `git log --oneline --first-parent <last v9 release>..<v10 pin>` lists only V1 to V5 as code
merges, plus docs. Any other code merge waits for the pin after, so a v10 problem is never mixed with another change.

## 2. The gate

The v10 script is the riders script (`next-build-v9r.md` section 3) copied and changed as below.

**Change**
- **V0 becomes V0-10.** `git log --oneline --first-parent <last v9 release>..<v10 pin>` lists the #407 merge and V3 to V5,
  nothing else with code. `SystemCatalog.swift` at the pin reads `CatalogPackage(id: "system", version: 10, ...)`
  with `nonisolated`, and nothing at 11. Fail: no install.
- **V1 to V3.** The upgrade source is the last v9 release's store (seeded with notes, a private note, a body weight and
  a best set). Count every v9 row before and after: all byte-identical, `tessEyes` added empty. V3 restores a v9 copy
  into the v10 build; Builder A sets the limit from a fresh time on the last v9 release.
- **V4 is retired.** No older build is installed over a v10 store on the phone. U3 and U4 replace it.
- **M1 and P14 stay hard rows** (in every v9 release from 56dd028 on).

**Add**

| New row | Do | Expect |
|---|---|---|
| U1 | Install the v10 build over the last v9 release's store without deleting the app. | Clean launch. All rows identical. Settings has `tessEyes` empty. No launch note. |
| U2 | Back up on v10, then restore that copy on v10. | Round-trips; `tessEyes` comes back as set. A pre-v10 copy reads `tessEyes` as no (S13). |
| U3 | Sim: install the last v9 release over the v10 store (the rollback). | The launch note. The v10 file's checksum is unchanged. Background twice: no new copy in Documents/Backups (M1). |
| U4 | Sim: on the last v9 release, restore a v10 copy. | "That copy is from a newer Tessera. Update first." Nothing restored (B6). |
| E1 | Phone build, no flags, fresh and upgraded store. | No eyes anywhere (Home, live workout corner). `showsTessEyes` is false. |
| E2 | LOOK at the foot of The week: read the third sentence, cycle it. | "Tess has eyes: **no**." Yes shows the eyes at once; one op with UNDO; back to no hides them. |
| E3 | Sim: launch with `-tessEyes` and the setting at no. | Whatever V3's PR rules for the flag on the Simulator. On the phone the flag is ignored (LaunchFlags). |
| E4 | Eyes on, ask Tess something that goes to Claude (fake key on the Sim). | Eyes hide while she works and come back after; Reduce Motion keeps the blink, no glance. |
| E5 (new) | Eyes on, start an answer, then leave the app mid-line and come back. | Tess is at rest, eyes open, no frozen glance or half-done Done. |

**The drill is the gate for U1 to U4.** Builder A runs `docs/research/v10-rollback-drill.md` (R0 to R6, 33 rows,
Simulator, about 2 hours) on the named v10 SHA, and QA reads the evidence, before Product says the v10 pin may go on
(decisions 1:41 pm). One change to the drill: **its "Pin" build is now the last v9 release on his phone (its SHA is named when #407 is ready), not a36b161.** The run, in order:
(1) install that v9 release on the Simulator over a seeded v9 store, save its Step 0 copy outside Backups as "Before
<v10 SHA> (from <v9 release SHA>) <time>" and check it (catalog 9, `backupInfo` reads `tessera-backup`, `1`; drill R1);
(2) install v10 over it without deleting the app; (3) verify U1 and U2 (drill R2); (4) roll back: install the v9
release over the v10 store and prove it refuses the v10 store, never writing to it, as U3 and U4 already say (launch
note, v10 file checksum unchanged, no new copy in Backups, a v10 copy refused; drill R3); then restore the "Before
<v10 SHA> (from <v9 release SHA>)" copy on the v9 release, relaunch, and check every v9 row is back (drill R4, R5).
Releases after a36b161 can change `BackupKeeper` (Core 0af renames the Step 0 copy and keeps rotation on the rolling
prefix; not in 56dd028 yet), so a drill run with a36b161 as the rollback would not test the build he actually rolls back to. Its R6 (7b321d2 must never be
used) stays as written.

`scripts/test.sh` on the v10 pin ends "All green" before anything installs.

## 3. Rollback after the v10 pin

**Short version.** After v10 is installed, the only rollback is the last v9 release on his phone. It is safe because it refuses the
v10 store, not because it opens it: it opens **empty**, with the launch note, and keeps nothing he does.

**Why.** #407 is additive (one optional field, no GRDB migration, no new table or column), but seeding v10 stamps
every system class with `packageVersion` 10 (`SystemCatalog.swift:436`). The last v9 release, like a36b161, has
`TesseraDatabaseSchema.isNewer` (`TesseraDatabaseSchema.swift:13-22`): it sees 10 > 9, leaves the file untouched,
runs the session in memory and shows "Your data is from a newer Tessera, so I left it untouched. Update the app to
open it. Nothing you do this time will be kept." (`TesseraSchema.swift:53-56`). M1 stops the daily copy from an
in-memory store (`TesseraBackup.swift:123-125`), so his seven good copies stay. A v10 backup is refused
(`TesseraBackup.swift:214`).

**Getting his data back** means rolling forward to a fixed v10 build, or restoring the Step 0 copy ("Before <v10
SHA> (from <v9 release SHA>) <time>", saved outside Backups) on the last v9 release. That restore keeps the v10 store as a Before-restore copy (up to 3
kept), so only work done during the in-memory rollback is lost (drill R5).

**Never 7b321d2** (nor 444e72b). It has no newer-store check, so it would open and write to the v10 store, and it
predates #422, so it shows private notes in plain text (drill R6).

**a36b161 after v10** behaves the same as the last v9 release (it refuses and opens empty), but it lacks the privacy
fixes in 56dd028 and later releases, so it is not the rollback.

**One catch.** If any rider is not yet in a release on his phone when #407 is ready, v10 waits.

**Proposed pin-checklist section 7 line:** "Once the v10 pin is installed, the rollback is the last v9 release on his phone, <v9 release SHA>. It
refuses the v10 store and runs in memory with the launch note (U3); it does not show his data until the Step 0 copy is restored on it. 7b321d2 and 444e72b
are never installed again, nor anything older than a36b161. Step 0 SAVE A COPY runs on that v9 release before the v10 install, saved outside Backups
as 'Before <v10 SHA> (from <v9 release SHA>) <time>' and checked (the Mac keeps the last 3, and the a36b161 copy is never deleted)."

## 4. Blocking and open

- **#407 is held** until every rider is in a release on his phone, then the v10 gate and drill run (was: until the riders pin is; before that, a36b161).
- **#407 needs a rebase** and the v9-opens-v10 test. `docs/qa/review-407.md` still says "Catalog v9" in its title;
  QA re-reviews the rebased head.
- **V3 and V4 wait on #407.** Product ruled they ship in the same pin, so the eyes are never in a build with a
  setting that does nothing.
- **The drill's Pin column** reads a36b161 today; Builder A runs it with the last v9 release on his phone (its SHA is named when #407 is ready).
- **pin-checklist section 7** on master names a36b161 as the rollback after v10; it needs the line above once the
  last v9 release's SHA is named.
