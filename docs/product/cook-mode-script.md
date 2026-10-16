# Cook mode: 10-minute phone script (slice 12)

*Kitchen lead, 2026-10-15. Run this on the phone, not the simulator, once Builder A's cook mode is installed. It's built from Research's `fixtures/cook-mode-scenarios.md`; the S-numbers say which fixture each step covers. Each step has one pass check, and a fail is anything else. You need a recipe with two timed steps: "Weeknight dal" from the seed recipes has 8 min and 20-25 min. Allow one notification when asked.*

| # | Do | Pass when | S |
|---|---|---|---|
| 1 | Open Weeknight dal and tap **Cook** | A dark full-screen page rises, showing step 1 large, its amounts under it and the screen not dimming. Home's Now reads "Weeknight dal" when you come back to it | S01 |
| 2 | Swipe up | Step 2 arrives and step 1 stays as a dim line above it | |
| 3 | Hold the cadmium **8 minutes** key | A line across the top starts burning down, labelled "Soften, 8 min" or similar. There's no button-shaped key or pill | S01 |
| 4 | Swipe to step 3 and hold its **20 minutes** key | Two stacked lines appear, the sooner one on top | S02 |
| 5 | Lock the phone | The Lock Screen shows Weeknight dal with the soonest timer and "+1" | S04 |
| 6 | Wait for the 8-minute timer with the phone locked | It flips to done on its own and a notification arrives once, "Soften is done", with no double alert | S04 |
| 7 | Tap the notification | Cook mode opens on this cook. The finished line flares and step 2 slides back in with a haptic. The current step doesn't change | S03 |
| 8 | Swipe the app away from the app switcher with the 20-minute timer running, then reopen it | The timer is still there with the right time left, and there's exactly one Lock Screen activity | S06 |
| 9 | Go to Home, then leave the phone for 15 minutes (or use `-demoTime`) | On return the cook is still running and still Now, not tucked into the ledger | S07 |
| 9b | Back in cook mode, drag the running timer's line left, then tap UNDO | It fades with "Simmer stopped." and UNDO, and UNDO brings it back with its real time left | |
| 10 | Go to the last step and hold **Finish** | The page closes. Any timer still running stops silently. Tess says one line. The Lock Screen activity goes and the recipe's context line reads "cooked today". UNDO on Tess's line reopens the cook on its last step | S14 |

**Write down any fail with its step number and a screenshot, and send it to the Kitchen lead.** Steps 5, 6 and 8 matter most: a timer that doesn't alert with the phone locked is the one failure that ruins a dinner.

Not in this script (slice 12b): pausing, +1 minute, and timers over 90 minutes shown in hours.
