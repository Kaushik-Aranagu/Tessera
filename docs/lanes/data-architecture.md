# Data and architecture lane: lessons

Scope: Core, the store, installs, gates, merges. The app reads the object graph through `ObjectStore`; Core owns every
number and sentence, and the UI never recomputes them.

- The release gate (Oct 22 5:14 PM PT): a device build plus the full package tests. The simulator app suite runs once
  every 12 hours on the newest release. Its runner often hangs ("hung before establishing connection"): that is the
  simulator, not a failing test; rerun it, do not bisect.
- The lane lock: `lane_lock.sh wait <lane> <purpose>` then `lane_lock.sh release <lane>`. It has no "run" command. Waiters
  queue first in, first out. Never write a fake "All green" line to satisfy an installer; check real evidence.
- Installs: `release-install.sh <sha7> <from7>` takes the Step 0 copy first and never overwrites an older copy. Never
  install while Tessera is open on the phone; when the phone is away, keep gating and install only the newest green release.
- Merges: never resolve a conflict inside a batch; merge the other side into the PR's own branch, resolve there, and have
  it re-pinned. The usual conflict is a facet line in `ReviewChoices`. Do not rebase a shared branch.
- Verify a branch at its own head: when the branch is checked out in another worktree, use `git checkout --detach origin/<branch>`
  or an archive; building the wrong tree gives a green that means nothing.
- Kill processes by PID, never by pattern. Clean up only rebuildable folders (old source archives and device builds); never Step 0
  copies, backups or the repo.
- Format.shown does not exist: use `Format.mass` for a stored kilogram value in the chosen unit. Core's `LogRow` has no
  workout id (ask Core before opening a row). `ObjectPrivacy.shownLabel` is the one privacy rule for any object.
