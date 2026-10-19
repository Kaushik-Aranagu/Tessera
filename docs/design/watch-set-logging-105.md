# 105. Watch: one-screen set logging

**Status: waits on the Watch target gate** (no Watch target exists; project.yml and CLAUDE.md are iPhone only). Slotted after Builder A's one throwaway free-team build proves the target.

Spec only; Builder A takes it with the Watch target (none yet, so the Watch row in 103 reads Later). Not yet okayed by Kaushik. Extends `watch-quick-wins.md` (W1 finish line, W2 rest in the Smart Stack, Cobalt sky), and `workout-v1.md`. The wrist logs a set in one screen: weight, reps, done, then rest.

## The screen
One screen, no scroll, no tabs, no cards. Cream `#F6EFE4` type on the Cobalt sky wash as W2.
| Row | Content | Type |
|---|---|---|
| Top | Exercise name, one line, never truncated mid-word (shrinks to a shorter form, "Bench" for "Bench press") | Label 16 strong |
| Weight | "82.5" with "kg" or "lb" after in 16 | numeral 44, Digital Crown steps it by the plate step |
| Reps | "8" | numeral 44, tap the side of the screen to step, or the crown after a tap on the word |
| Set | "SET 4 of 5" | 16 at 70% |
| Done | The whole bottom line is the word **Done** on its cream ink line (as W2 line 2); the screen is that line, not a button shape | 21 strong |
- Two numerals and one word: sizes 44 / 21 / 16. No other numerals on the screen.
- The previous set's weight and reps are pre-filled, so a repeat set is one tap on Done.
- Weight and reps use the Crown and a tap on the numeral to switch which one the Crown moves; the active numeral is in full cream, the other at 70%. No highlight box.

## After Done
- The set row turns to the rest: the countdown at 44 tabular, colon at 55%, "+15" as a 16 label word on the right, the cream horizon (2 pt) emptying from the right; line 2 becomes "82.5 x 8" at 21 on its ink line. This matches W2's resting state so the Smart Stack and the app show the same thing.
- When rest is up the countdown becomes "Go" and the Smart Stack warms as W2 specifies. One haptic only (the wrist tap at rest end); the Done tap itself gives the system's own button feedback and we add nothing.
- Undo: a swipe back on the set line, or a tap on "82.5 x 8", takes the set out; "Set 4, removed." with the ink word UNDO for 10 s. The undo plays no haptic.
- Last set: the finish line from W1 (the heart sentence) follows; private workouts read "Private workout, ready to finish" on the finish face.

## Side (sheet 75)
Swipe from the right edge: **THIS EXERCISE**, the sets so far in 21 lines ("82.5 x 8", "82.5 x 8"), newest on top, up to six, then the page turns. Empty: "No sets yet." A swipe back returns. The Crown never moves the side.

## Type and layout rules for the watch
- 16 pt floor holds. Sizes 44 / 21 / 16, Inter Tight only, no italics, no SF system font.
- Always-on: numerals at 70% ink and the horizon stops, no animation; Low Power and Reduce Motion: the rest horizon steps once a second instead of gliding.
- Dynamic Type large: the weight and reps stack; the previous set pre-fill stays; names shorten before they truncate.
- VoiceOver: "Bench press, set 4 of 5, weight 82.5 kilograms, reps 8. Done." Crown adjusts the focused numeral.

## Haptics, one per moment
| Moment | Haptic |
|---|---|
| Crown step | The system detent only |
| Done | The system's own button feedback, nothing added |
| Rest ends | One wrist tap |
| Set removed | None |
| A failed write | One soft warning, the only warning |

## Never
Pills, cards, a rounded-rectangle Done, a hold-to-log gesture, a second haptic on the same moment, italics, a fourth size, a faded or diffused Tess on the wrist, any workout word from a private workout (it reads "Private workout").

## For Builder A
The Watch row (103) gates it. Writes go through the same set-logging path as the phone so the ledger shows no difference; the pre-fill comes from the last set of the same exercise. Complication and Smart Stack stay as `watch-quick-wins.md`.
