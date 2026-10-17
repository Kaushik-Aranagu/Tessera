# Lane lock for the shared Mac

Several lanes share one Mac, one iOS simulator and one Xcode. Two concurrent `xcodebuild` runs on the same DerivedData, or two lanes driving the same simulator, corrupt each other. A lane takes the lock before any simulator use or Xcode build and releases it after.

## Convention

- **Lock**: the directory `/tmp/tessera-mac-lock.d` on the Mac (`mkdir` is atomic, so only one lane wins). There is no override. A stale or foreign directory is removed with `rm -f info; rmdir`, so a directory holding any other file is left alone and the helper stops with an error.
- **Queue**: the directory `/tmp/tessera-mac-lock.q` holds one ticket file per waiting lane (`<epoch>-<lane>`, containing the waiter's pid), used only by `wait`.
- **Content** (file `info` inside it, `key=value` lines): `lane` (lane name), `pid` (the holder's long-lived shell pid), `start` (epoch seconds), `start_iso` (UTC), `purpose` (short text, e.g. `app tests for PR 312`).
- **Abandoned holds free themselves.** A hold is stale when its pid is dead, it is older than 2 hours (7200 s), or it has had **no heartbeat for 10 minutes**. The heartbeat is the epoch in `/tmp/tessera-mac-lock.d/beat`, written at acquire and by `beat`. The next `acquire`, `wait` or `run` frees a stale hold, prints the reason and appends it to `/tmp/tessera-mac-lock.log`. A live shell that sits on the lock without beating is freed too. A hold made by the old script has no `beat` file and never beats, so it is freed only when its pid is dead or after 45 minutes (2700 s), never by the 10-minute rule. A stale lock may be taken over by the next lane; the helper says so when it does.
- **Package-only runs** (`swift test` in `TesseraCore/`, no simulator, no Xcode) do not need the lock.
- **Never `pkill`/`killall` by pattern** (xcodebuild, Simulator, Xcode, swift). That kills other lanes' work. Kill only a pid you started and recorded yourself. If the lock holder looks hung, ask that lane or the coordinator; do not kill it.
- Always release in the same shell that acquired (`trap '...lane_lock.sh release <lane>' EXIT`). Release only works for the lane named in the lock.

## Helper

`scripts/ops/lane_lock.sh`, POSIX sh:

```sh
scripts/ops/lane_lock.sh acquire <lane> "<purpose>"   # exit 0 acquired, 1 busy
scripts/ops/lane_lock.sh wait <lane> "<purpose>" [max_s]  # queue in order, take the lock when it is your turn (default 1800 s), exit 1 on timeout
scripts/ops/lane_lock.sh beat <lane>                  # heartbeat; a manual hold must beat at least every 10 minutes
scripts/ops/lane_lock.sh run <lane> "<purpose>" -- cmd...   # wait in line, hold while cmd runs (beats every 60 s), always release, return cmd's exit code
scripts/ops/lane_lock.sh release <lane>               # exit 1 if not held by that lane
scripts/ops/lane_lock.sh status                       # prints the holder, age_s and beat_age_s, or "free"
```

Typical use:

```sh
scripts/ops/lane_lock.sh acquire ios-a "app tests" || exit 1
trap 'scripts/ops/lane_lock.sh release ios-a' EXIT
scripts/test.sh --app-only
```

The recorded pid is the helper's parent (`$PPID`), so call the helper directly from the long-lived shell, not through a throwaway `sh -c`, or the lock looks dead immediately and is taken over.

## Waiting in line

Use `wait` instead of `acquire` when the lock is busy. Waiters queue first-come-first-served in `/tmp/tessera-mac-lock.q` (one ticket per waiter, holding its pid; a ticket whose shell has died is skipped). The next waiter takes the lock within 15 seconds of the holder's release, so the simulator hands off with no relay through the coordinator. The same shell rule applies: call `wait` from the long-lived shell, and release with the same trap.

## Who holds it

`status` and the busy message name the holder, how long it has held the lock and when it last beat. A waiting `wait` prints that line about once a minute. Prefer `run` for builds and tests: it beats for you and releases even when the command fails. A manual `acquire` needs `beat` at least every 10 minutes (a 60-second loop is plenty).

## Locked screen

When the Mac screen is locked, simulator UI runs stall (XCUITest waits 60 s for idle on every step, `simctl spawn` hangs) while still holding the lock and beating. So `run` checks first: while the screen is locked it prints and logs `screen locked, waiting (<lane>)` once a minute and does not queue or start (it gives up after an hour). If the screen locks while it is queued, it hands the lock back and waits again. Detection uses `ioreg` (the console user's `CGSSessionScreenIsLocked`, then `Quartz` if the system python has it); if it cannot tell, it counts as unlocked.

Package-only jobs (`swift test` in `TesseraCore/`) do not use the lock and run on a locked Mac. If one goes through `run` anyway, set `LANE_LOCK_SCREEN_OK=1` to skip the screen check. `LANE_LOCK_SCREEN=locked|unlocked` forces the answer for tests.
