# Review #225: v3 zone column on op (3c9278a, head e1a2826)

Core. 6 files, +121/-6. Static review (no Swift toolchain here).

**Verdict: PASS.** The migration can't drop data, and old backups and old exports still restore. One should-fix (Z1, cheap, matters for the 26 Oct trip), one test gap, one rollback note.

## The migration never drops data
- "v3" is a single `ALTER TABLE op ADD COLUMN zone TEXT`: nullable, no default, no table rebuild, no copy. SQLite adds the column in place; every existing row keeps all its values and reads NULL for `zone`.
- It's registered after v1 and v2, so GRDB runs it once, inside its own transaction. A failure rolls back to v2 untouched.
- Writes: the op INSERT OR REPLACE now lists 12 columns and 12 values, with `r.zone` last. Reads: `record.zone = row["zone"]`, which is nil for old rows. Tested (`oldRowsStayNull`, `theZoneSurvivesSaveAndReload`).

## Old backups and exports still import
- **.tessera backup (SQLite copy) from v2:** `TesseraBackup.inspect` only refuses migrations this build doesn't know (`isSubset(of: known)`, TesseraBackup.swift:181). ["v1","v2"] is a subset, so it's accepted. On restore the file is opened by `TesseraContext`, whose migrator adds v3, so old rows come back with zone NULL.
- **JSON export without `zone`:** `OpEntry.zone` is optional, so Codable's synthesized decoding treats a missing key as nil. Import sets `record.zone = entry.zone` (nil). Tested (`anOlderExportWithoutZonesStillDecodes`), and the `format` number didn't change, so old exports pass the format check.
- **New export:** zone written per op and restored on import. Tested.

## Should-fix
- **Z1 (TimeZone.current is cached):** the default stamp is `{ TimeZone.current }` (ActionEngine.swift:37). Foundation caches the system zone for `TimeZone.current`. Apple's guidance is to use `TimeZone.autoupdatingCurrent` to follow a change while the app is running. On the trip, if Tessera stays alive in the background across the flight, sets logged after landing could be stamped America/Los_Angeles until the next relaunch, which defeats the column's purpose.
  - Fix: `{ TimeZone.autoupdatingCurrent }` (its `identifier` reflects the zone now). One line.
  - Phone check (resign-day or the trip): Settings > General > Date & Time, set a zone manually with the app in the background, log a note, then check the op's zone in an export.

## Test gap
- **Z2:** `oldRowsStayNull` inserts an old-style row into a database that's already at v3. Nothing opens a real v2 file. Add one: build a DB with `migrator.migrate(db, upTo: "v2")`, insert an op, close, reopen through `TesseraContext`, and assert the row and its values are intact and `zone` is nil. That's the test that proves "never drops data" on his actual phone database.

## Rollback note (for resign-day.md)
- After this build runs once, the phone's database is at v3. If he's ever rolled back to an older build (fallback b19fb4a/d0154a9):
  - The old build opens the database fine. It doesn't know the zone column and rewrites ops without it, so zones on ops it rewrites go back to NULL. No other loss.
  - Its daily copies record migrations v1, v2, v3, so that old build's own restore refuses them as "made by a newer build". The newer build restores them fine.
  - So a rollback is safe for data; just don't restore with the old build.

## Addendum: #236 (9d4cb4f), Z1 and Z2 closed
- **Z1 closed:** the default stamp is now `{ TimeZone.autoupdatingCurrent }` (ActionEngine.swift:38); its `identifier` follows the device after a flight without a relaunch. `theDefaultZoneFollowsTheDevice` only checks the default is the autoupdating zone (a test can't change the system zone), so the phone check above still stands for the trip.
- **Z2 closed:** `aRealV2FileOpensAtV3` builds a real file with `migrate(upTo: "v2")`, inserts a v2 op (with route), closes, then opens through `ObjectStore`. It asserts v1/v2/v3 applied, the old row kept with its route and a NULL zone, and a new action stamped and saved next to it. That's the phone database's upgrade path.
- Two files, +38/-2, nothing else touched. PASS.
