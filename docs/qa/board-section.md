## QA (Repo maintainer)

*No simulator or Swift toolchain in this thread, so QA here is code review on master, not running the app.*

**Now:** review each new merge as it lands. Next up: Core's second hotfix (H1–H5, K2/K6 remainders, N1–N4, G2) and iOS build's G1 fix.

**Next:**
1. Keep the docs index at `docs/README.md` current.
2. Review merges from before #40 that no one has checked yet, oldest risk first: storage (GRDB), the op log and undo, and export.

**Done:** #46 to #58 reviewed (#64), grammar traced (#67), hotfix #70 checked and #40 to #45 reviewed (#77), and the gym, kitchen and regression checks written for the Mac leads (#63).

**Later:**
- Performance budget checks (launch time, dial at 120 fps). These need a Mac lead to run them.
