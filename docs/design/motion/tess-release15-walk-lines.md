# Release 15 walk: motion lines (board 76)

Ready-to-paste "Motion feel" lines for Ops' Release 15 walk, in the same shape as Release 14's M1 to M5 (`docs/ops/release-14-walk-draft.md`): quick looks after the numbered steps, never block, **KNOWN until the PR is in** is a known row and not a fail, FIX FIRST only when the release claims the PR and the look still fails. One line per ruling since Oct 17 4 PM that becomes buildable when the Mac is back. PR numbers are the ones open on master `cdcacde8`; Ops marks a row UNVERIFIED when the release SHA does not contain its PR (the lab cannot read the release SHA). Lab spec behind each line is named in brackets. Nothing here asks him to type a secret-shaped phrase, and no line looks at a private item's words.

| # | Do this | Look for (PASS) | KNOWN until | FIX FIRST if |
|---|---|---|---|---|
| M1 | Finish one task, one logged set, then one workout. | ONE haptic each: the three-tap done pattern for a task or finish, one `.success` only when the workout set a best. Never two buzzes. [haptics migration table, training pass] | the haptics migration PRs land (not open yet; rows 17, 18, 25) | the release claims the migration and a finish still buzzes twice |
| M2 | Turn Reduce Motion on. Finish a task, log a set. | Tess keeps full opacity and colour while she works (position only, no dimming, no swell); one done buzz. [#962, soul fix] | #962 (open at `ec10ccce`) | she fades or loosens under Reduce Motion in a release that has #962 |
| M3 | Turn Low Power on. Open Review, change Look, open a list. | A quick crossfade (about 150 ms), no sliding or zoom; Tess in her own slower form; haptics for his own touches still play. [Low Power flag PR] | the Low Power flag PR (Builder A, after #945) | the release has it and a screen still slides |
| M4 | Start a cook timer of one minute, lock the phone. | It rings once at the end; title "Timer", body "<label> is done." (or "Timer is done." for a private or empty label). Open the app late: it flares with no haptic. [#940, cook-clock pass] | #940 (open at `bf1b5a24`); Builder A adds the ring sound | the text carries a private label |
| M5 | Cook timer, app in front: let it run out. | ONE heavy buzz (`.timeUp`) at zero. A hold-to-start plays no completion haptic. [cook-clock pass] | the haptics migration PR (the cook sites) | two buzzes, or a medium thud |
| M6 | Log a set, let the rest run out, app in front. Then again, locked. | In front: one heavy buzz at zero. Locked: ONE notification "Rest is up" with a masked body, and the activity itself never rings. Skip a rest: no buzz. [live-activity motion, #969] | Core's rest-end notification | an exercise name that is private appears on the lock screen |
| M7 | Finish a task, tap UNDO inside 10 s. | ONE light decreasing tick only; the finished state comes back. [migration table row 26] | row 26 (UNDO word silenced) | UNDO ticks twice |
| M8 | Recipes: send a recipe to Groceries while the store refuses (Ops has the setup), or a copy that cannot save. | The failure line, and ONE soft warning haptic, once. Nothing for an offline or information line. [#889, #895, error-notice] | #889 and #895 | a second warning, or none |
| M9 | Groceries: tap a private row, tap a normal row. | The two rows look and move identically: same strike, same light tick, "Private item" never changes into words. [#885, #912; private rows move like any other] | #885 and #912 | a private row behaves differently, or shows words |
| M10 | Pantry: swipe-add one item. | ONE `.made` tick. A tap that changes nothing plays nothing. [pantry-v2-motion-check; Product ruled `.made`] | the Pantry v2 PR | no tick, or a heavier one |
| M11 | Home: hold START WITH on the plan. With VoiceOver, double tap it. | Hold: one `.made`. VoiceOver says "Hold to keep N tasks" and does NOT complete; the action "Keep" completes with one haptic and no fill. [day-screens pass; DEC:1043] | Builder B's Plan PR (not open) | double tap completes the plan |
| M12 | Capture: type a phrase the grammar cannot read, a short one. | The capture-miss route and its receipt; a too-long phrase (over 600 characters) only says "That's too long to send. Say it shorter." with no haptic. [#884, migration row 14] | #884 | a haptic on the too-long line |
| M13 | Quiet hours: set the phone's clock to 23:30 (Ops decides how). | His own taps still buzz; Tess-initiated lines (a quiet-hours line, a bead lighting) make no sound or haptic. [cook-clock pass; DEC:1011, 1033] | the `Haptic` origin field (build gap) | any Tess-initiated haptic after 23:00 |

## Not walkable on Release 15 (say so, do not fail)
- Money dial and Reading drums, Shutdown, Habits, Day log, Settings (Haptics row, Claude page, Quiet fact line), Backups changes, Health permission timing, the week story, widgets and the 07:00 new-day words: specs exist (#963, #966, #970, #976, #973) but no app code.
- Haptics "off" cannot be walked until a Haptics setting exists.

## Notes for Ops
- Order of looks: M2, M3 and M7 first (no setup); M4 to M6 need a workout or timer; M13 last.
- Each row names the lab spec so a FIX FIRST can be sent to Builder A with the table row, not a paraphrase.
- The export row, "Backup, saved." receipt and Face ID before export (Product, 10:58 PM) are build items with no PR yet.
