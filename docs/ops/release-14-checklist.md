# Release 14 pin checklist (Ops, ready to fill when the Mac unlocks)

Written 6:45 PM PT Oct 17 from pin-release.md and pin-release-product.md. Release 14 is HELD and not named. Fill the blanks in order; do not name a SHA until the trigger below is true.

## Trigger (any one)
- The Mac-run app PRs have merged (the eight waiting on test.sh: #564, #868, #871, #884, #885, #889, #890, #895; #886 once Core's fix is re-pinned and re-verdicted), or
- 30 minutes after the Mac unlocks, with whatever has merged by then.
Docs and scripts/ai merges never trigger a release.

## Fill-in
- Release SHA: master at the last merge in the batch = `________` (full 40 characters, from GitHub, not typed from memory).
- Installed on the phone now: `bbadf141` if release 13 went in, else `e149e66` (release 8). Ask Builder A which; do not guess.
- Step 0 name, exactly: `Before <SHA> (from bbadf141 or e149e66, whichever is installed) <time>` with the real SHA and the real installed SHA filled in, time from a fresh date run in PT. It sits outside Backups, never overwrites, renames or deletes an existing copy.
- Release 13 and 14 may go as one install if 13 never went in: then the installer is re-armed on the release 14 SHA only (13's loop stopped).

## Gates (all must be yes, recorded at the exact head)
1. Every app PR in the batch has a QA PASS at its exact full head SHA (qa.md PIN READINESS line), plus Design PASS for UI changes.
2. No Catalog or migration change; Catalog stays v9 (v10 is #407 and waits for every rider).
3. test.sh ends "All green" on the release SHA itself (engine package and app).
4. Any walls change in the batch also passes its walls-ui spec rows.
5. Frozen-PR rule respected: no PR in the batch changed after its number was sent.
6. Nothing older than a36b161 is ever installed; only the named SHA, never master.
7. Phone on shared Wi-Fi (standing install approval, cmsg_01VTPva3JGXrfvetgUvAWE7MKtsr7xNNmpkp1H7oWKzSoD).

## After install
- Builder A reports installed SHA; the coordinator sends Product the SHA for the section 6 chain; the coordinator tells Kaushik it is on (promised in the 4:50 PM overview).
- Design's walk or clip runs after install and does not block. Walk items already owed (pin-walk-next): the #662 Home stroke, #786 and #806 Lists swipes vs side swipe, plus the new PRs' own rows. A FIX FIRST becomes a roll-forward fix.

## Rollback (Product 3:03)
Roll forward first; then the previous release, but only if no privacy fix landed between the two; then restore the Step 0 copy.

## Other
- Signing lapse Fri Oct 23 2:12 PM PT: a build installed after Oct 22 needs a fresh profile.
- Records go to pin-release-log-2.md style notes; keep pin-release.md under 3000 bytes.
