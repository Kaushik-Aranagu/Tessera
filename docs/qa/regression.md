# Pre-merge regression checklist

Run this before merging anything to master. There's no CI, so this list and `scripts/test.sh` are the only gate. It takes about ten minutes on the simulator. If a row fails, don't merge: send the step and what you saw to the coordinator.

## Always

- [ ] `scripts/test.sh` passes, both the package and the app.
- [ ] You've merged the latest master into your branch and rerun the tests. Two PRs that each pass alone can break master together, as #46 and #47 did.
- [ ] The app launches on a fresh install (delete it first) and on an existing install, with no migration error.

## Undo

- [ ] Log a set, then undo. The set is gone.
- [ ] Add a grocery item, check it, then undo twice. The item is back and unchecked, then gone.
- [ ] Undo after relaunching. The last action before the relaunch still undoes.

## Export

- [ ] Export JSON. The file opens and has workouts, sets, recipes, lists and notes.
- [ ] Any new class or field from this PR is in the export.

## What's running

- [ ] Start a workout, then a shop. Both show in What's running, and Now picks the right one.
- [ ] Background the app for a minute and come back. Nothing is lost or duplicated, and timers kept their end times.
- [ ] Finish each process. Each one leaves What's running.

## Tess and the ghost row

- [ ] `bench 80x8` logs a set.
- [ ] `buy milk` adds milk to Groceries.
- [ ] `call mum friday` makes a Friday task.
- [ ] Any phrase this PR teaches Tess doesn't change what an older phrase does.

## Reduce Motion

- [ ] Turn on Reduce Motion (Settings > Accessibility > Motion). Every screen this PR touches still works, with no slides, sweeps or flares, and nothing waits on an animation to finish.

## If this PR touches live mode or the Lock Screen

- [ ] Run sections B, D and E of [gym-flow.md](gym-flow.md).

## If this PR touches the kitchen

- [ ] Run the sections of [kitchen-flow.md](kitchen-flow.md) for the screens that exist.
