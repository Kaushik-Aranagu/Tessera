# Review #718 at e446f30d (Ops, staleness skip)

Static. Merges clean. staleness.py adds `if "(merged #" in line: continue`; four board lines get "(merged #N)" (qa 0 and 2 and the Later gate-rows line, motion 15).
- Read-only: reads stdin and board files, prints. No exec, subprocess, network or write (PY_FORBIDDEN clean; no urllib).
- Marks are true: #342, #428, #451, #546, #576 are all on master.
- Skip cannot hide an open PR: only lines naming MERGED numbers are ever flagged, and a mark never changes that set.
- Low L1: the skip covers the whole line, so a marked line that also names a different merged PR stays hidden. Stricter: skip only when every hit is inside the "(merged ...)" list.
- The three QA board lines naming "pin" (Now, Next 3, Next 4) were stale; I cleared them on the board.

PASS.
