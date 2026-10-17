# v10 rollback drill, on the Simulator (Product item AN)

For: Builder A (runs it), QA (reads the evidence), Product (reads the result). Owner: Research lab.
Fri Oct 16, 2026 (Pacific). Read by hand on `origin/master` at `f4bc55b` (Merge #515), with `a36b161`, `7b321d2`
and `origin/core/tess-eyes` (`8f9b6cb`). Nothing was built or run for this page. Every value is made up.

**What it proves.** Before the v10 build goes on Kaushik's phone, the rollback story in `next-build-v10.md` section 5
and pin-checklist section 7 holds on a real build: a36b161 refuses the v10 store and runs in memory without touching
it, v10 opens again with everything there, the Step 0 copy is a working last resort, and 7b321d2 must never be used.

**Never the phone.** Every command names a Simulator by its UDID. Nothing here uses `devicectl`, `booted`, or a
device destination. Launch flags are read only through `LaunchFlags` (`App/LaunchFlags.swift`), which exists only
on the Simulator, so they could never reach his data anyway. Only `-demoTime` and `-resetDemo` are used, and
`-resetDemo` only once, in R1. Never restore a copy of his real backup on these Simulators.

**The three builds.**

| Name | SHA | Catalog | Newer-store check | Role |
|---|---|---|---|---|
| Pin | `a36b161` (#498 M1) | 9 | Yes: `TesseraDatabaseSchema.isNewer` (`TesseraDatabaseSchema.swift:13`), store refused at `TesseraSchema.swift:53`, backup refused at `TesseraBackup.swift:214`, no copy from a fileless store at `TesseraBackup.swift:125` | The rollback once v10 is on |
| v10 | `$V10`: the named v10 pin, master with #407 merged (rebased, `nonisolated` kept, `version: 10`) | 10 | Yes (same files as the pin; no diff in `Export/`, `Model/`, `Features/Backup/` between a36b161 and f4bc55b) | The build under test |
| Old | `7b321d2` | 5 | **None** (`git grep isNewer 7b321d2` is empty; its backup check compares migrations only, `TesseraBackup.swift:211`) | R6 only, on a throwaway Simulator |

**Do not use `core/tess-eyes`'s head as the v10 build.** Its base is 5af8f2c (#422), so it has no #475 newer-store
check and no #498 M1. It makes a v10 store, but it is not the build he gets. Until `$V10` is named, a dry run may use
a local, uncommitted merge of `origin/core/tess-eyes` onto master in a throwaway worktree (resolve
`SystemCatalog.swift:350` as `public nonisolated static let package = CatalogPackage(id: "system", version: 10, ...`).
Only a run on the named `$V10` counts for the gate.

## R0. Setup (Mac, before anything installs)

```bash
# One folder for the drill, no spaces in the path (sqlite URIs read cleaner).
export DRILL=~/TesseraDrill EV=~/TesseraDrill/evidence REPO=~/pilot
mkdir -p "$DRILL" "$EV"
cd "$REPO" && git fetch -q origin
export V10=<named v10 SHA>     # full SHA from decisions.md

# V0-10 first: the build under test is really v10 and still carries the pin's guards.
git merge-base --is-ancestor a36b161 "$V10" && echo "pin is an ancestor"
git log --oneline --merges a36b161.."$V10" | grep -E "#403|#407"
git show "$V10":TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift | grep -n 'CatalogPackage(id: "system"'
git grep -n "isNewer" "$V10" -- TesseraCore/Sources | head
git grep -n "isNewer" 7b321d2 -- TesseraCore/Sources | wc -l     # must print 0

# One worktree and one DerivedData per SHA.
for sha in a36b161 "$V10" 7b321d2; do
  short=$(git rev-parse --short "$sha")
  git worktree add --detach "$DRILL/src-$short" "$sha"
  (cd "$DRILL/src-$short" && xcodegen generate &&
   xcodebuild -scheme Tessera -configuration Debug \
     -destination 'platform=iOS Simulator,name=iPhone 17' \
     -derivedDataPath "$DRILL/dd-$short" build | xcbeautify)
done
export APP_PIN="$DRILL/dd-a36b161/Build/Products/Debug-iphonesimulator/Tessera.app"
export APP_V10="$DRILL/dd-$(git rev-parse --short "$V10")/Build/Products/Debug-iphonesimulator/Tessera.app"
export APP_OLD="$DRILL/dd-7b321d2/Build/Products/Debug-iphonesimulator/Tessera.app"

# A fresh iPhone 17 just for the drill (the dev Simulator stays as it is).
RUNTIME=$(xcrun simctl list runtimes | awk '/iOS 27/ {print $NF}' | head -1)
export UDID=$(xcrun simctl create "Drill v10" "iPhone 17" "$RUNTIME")
xcrun simctl boot "$UDID" && open -a Simulator
export BID=com.kaushikaranagu.tessera
```

Paste these helpers into the same shell. `snap` stops the app, then checksums and copies the store; every query runs
on the copy, read-only, never on the live file.

```bash
data() { xcrun simctl get_app_container "$UDID" "$BID" data; }
store() { echo "$(data)/Library/Application Support/Tessera"; }
launch() { xcrun simctl launch "$UDID" "$BID" -demoTime 18:10 "$@"; }
background() { xcrun simctl launch "$UDID" com.apple.Preferences >/dev/null; }   # sends Tessera to the background
shot() { xcrun simctl io "$UDID" screenshot "$EV/$1.png"; }
q() { sqlite3 "file:$1/tessera.sqlite?mode=ro" "$2"; }
snap() {   # snap <label>
  local out="$EV/$1"; mkdir -p "$out"
  xcrun simctl terminate "$UDID" "$BID" 2>/dev/null
  (cd "$(store)" && ls -la > "$out/store-ls.txt" && shasum -a 256 tessera.sqlite* > "$out/store.sha256")
  cp "$(store)"/tessera.sqlite* "$out/"
  ls -la "$(data)/Documents/Backups" > "$out/backups-ls.txt" 2>&1
  ls -laR "$(store)" > "$out/appsupport-ls.txt"
  plutil -p "$(data)/Library/Preferences/$BID.plist" 2>/dev/null | grep -i launchNote > "$out/launch-note.txt"
  q "$out" "SELECT 'catalog', MAX(packageVersion) FROM classDef WHERE packageID = 'system';
            SELECT 'migrations', group_concat(identifier) FROM grdb_migrations;
            SELECT 'objects', COUNT(*) FROM object; SELECT 'links', COUNT(*) FROM link;
            SELECT 'ops', COUNT(*) FROM op; SELECT 'userOps', COUNT(*) FROM op WHERE actor != 'system';
            SELECT 'tessEyesField', COUNT(*) FROM fieldDef WHERE key = 'tessEyes';
            SELECT 'tessEyesSet', COUNT(*) FROM object o JOIN fieldDef f ON f.key = 'tessEyes'
              WHERE instr(upper(CAST(o.\"values\" AS TEXT)), upper(f.id)) > 0;
            SELECT 'drill', title FROM object WHERE title LIKE 'drill%' ORDER BY title;" > "$out/summary.txt"
  for t in object link op; do
    sqlite3 "file:$out/tessera.sqlite?mode=ro" -cmd ".mode quote" "SELECT * FROM \"$t\" ORDER BY id;" | sort > "$out/$t.txt"
  done
  cat "$out/summary.txt"
}
kept() { comm -23 "$EV/$1/$3.txt" "$EV/$2/$3.txt"; }   # rows in $1 missing or changed in $2; empty is good
```

If `sqlite3` says "unable to open database file" on a copy, run `sqlite3 "$EV/<label>/tessera.sqlite" "PRAGMA
wal_checkpoint(TRUNCATE)"` on that evidence copy only (never on the Simulator's live file), then query again.

| # | Do | Expect | Evidence | Result |
|---|---|---|---|---|
| R0.1 | Run the V0-10 block. | a36b161 is an ancestor of `$V10`; the #403 and #407 merges are listed; `version: 10` with `nonisolated`; `isNewer` found in `$V10`; `0` for 7b321d2. | Paste the output into `$EV/R0-v0.txt`. | [ ] P [ ] F |
| R0.2 | `scripts/test.sh` in `$DRILL/src-<v10 short>`. | Ends "All green". | Last 20 lines in `$EV/R0-tests.txt`. | [ ] P [ ] F |
| R0.3 | Build all three, create and boot "Drill v10". | Three `Tessera.app` bundles; one new Simulator UDID. No phone is a destination anywhere. | `echo $UDID > $EV/R0-udid.txt`; `xcrun simctl list devices \| grep Drill >> $EV/R0-udid.txt`. | [ ] P [ ] F |

Any F in R0 stops the drill. Nothing installs.

## R1. The pin with his shape of data, then SAVE A COPY (Step 0)

```bash
xcrun simctl install "$UDID" "$APP_PIN"
launch -resetDemo          # the only -resetDemo in the drill
```

In the app, give it his shape (each one makes an op that isn't `system`, so daily copies run; demo history alone is
written by `system` and would skip them):
1. Ask Tess: `wifi password is tacocat`. Expect "Private note, kept."
2. Ask Tess: `182.4 lb this morning`. The body weight ghost; leave it (no UNDO).
3. Ask Tess: `bench 100 x 5`. A set today that beats the demo's bench best.
4. Ask Tess: `drill r1 task saturday`. A task.
5. Notes, the writing line: `drill r1 note`.

```bash
background; sleep 3; launch          # the pin writes today's daily copy on this background
shot R1-home
snap R1
```

Then Step 0, exactly as on the phone: Review > The week > Backups (at the foot) > **Save a copy**. In the save sheet
choose **On My iPhone** (not the Tessera folder), rename it `step0-v9-a36b161`, Save.

```bash
shot R1-saved
STEP0=$(find ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Shared/AppGroup \
  -path "*File Provider Storage*" -name "step0-v9-a36b161.tessera" | head -1)
echo "$STEP0" > "$EV/R1-step0-path.txt"; shasum -a 256 "$STEP0" > "$EV/R1-step0.sha256"
mkdir -p "$EV/R1-step0" && cp "$STEP0" "$EV/R1-step0/tessera.sqlite"
q "$EV/R1-step0" "SELECT MAX(packageVersion) FROM classDef WHERE packageID = 'system'; SELECT format, version FROM backupInfo;"
```

| # | Do | Expect | Evidence | Result |
|---|---|---|---|---|
| R1.1 | Install the pin, launch with `-resetDemo`, add the five things. | Each line as above. Home draws the demo day. | `R1-home.png` | [ ] P [ ] F |
| R1.2 | `snap R1`. | `catalog 9`, `migrations v1,v2,v3`, `userOps` 5 or more, `tessEyesField 0`, two `drill` rows. No launch note. | `$EV/R1/` (summary, checksums, table dumps) | [ ] P [ ] F |
| R1.3 | Read `$EV/R1/backups-ls.txt`. | One `Tessera-<today>.tessera`. This is the control for R3: the pin does write daily copies from its own store. | `backups-ls.txt` | [ ] P [ ] F |
| R1.4 | Save a copy to On My iPhone as `step0-v9-a36b161`. | "Saved." on Backups. The file is found; its catalog is 9; `backupInfo` reads `tessera-backup`, `1`. | `R1-saved.png`, `R1-step0-path.txt`, `R1-step0.sha256` | [ ] P [ ] F |

Write down the R1 counts: objects, links, ops. They are the "v9 rows" for R2, R4 and R5.

## R2. Install v10 over the pin (gate U1)

```bash
xcrun simctl install "$UDID" "$APP_V10"     # in place: never uninstall
launch
shot R2-home
```

In the app: open Notes and the Day log; check the five R1 things are there and the private note reads "Private note".
Then add the v10 work that R5 will lose: Ask Tess `drill v10 task sunday`, and Notes `drill v10 note`. Then Review >
The week > Backups > **Save a copy** to On My iPhone as `drill-v10-copy` (R3 and R4 use it).

```bash
shot R2-notes
snap R2
for t in object link op; do echo "== $t"; kept R1 R2 $t; done > "$EV/R2-kept.txt"; cat "$EV/R2-kept.txt"
V10COPY=$(find ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Shared/AppGroup \
  -path "*File Provider Storage*" -name "drill-v10-copy.tessera" | head -1)
echo "$V10COPY" > "$EV/R2-v10copy-path.txt"; shasum -a 256 "$V10COPY" > "$EV/R2-v10copy.sha256"
```

| # | Do | Expect | Evidence | Result |
|---|---|---|---|---|
| R2.1 | Install v10 over the pin, launch. | Clean launch, no crash, no launch note. Home draws. | `R2-home.png`, `$EV/R2/launch-note.txt` empty | [ ] P [ ] F |
| R2.2 | Read `$EV/R2/summary.txt`. | `catalog 10`. `migrations v1,v2,v3` (no new GRDB migration). `tessEyesField 1`, `tessEyesSet 0`: the field is there and empty, so eyes are off. Four `drill` rows. | `$EV/R2/summary.txt` | [ ] P [ ] F |
| R2.3 | Read `$EV/R2-kept.txt`. | Empty under all three tables: every R1 row is in R2, byte for byte. Any line stops the drill until Builder A explains it (as V2 did). | `R2-kept.txt` | [ ] P [ ] F |
| R2.4 | Look at the soul on Home and in a live workout's corner. | No eyes anywhere (E1). | `R2-home.png` | [ ] P [ ] F |
| R2.5 | Notes and Day log. | Private note reads "Private note"; body weight, the bench set and the R1 note and task are there. | `R2-notes.png` | [ ] P [ ] F |
| R2.6 | Save the v10 copy. | "Saved."; the file is found. | `R2-v10copy-path.txt`, `.sha256` | [ ] P [ ] F |

## R3. Roll back to the pin over v10 (gates U3 and U4, M1)

```bash
snap R3-before                                   # app stopped; checksum of the v10 store as it stands
mkdir -p "$EV/R3-backups-parked"
mv "$(data)/Documents/Backups/"* "$EV/R3-backups-parked/"   # empty the folder so any new copy shows
ls -la "$(data)/Documents/Backups" > "$EV/R3-backups-empty.txt"
xcrun simctl install "$UDID" "$APP_PIN"
launch
shot R3-launch-note
```

In the app: read the line beside the soul (do not open the Ask bar yet; opening it clears the note). Then Notes and
Home: his data isn't shown. Ask Tess `drill rollback task`, which goes into memory only.

```bash
shot R3-in-memory
background; sleep 3; launch; background; sleep 3; launch
ls -la "$(data)/Documents/Backups" > "$EV/R3-backups-after.txt"
```

Then the U4 check: Review > The week > Backups > **Restore**, On My iPhone, pick `drill-v10-copy`.

```bash
shot R3-v10-refused
ls -la "$(store)" > "$EV/R3-no-pending.txt"       # no restore-pending.sqlite
snap R3-after
diff "$EV/R3-before/store.sha256" "$EV/R3-after/store.sha256" && echo "store untouched"
mv "$EV/R3-backups-parked/"* "$(data)/Documents/Backups/"   # put his copies back
```

| # | Do | Expect | Evidence | Result |
|---|---|---|---|---|
| R3.1 | Install the pin over the v10 store, launch. | Beside the soul: "Your data is from a newer Tessera, so I left it untouched. Update the app to open it. Nothing you do this time will be kept." (`TesseraSchema.swift:54-55`). No crash. | `R3-launch-note.png`; `$EV/R3-after/launch-note.txt` holds the same words | [ ] P [ ] F |
| R3.2 | Look at Notes, Home and the Day log. | None of the R1 or R2 things. The app runs, empty, in memory. | `R3-in-memory.png` | [ ] P [ ] F |
| R3.3 | Ask Tess `drill rollback task`, background twice. | Documents/Backups stays empty: no `Tessera-<today>.tessera`, nothing new (M1, `TesseraBackup.swift:125`). R1.3 showed the pin does write one from a real store, so empty here is M1 at work. | `R3-backups-empty.txt`, `R3-backups-after.txt` | [ ] P [ ] F |
| R3.4 | Restore `drill-v10-copy` on the pin. | "That copy is from a newer Tessera. Update first." Nothing staged: no `restore-pending.sqlite` in the store folder (`TesseraBackup.swift:214`, `BackupView.swift:256-257`). | `R3-v10-refused.png`, `R3-no-pending.txt` | [ ] P [ ] F |
| R3.5 | Compare checksums. | `store.sha256` identical before and after for `tessera.sqlite` and `tessera.sqlite-wal`. A changed `-shm` alone is noted, not a fail (it is SQLite's index, not data). `summary.txt` for R3-before and R3-after match line for line; `drill rollback task` is in neither. | `R3-before/`, `R3-after/`, the `diff` output | [ ] P [ ] F |

## R4. Roll forward to v10 again (U3's way back, and gate U2)

```bash
xcrun simctl install "$UDID" "$APP_V10"
launch
shot R4-home
snap R4
for t in object link op; do echo "== $t"; kept R2 R4 $t; done > "$EV/R4-kept.txt"; cat "$EV/R4-kept.txt"
```

Then U2, two restores on v10, each applied by closing Tessera from the app switcher and opening it again
(`launch` after `xcrun simctl terminate "$UDID" "$BID"`):
1. Backups > Restore > On My iPhone > `step0-v9-a36b161`, hold **Replace**, relaunch. `shot R4-u2-step0`, `snap R4-u2-step0`.
2. Backups > Restore > On My iPhone > Tessera > Backups > the newest `Before-restore-<time>` (the v10 store that
   restore just kept), hold **Replace**, relaunch. `shot R4-u2-undo`, `snap R4-u2-undo`.

```bash
for t in object link op; do echo "== $t"; kept R1 R4-u2-step0 $t; kept R4 R4-u2-undo $t; done > "$EV/R4-u2-kept.txt"
```

| # | Do | Expect | Evidence | Result |
|---|---|---|---|---|
| R4.1 | Install v10 over the pin, launch. | No launch note. Home, Notes and the Day log show R1 and R2's things. `drill rollback task` is not there. | `R4-home.png`, `$EV/R4/launch-note.txt` empty | [ ] P [ ] F |
| R4.2 | Read `$EV/R4/summary.txt` and `R4-kept.txt`. | Same catalog, counts and four `drill` rows as R2. `R4-kept.txt` empty: R3 changed nothing. | `$EV/R4/`, `R4-kept.txt` | [ ] P [ ] F |
| R4.3 | U2 part 1: restore the Step 0 v9 copy on v10. | "Restored from your backup. What was here before is kept in Backups, so you can restore it again." Two `drill r1` rows, no `drill v10` rows; `catalog 10` after the launch; `tessEyesSet 0` (a pre-v10 copy reads eyes as no, S13). `kept R1 R4-u2-step0` empty. | `R4-u2-step0.png`, `$EV/R4-u2-step0/` | [ ] P [ ] F |
| R4.4 | U2 part 2: restore the Before-restore copy v10 just kept. | The four `drill` rows are back; `tessEyesSet` as in R4 (0, since nothing can set it yet). `kept R4 R4-u2-undo` empty. The v10 copy round-trips. | `R4-u2-undo.png`, `R4-u2-kept.txt` | [ ] P [ ] F |

## R5. The last resort: the Step 0 copy on the pin

His call only, never the default: rolling forward (R4) loses nothing. This shows what it costs.

```bash
snap R5-v10-before
xcrun simctl install "$UDID" "$APP_PIN"
launch                                   # the launch note again, in memory
```

Backups > Restore > On My iPhone > `step0-v9-a36b161`, hold **Replace**, then relaunch:

```bash
xcrun simctl terminate "$UDID" "$BID"; launch
shot R5-restored
snap R5
for t in object link op; do echo "== $t"; kept R1 R5 $t; done > "$EV/R5-kept.txt"
ls -la "$(data)/Documents/Backups" > "$EV/R5-backups.txt"
ls -laR "$(store)/Backups" > "$EV/R5-moved-aside.txt"
```

Then prove the v10 work is kept, not gone: roll forward and restore the Before-restore copy the pin just made.

```bash
xcrun simctl install "$UDID" "$APP_V10"; launch
# Backups > Restore > On My iPhone > Tessera > Backups > newest Before-restore-<time>, hold Replace
xcrun simctl terminate "$UDID" "$BID"; launch
shot R5-v10-back
snap R5-v10-back
for t in object link op; do echo "== $t"; kept R5-v10-before R5-v10-back $t; done > "$EV/R5-v10-back-kept.txt"
```

| # | Do | Expect | Evidence | Result |
|---|---|---|---|---|
| R5.1 | On the pin, restore the Step 0 copy. | Picking it is allowed (catalog 9). After the relaunch: "Restored from your backup. What was here before is kept in Backups, so you can restore it again." No newer-store note. | `R5-restored.png` | [ ] P [ ] F |
| R5.2 | Read `$EV/R5/summary.txt` and `R5-kept.txt`. | `catalog 9`, the two `drill r1` rows, no `drill v10` rows, `tessEyesField 0`. `R5-kept.txt` empty: the store is R1's again. | `$EV/R5/` | [ ] P [ ] F |
| R5.3 | Read `R5-backups.txt` and `R5-moved-aside.txt`. | A new `Before-restore-<time>.tessera` in Documents/Backups (a v10 copy, `TesseraBackup.swift:293-296`), and the v10 store's raw files in `Application Support/Tessera/Backups/<date>/` (`TesseraSchema.swift:129-151`). | both files | [ ] P [ ] F |
| R5.4 | Background once on the pin. | Today's `Tessera-<today>.tessera` is rewritten with a newer time, because a restore came after it (`TesseraBackup.swift:145-147`): the pin copies from a real store again, catalog 9. | `ls -la` of Documents/Backups into `$EV/R5-daily.txt`, compared with `R5-backups.txt` | [ ] P [ ] F |
| R5.5 | Roll forward to v10 and restore that Before-restore copy. | All four `drill` rows are back; `R5-v10-back-kept.txt` empty. | `R5-v10-back.png`, `$EV/R5-v10-back/` | [ ] P [ ] F |

**What R5 costs.** Everything done on v10 after Step 0 (here the two `drill v10` rows; on the phone, every set, note,
task and setting since the v10 install) is not in the restored store. It isn't destroyed: the pin keeps it as a
Before-restore copy that only a v10 build can open (R5.5), and Before-restore copies are pruned to the newest 3
(`TesseraBackup.swift:41`). Anything done during an in-memory rollback session (R3) is lost for good.

## R6. Prove 7b321d2 must never be used (Simulator only, destroys that Simulator)

**Simulator only. Destructive to the throwaway Simulator it runs on. Never on the phone, never on "Drill v10",
never on the dev iPhone 17.**

```bash
export UDID=$(xcrun simctl create "Drill 7b3 throwaway" "iPhone 17" "$RUNTIME")
echo "$UDID" > "$EV/R6-udid.txt"
xcrun simctl boot "$UDID"
xcrun simctl install "$UDID" "$APP_V10"
launch -resetDemo
```

On v10: Ask Tess `wifi password is tacocat` ("Private note, kept."), `drill v10 before old`, and background once so
v10 writes its daily copy.

```bash
snap R6-v10
mkdir -p "$EV/R6-backups-parked" && mv "$(data)/Documents/Backups/"* "$EV/R6-backups-parked/"
cp "$EV/R6-backups-parked/"Tessera-*.tessera "$EV/R6-v10-daily.tessera"
xcrun simctl install "$UDID" "$APP_OLD"
launch
shot R6-old-launch
```

On 7b321d2: open Notes and the Day log (screenshot each), then Ask Tess `drill old wrote this`, background twice.
For R6.5, put v10's daily copy where the Files picker sees it (On My iPhone > Tessera), then Backups > Restore >
On My iPhone > Tessera > `r6-v10-copy`, and stop at the "Replace everything" question (don't hold Replace):
`cp "$EV/R6-v10-daily.tessera" "$(data)/Documents/r6-v10-copy.tessera"`.

```bash
shot R6-old-notes
background; sleep 3; launch; background; sleep 3
snap R6-old
diff "$EV/R6-v10/store.sha256" "$EV/R6-old/store.sha256"
ls -la "$(data)/Documents/Backups" > "$EV/R6-old-backups.txt"
for f in "$(data)/Documents/Backups/"Tessera-*.tessera; do
  mkdir -p "$EV/R6-old-copy" && cp "$f" "$EV/R6-old-copy/tessera.sqlite"
  q "$EV/R6-old-copy" "SELECT MAX(packageVersion) FROM classDef WHERE packageID = 'system';"
done
```

| # | Do | Expect (from reading 7b321d2) | Evidence | Result |
|---|---|---|---|---|
| R6.1 | Install 7b321d2 over the v10 store, launch. | Opens it with **no** launch note: it has no newer-store check and knows all three GRDB migrations, so nothing stops it. | `R6-old-launch.png`, `$EV/R6-old/launch-note.txt` | [ ] recorded |
| R6.2 | Notes and the Day log. | 7b321d2 is before #422, so it doesn't know private notes: expect "wifi password is tacocat" in plain text on the Notes list and in the Day log. | `R6-old-notes.png` | [ ] recorded |
| R6.3 | Ask Tess `drill old wrote this`. | The row lands in the v10 file: `drill old wrote this` in `$EV/R6-old/summary.txt`, checksum changed, `catalog` still 10 (it never refreshes a newer class, `SystemCatalog.swift:354` at 7b321d2). It writes into a store it doesn't understand. | `R6-old/summary.txt`, the `diff` output | [ ] recorded |
| R6.4 | Background twice. | A new `Tessera-<today>.tessera`, made by 7b321d2 from the v10 store (no M1 at 7b321d2). | `R6-old-backups.txt`, the copy's catalog query | [ ] recorded |
| R6.5 | Pick `r6-v10-copy` in Restore on 7b321d2. | Accepted: "Replace everything with the copy from ...?" shows, where the pin says "That copy is from a newer Tessera. Update first." (its check is migrations only, `TesseraBackup.swift:211` at 7b321d2). | `shot R6-old-restore` | [ ] recorded |
| R6.6 | Delete the Simulator. | `xcrun simctl shutdown "$UDID" && xcrun simctl delete "$UDID"`; it is gone from `xcrun simctl list devices`. | `$EV/R6-deleted.txt` | [ ] P [ ] F |

R6 passes when every row is recorded. Each "recorded" that matches its Expect is one more reason 7b321d2 never goes
on after v10. If 7b321d2 refuses the store, or shows "Private note", that changes the rollback story: stop and tell
Research and Product before the v10 install.

Afterwards, `git worktree remove` the three `src-*` folders; keep `$EV`. Shut down "Drill v10" or delete it once QA
has read the evidence.

## Report back

- `$V10` (full SHA) and R0.1's output.
- Pass or fail for R1 to R5 by row; R6 as recorded, word for word where it differs from Expect.
- The R1 counts (objects, links, ops) and any non-empty `kept` file, with Builder A's explanation.
- The R3 launch note word for word, and the two `store.sha256` files.
- Zip `$EV` and attach it to the QA thread.

## Time, owner and gate rows

**Time budget.** About 2 hours with warm builds: R0 40 min (three builds, the tests, the Simulator), R1 15 min,
R2 15 min, R3 15 min, R4 15 min, R5 15 min, R6 10 min, report 5 min. Add 30 min if DerivedData is cold. Run it in one
sitting on one calendar day (before midnight): the daily copy names and R1.3's control depend on the day staying the
same.

**Who runs it.** Builder A owns every install, here as on the phone. QA reads `$EV` and ticks the rows. Research
answers questions about the Expect column. Product reads the result before it says the v10 build may go on.

**Gate rows it satisfies** (`next-build-v10.md` section 4):

| Gate row | Drill rows |
|---|---|
| U1: v10 over a36b161's v9 store; clean launch; all rows identical; `tessEyes` empty; no launch note | R2.1 to R2.5 |
| U2: back up on v10 and restore it on v10; a pre-v10 copy reads `tessEyes` as no | R4.3, R4.4 |
| U3: a36b161 over the v10 store; launch note; checksum unchanged; no new copy (M1) | R3.1 to R3.3, R3.5, with R4.1 and R4.2 as the way back |
| U4: on a36b161, restore a v10 copy; refused, nothing restored | R3.4 |

It also stands behind pin-checklist section 7's "After v10" line (R5 for the Step 0 copy, R6 for 7b321d2), and
replaces the retired V4 with evidence instead of a rule.

## What this reading changes in the rollback story

1. **The Step 0 copy must be saved outside Tessera's own Backups folder.** Save a copy offers the name
   `Tessera-<date>` (`BackupKeeper.swift:164-172`), the same pattern as the daily copies. If he saves it into On My
   iPhone > Tessera > Backups, it joins the rolling seven (`TesseraBackup.swift:133`, `:170-172`): v10 can replace it
   between midnight and 4 am that night and prunes it after a week. The phone's Step 0 should say: save to iCloud
   Drive (or anywhere but Tessera's Backups) and rename it.
2. **R5 loses less than "everything since".** Restoring the Step 0 copy on a36b161 first keeps the v10 store as a
   Before-restore copy and moves its files aside (`TesseraBackup.swift:285-311`). A later v10 build can restore that
   copy. Only work done during an in-memory rollback session is gone for good. The Before-restore copies are capped
   at 3, so repeated restores push it out.
3. **`core/tess-eyes`'s head is not a v10 build to test.** It predates #475 and #498. B5 in the v9 script only uses
   it to make a v10 store; U1 to U4 must run on the named `$V10`.
4. **Demo data alone doesn't exercise the daily copy.** The demo's ops are by `system`, and `writeRolling` skips a
   store with no other ops (`TesseraBackup.swift:141-142`). Without R1's five real actions, R3's "no new copy" would
   pass even without M1.
5. **7b321d2 would show private notes in plain text** (it is before #422), on top of writing to the v10 store. That
   makes it a privacy rollback hazard as well as a data one.
