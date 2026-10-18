# Kitchen gap rows: motion, haptic and Low Power (board 95)

Docs only; nothing here is built. These rows fill the places where a Kitchen ruling (batch ruled "Kitchen's default", Product, Oct 18 7:25 AM) has no motion spec yet. Anything marked "(lab default)" is a pick by Design lab, for Product to overrule. Every other number and word comes from the ruling or the spec named in the Source line of its row.

Sources: `product/kitchen-open-calls-batches-oct18.md` (G numbers); neighbors `tess-cook-clock-lowpower-and-timer-end.md` (CCK), `tess-groceries-lists-and-home-settings-lowpower.md` (GRO), `tess-day-screens-motion-pass.md` (DAY), `tess-live-activity-lockscreen-widget-motion.md` (LAW), `tess-backups-health-review-motion.md` (BHR), `tess-training-motion-lowpower-pass.md`, `tess-notes-recipes-motion.md` (NRM), `tess-capture-miss-motion.md` (CMS), `tess-notification-ask-and-launch-notes-motion.md` (NAL), `tess-haptics-migration-table.md` (HMT), `tess-lowpower-reducemotion-matrix.md` (MAT).

House rules reused: Low Power = Reduce Motion = one 150 ms crossfade; one haptic per moment; the shared Tess line holds 4 s for a new thing and 10 s for a change or under VoiceOver; the haptic belongs to the action, never to the line; background work never plays a haptic.

## Cook

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N26 (G240) Cook step changes | The step changes as the cook screen already moves it; nothing is added. | Same; Low Power equals Reduce Motion (CCK:17). | A step change is a focus move only, with no announcement. The timer end stays the one high-priority "Simmer is done." (CCK:46, K84.22) and that line is not a live region, so VoiceOver never says the same thing twice on the cook screen. | none |

## Groceries

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N31 (G252) Undo on Groceries | One shared Undo: it runs the Bottom chrome's `undo()` and `takeBack`, then the thing's own reversal plays (a grocery returns to its aisle with the house 320 ms fade-and-rise, GRO:29). The taken-back line shows in the shared slot. | 150 ms fade for the line and the return. | Label "Undo", hint "Puts back what was just done". The taken-back line is announced once (via G251), thing first, for example "Rice, taken back." (lab default wording, from the Plan and Money pattern). | `.undo` once, from the shared Undo; the line itself plays none |

## Plan my day

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N34 (G267) Proposed plan rows waiting | One repeating opacity animation drives the breath, 0.5 to 0.66 (DAY:26). It stops after a few cycles (lab default: 6 cycles) and rests at the mean 0.6. It replaces the 30 fps `TimelineView` on Home and Now (`Features/Home/HomePlan.swift:307`, `Features/Home/NowPage.swift:500`). Training has no proposed-plan-row breath; `TrainingPage.swift:622` is the next-stroke guide (20 fps, already paused in Reduce Motion), outside G267. | Rows sit still at a fixed breath, 0.6 (GRO:53, `HomePlan.swift:342`); no timeline. | n/a | none |
| N44 (G320) A kept plan row | The ink is dry and the row stays in the list; the "Proposed" state is gone. | One 150 ms ink fade (as the Keep moment in DAY). | Reads "<title>, <time>, kept", for example "Reply to landlord, 8 am, kept." No "Proposed", no hint. The only action is Undo, through the shared slot (spoken "<title>, taken back."). The Keep and Skip actions are dropped; skip also checks that the row is not kept. | none on the row; `.undo` once on Undo |

## Widgets and Live Activities

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N46 (G339) Rest widget: "Go" swap and digits | Second timeline entry at `restEndsAt`; the word swaps Resting to Go and the digits roll (LAW:85 `.push(from: .bottom)`, `.numericText`). | Reduce Motion from the environment and Low Power from `ProcessInfo`, both read each time the view is built through one shared helper in `Shared/ReducedMotion` (two lines): the Go swap is a crossfade and the digits do not roll. The entry still lands at the end time and there are no extra entries (LAW:80). Same flag for every future widget. | The word and time read as today | none (widgets have no haptic) |

## Backups

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N47 (G359) Daily backup under Low Power | Nothing on screen. The last good day is remembered per place (UserDefaults) and the whole call is skipped when the day is done; the late tail uses ">" not ">="; the work runs off the main actor inside a background-task assertion. | Low Power: the first daily copy of the day still runs (the safety copy). Late-tail refreshes and the folder re-check wait for the next open with power OK. No visible change in either mode. | Not announced; a failure shows its quiet line on the next open (BHR:24) | none (background work never warns) |

## Training and Exercise pages

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N50 (G383) Trend wet tip | The tip breathes while its page is on screen; the loop stops when the page disappears (no hidden animation under a pushed page). | Sits still at 0.75 opacity, no loop. | n/a | none |
| N51 (G384) Exercise page zooms (history, muscle, path) | `.zoom` as built. | 150 ms crossfade. The three sources join the PL13 test through the one Low Power input; the path buttons' ".up" relation takes the reduced branch. | Focus moves to the new page as today | none |
| N53 (G387) Plans and Exercise day-word stagger and press fade | The five animations (day-word stagger, press fade, and the rest) all run through `tesseraAnimation`; no raw animation in Plans or Exercise (source scan). | Reduced branch: the two transitions drop their offsets; 150 ms fade. | n/a | none |
| N54 (G390) "Add to routine" on an exercise page | The shared Tess line says "Bench press, added to Push A." (thing first; the routine name goes through the mask, G389) with UNDO, 4 s for a new thing. | 150 ms fade for the line. | Announced once. UNDO flat 10 s. Menu items speak "Push A, 5 exercises". | `.made` once through `tesseraFeedback` (HMT:35); UNDO plays `.undo` alone |

## Notes

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N37 (G290) Notes list entrance | The list enters once per visit. It does not replay on a revisit (`animateEntrance` is not forced); the row transition goes through the policy. | The entrance is opacity only; a new row is a 150 ms fade. | List announced with its count (NRM) | none |

## Speak / Ask

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N42 (G314) Write dry window | The Write line dries on its normal window (3 s house window; 2 s in a live workout, DAY:51). | Reduce Motion: 0.8 s Speak and 0.6 s Write. Low Power alone keeps the full 3 s with a stepped drain (about 0.75 s x4, ruled Oct 17 9:34 PM) through `withTesseraAnimation`. Touch cancels, the line empties, then it commits. | Flat 10 s with a named Cancel action, never shortened by RM or LP (DAY:51) | none |
| N55 (G428) First-send notice and a receipt in the Ask line | Two lines in the one slot, in order: the receipt first, the notice second (or the notice appended to the receipt). One claim, one UNDO. The notice still shows on send, 4 s (CMS:18). | 150 ms crossfade, as CMS | Receipt announced first, notice second, each once | the area's own `.made` for the receipt; none for the notice |
| N57 (G441) Typing "undo" | Typed "undo" in Write behaves exactly like saying it: one shared check across Write and Speak, then the Undo moment of the area (N56: "Tacos, taken back." once at high priority). | Same | Same as spoken | `.undo` once, same as spoken |

## Launch

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| N59 (G460) Cold launch in Low Power | The full-history warm-up runs at launch. | Low Power: the warm-up is skipped and the cache builds on the first query, which pays the cost. The first-frame time and the launch notes (NAL:24-28) are unchanged. | n/a | none |

## Build checks

- N26: test that a step change posts no announcement and the timer-end line has no live-region trait.
- N31: `groceriesUndoSharesBottomChromeUndo`; label "Undo" and hint "Puts back what was just done" asserted; one `.undo` per press.
- N34: `proposedRowsDoNotBreatheInLowPower`; no `TimelineView` left at 30 fps (`Features/Home/NowPage.swift:500`, `Features/Home/HomePlan.swift:307`); the normal-power loop stops after its cycles.
- N44: kept row label has no "Proposed" and no hint; accessibility actions are only Undo; skip is guarded on a kept row.
- N46: grep finds one shared ReducedMotion helper used by the Go swap and the digits; a Low Power view build shows crossfade and no roll.
- N47: `dailyBackupSkipsWhenDayDone`, `lateTailUsesStrictGreater`, `lowPowerRunsFirstDailyCopyOnly`.
- N50: `trendTipDoesNotBreatheInLowPower` (named in G383); loop stops on disappear.
- N51: the three sources are in the PL13 test; path buttons take the reduced branch.
- N53: source scan finds no raw animation in Plans or Exercise; reduced branch has no offsets.
- N54: `addToRoutineSaysWhatWasAdded`, `addToRoutineOffersUndo` (named in G390); UNDO 4 s, 10 s under VoiceOver.
- N37: the list does not replay on revisit; a new row fades 150 ms under the flag.
- N42: Write dry is 0.6 s under Reduce Motion and 3 s with 4 steps under Low Power alone; the drain uses `withTesseraAnimation`.
- N55: with a notice and a receipt both due, the receipt is first and there is one UNDO.
- N57: one shared function decides "undo" for typed and spoken input.
- N59: a Low Power cold launch makes no warm-up call; the first query builds the cache.

## Asks

- Design (N34): how many cycles before the normal-power breath rests. The ruling says "a few"; 6 is a lab default.
- Product (N42): G314 is marked in the batch as conflicting with the Oct 17 9:34 PM ruling. This spec follows the ruling-consistent default (Reduce Motion 0.8 s and 0.6 s; Low Power 3 s with stepped drain). Please confirm.
- Product (N31, N44): the exact spoken words for "taken back" on Groceries and a kept row follow the Plan pattern (lab default); confirm or give the lines.
