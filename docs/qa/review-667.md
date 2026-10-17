# Review #667 (Core: fixed noon in ReceiptTests.aMovedTaskSaysWhen)

Head 61458732. Test-only, one file, 3 lines added and 1 removed. Static review. Design not needed.

**Verdict: QA PASS.** `now` is a fixed Oct 15 2026 at noon, passed as the move's `time:`, so "tomorrow" is the next calendar day at any hour of the real clock. The 12-day case follows from `tomorrow`. No DST change falls in the window (US change is Nov 1). The comment explains the 4 am day turn. No production code touched.
