# QA (Repo maintainer)

*No simulator or Swift toolchain in this thread, so QA here is code review on master, not running the app.*

**Now:** release cut for Kaushik's phone at 19:45 UTC. Review every merge before it (#80 in progress, data-safety next), then read master as a release candidate and send the coordinator a go or no-go. Next up: Core's data-safety fix (D1–D3), Core's second hotfix (H1–H5, K2/K6 remainders, N1–N4, G2) and iOS build's G1 fix.

**Next:**
1. Keep the docs index at `docs/README.md` current.
2. Review the remaining older merges: Tess engine and App Intents, processes and What's running, HealthKit.

**Done:** #46 to #58 reviewed (#64), grammar traced (#67), hotfix #70 checked and #40 to #45 reviewed (#77), the gym, kitchen and regression checks written for the Mac leads (#63), and the data-safety review (D1–D4, merged as #79).

**Later:**
- Performance budget checks (launch time, dial at 120 fps). These need a Mac lead to run them.
