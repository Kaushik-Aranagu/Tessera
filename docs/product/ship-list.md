# Ship list: small slices, fastest feel first

*Product lead, 2026-10-15 16:00. Follows Kaushik's standing direction: velocity over perfection. He uses the app daily while it keeps changing. Each slice works end to end, ships alone, and is ordered by what he'll feel first in the gym and on Home. **Rough** means a first version is fine: plain but working, polished later. The premium UI bar still applies to whatever he sees most (live mode, Home); rough means fewer states and simpler motion, not stock-looking.*

**Already merged (per coordinator):** Home with What's running, the live workout, the lock-screen rest timer, the Tess engine, and speed, safety and export groundwork.

## Next up, in order

| # | Slice | Done when | Rough OK? |
|---|---|---|---|
| 1 | **Seed his real plan** | PPL×2 routines with real exercises, kg, 20 kg bar / 1.25 kg plates / 2 kg dumbbells are in the app on first launch | Yes: hard-coded seed is fine |
| 2 | **Prefilled one-hold logging** | Each set opens at last time's weight × reps (else the scheme's target); one hold logs it | Yes: "last time" only, no progression yet |
| 3 | **Dial and drum work for real** | Weight dial snaps to loadable values and shows plates per side; rep drum rolls | Dial must feel good; plate math can be plain text |
| 4 | **Finish and see it saved** | Finishing compresses the session into today's history on Home, with Tess's one-line summary | Yes: simple summary line |
| 5 | **Now counts down as a draining bar** | Now's countdown is a bar that drains in real time (the same drain as the rest dial), not just a number | Yes: plain bar, refine later |
| 6 | **Exercise page v0** | Tap an exercise: best set, best e1RM, last 5 sessions | Yes: no chart yet |
| 7 | **PR hint and moment** | "beats 5RM" hint before the set; one celebration when it happens | Hint can be text; celebration can wait for slice 13 |
| 8 | **Edit and undo any set** | Tap a logged set to change it; undo the last action | Yes |
| 9 | **Swap exercise in a session** | Pull down on the name, pick from the same movement pattern | Yes: simple list ranked by pattern only |
| 10 | **Routine editing** | Reorder, add, remove exercises and change sets × reps in a routine | Yes: plain editor |
| 11 | **Week view** | Days across, routine and done state; next routine rolls on after a missed day | Yes: no per-muscle sets yet |
| 12 | **Quick Capture "log bench 80x8"** | Typed in the Bar, shown as a ghost row, commits on tap or after 2 s | Yes: grammar only, no on-device model |
| 13 | **Polish pass on live mode** | Stamp seat, rest on the dial, PR light sweep, haptics, Reduce Motion | No: this is the premium moment |
| 14 | **Double progression** | Next session's target goes up when all sets hit the top of the range | Yes: one fixed rule (+2.5 kg BB, +2 kg DB) |
| 15 | **Weekly sets per muscle** | A strip of muscles with fractional sets vs 10–20 | Yes |
| 16 | **Month heatmap and counts** | "Session 6 of 14 this month", tap a day to open it | Yes |
| 17 | **Voice in the gym** | Hold the Bar: "same", "8", "80 for 7" | Yes: grammar first |
| 18 | **Rep maxes table, e1RM trend** | Exercise page gets the rep-max table and 90-day groove | Yes |
| 19 | **HealthKit write** | Finished workouts appear in Apple Health | Yes |

## Deferred (future-proofing only, not felt in daily use)

- **Storage engine bake-off.** Pick whichever works now and move on; migrate later if it hurts. Export (already merged) keeps data safe.
- **Capability manifests** per app and for Tess.
- **One syscall registry generating Tools, App Intents and Claude schemas.** Hand-write the few intents needed (lock-screen Done) for now.
- **Schema-as-data and package overlays** (needed only for M3 class editor).
- **On-device model routing and Private Cloud Compute tiers** for Tess. Grammar first; models when the grammar runs out.
- **Visible Tess memory (`Fact` objects), Time Machine, daemons.**
- **Full What's running beyond workouts** (tasks, waiting items), plate stack concept.
- **CloudKit sync.** One phone for now; export covers backup.

## Rules for build teams

- Ship each slice to his phone as soon as it works; don't batch.
- If a slice needs a decision, take the obvious default and note it; don't wait.
- Rough is fine for logic and secondary screens. Live mode and Home still meet the UI bar before he sees them, because those are what he lives in.
