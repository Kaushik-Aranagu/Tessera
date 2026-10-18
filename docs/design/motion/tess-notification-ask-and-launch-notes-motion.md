# Notification ask (G458) and launch notes (G442 to G446): motion, haptic and Low Power rows (board 93)

Docs only; lab defaults marked, Product to overrule. Source: `product/kitchen-open-calls-batches-oct18.md` (project file; batch ruled "Kitchen's default" at 7:24 AM Oct 18, decisions.md). House rules reused: one slot for Tess's line and UNDO, shared hold helper (4 s new, 10 s change or VoiceOver), plain ink lines, one haptic per moment, Low Power = Reduce Motion = 150 ms crossfade, masked text through the one private-text function.

## A. The notification ask (G458)
The ask is one plain line in the Tess slot with its answers as ink words (the one-ask pattern, `one-ask.md`), not a sheet or alert.

| Moment | Normal | Reduce Motion / Low Power | VoiceOver and large text | Haptic |
|---|---|---|---|---|
| Ask arrives | the line enters the slot, 300 ms blur 4 pt to 0 with opacity; answers sit under it as ink words | 150 ms crossfade | announced once on arrival; never re-announced when the page redraws | none |
| It waits | no timer, no fade, no auto-dismiss; it holds until he answers (G458); the soul follows the one-ask wait rules (`tess-motion.md:141`: no roam, split or repaint) | same | stays focusable | none |
| Quiet hours (23:00 to 07:00) | a held ask shows and says nothing: no arrival motion, no announcement, no sound; it appears on the first open after 07:00 | same | not announced until it shows | none |
| Large text | the answers stack under the line, one per row, each a 44 pt band; stacking is a layout change, no animation | same | order: line, then answers, "Not now" last | none |
| He answers | the ask folds out (200 ms), Tess's one receipt line enters in the same slot; the notification choice is written once | 150 ms crossfade both | receipt announced | the area's own `.made`, once |
| "Not now" | folds out, no receipt line, nothing written, the ask returns on the next eligible open per Product | 150 ms | named action "Not now" on the line (G458), spoken as "Not now" | none |

Lab defaults: the arrival blur matches the error notice; "Not now" gets no haptic (it writes nothing).

## B. Launch notes (G442 to G446)
Launch notes are plain lines that explain a bad start. They never use the warning haptic: `.warning` is for a write that did not save in front of him, and a launch note is information.

| Note | Wording (ruled) | Motion | Hold | Haptic |
|---|---|---|---|---|
| Setup failed (G442) | "Couldn't set up your exercises. Close and reopen the app." | enters in the Home slot with the first-frame entrance (no extra motion; 150 ms crossfade in RM/LP); the next launch retries silently | stays until a good launch clears it | none |
| Not saving this time (G443) | "Not saving this time." on Home and the Review header | plain line, no animation after it appears; it does not pulse and no UNDO shares the slot | the whole session; cleared only by a good launch | none (one `.warning` only when an actual write he made fails, per H13) |
| Worded for the next launch (G444) | "Last time your data couldn't open. It's safe." instruction first, three lines at most | crossfade in, crossfade out; at three lines the layout does not grow the page, it scrolls inside the slot at large text | until read once, then 10 s under VoiceOver | none |
| Old-store move (G445) | no line while it runs; it runs behind the first frame | nothing moves; the first frame is never delayed by it | n/a | none |
| First-launch rest-day receipt (G446) | the shared receipt, 4 s hold | normal receipt entrance; outside 07:00 to 23:00 it is held until the next open (no 3 AM receipt) | 4 s (10 s under VoiceOver) | none |

All launch notes are announced once, not on every Home redraw. A note and an UNDO never show together; the newest op wins the slot (DEC:1077 item 2).

## Build checks
1. The notification ask has no timeout path in code; it is only dismissed by an answer or "Not now".
2. Between 23:00 and 07:00 the ask makes no sound and posts no announcement.
3. At the largest Dynamic Type size the answers stack and each is at least 44 pt.
4. No launch note plays a haptic; the first-frame time does not move with the legacy-store move.
5. "Not saving this time." survives a Home redraw and a tab change for the whole session.

## Asks
1. Product: does "Not now" bring the notification ask back on the next eligible open, or never again until Settings? Lab default: next eligible open.
2. Design: wording of the receipt line after he answers the ask.
