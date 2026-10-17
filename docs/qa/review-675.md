# Review #675 (Ops: locked-screen guard in lane_lock.sh)

Head 8622fb8d, merge-tree clean against master a479f606. Script and docs only (2 files). Design not needed.

**Verdict: QA PASS.** Static read; the detection itself is only tested with the forced override, see the first low.

## Your questions
- **Heartbeat, release and stale rules (#657) are untouched.** The locked wait happens before `wait`, so nothing is queued and no lock is held while it polls. After a hold is taken, the heartbeat subshell is still started after the loop, with the same `beat` calls. `acquire`'s stale rules (dead pid, 2 h, 10 min without a beat, legacy 45 min) are not edited. The hand-back calls the existing `release <lane>`, which matches the lane that `wait` just acquired (`LOCK_PID=$PPID` is the run shell), so it frees exactly that hold.
- **A failed ioreg read never blocks.** `screen_locked` returns 1 (unlocked) for non-Darwin, a missing or failing ioreg (empty pipe, `grep -q` fails), a failing python fallback, and any unreadable state. The calls sit in `while`/`||` contexts, so `set -e` cannot abort on them.
- `LANE_LOCK_SCREEN_OK=1` is checked first and skips everything. The locked wait logs once a minute to the lock log and the terminal, and exits 1 after an hour; the limit is set once at the start of `run`.

## Lows
1. The ioreg parse (`grep -A1 -E 'CGSSessionScreenIsLocked|IOConsoleLocked' | grep -q '<true/>'`) has not been run against real output. Fail-open means the worst case is the old behaviour, but do one real check on the Mac: lock the screen, run `lane_lock.sh run test x -- true`, expect "screen locked, waiting"; unlock and expect it to proceed.
2. The `/usr/bin/python3 -c 'import Quartz'` fallback adds little (system python has no Quartz) and, on a Mac without the command-line tools, can raise the "install developer tools" dialog on every check. Drop it, or guard it with `xcode-select -p`.
3. A hand-back re-queues at the back of the FIFO, so that run loses its place. Acceptable; say so in the docs.
4. `LANE_LOCK_SCREEN=unlocked` is a second bypass beside `_OK=1`; fine, as the docs call it a test hook.

## Follow-up #677 at 43ef7ce9: PASS
Own change is two small edits on top of #675: the python Quartz line is removed (`screen_locked` now ends `ioreg ... && return 0` then `return 1`, so unknown still counts as unlocked) and the hand-back order is noted in the script (a comment before the give-back line) and the doc. `sh -n` on the script parses clean. Closes lows 2 and 3.
