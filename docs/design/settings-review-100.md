# 100. Settings, the Review section: every open choice is a switch he flips live

**Ask (Product, huddle push, Oct 19), trimmed to `product/review-choices-oct19.md`:** only choices Kaushik has not made yet become switches he flips on his phone and sees at once. Top bar, Stage titles, Area colours, Small images and Tess motion picks are decided and ship without a switch, so they are not here. Drawn for Builder B on 93 (one packed screen, name left and value right), 80 (plain counts, no card), 90 (six rows a page), 75 (every screen has a side) and 99 (reading layouts stay the refit spec behind their switch). Spec only; nothing ships until Builder B takes it. Not yet okayed by Kaushik.

## The section
Settings becomes its own page and REVIEW is a section on it (Product moves LookSentence, RestDaySentence and the Claude section into that page; their order is Product's, not drawn here). Four pages of six rows or fewer, turned by a vertical swipe (sheet 90). The only heading on a page is its section word: LOOKS AND DAY, WORKOUT, CONNECTED, SHOWN.

### One row, always the same
- Name on the left in `ink` (21, never wraps). Current value on the right in `inkSecondary` (21), in Product's own words. A tap flips a two-value row in place; a row with three or more values (Page turn, Tess eyes and mouth) opens its words in place, like Page turn on 93, each previewing once.
- The value that matches master today carries a tiny 16 word **Today** under it, so he can always find his way back. Default is always today's behavior; off or default looks and acts exactly like master.
- Under the row he last touched, one 16 `inkSecondary` before/after line. A page holds six names and one sentence, never a sentence per row.
- Live: the flip changes the real screen at once in the house spring (0.42 s; 150 ms crossfade under Reduce Motion and Low Power). One haptic per flip; no toast, no Tess line.
- **Everything as before** at the top of the section sets every row to Today (second tap within 3 s confirms). It is the only confirm.
- Nothing here stores or shows anyone's words. Private titles stay "Private ..." at 100% ink in every preview.

## Page 1, LOOKS AND DAY (6)
| Row | Values (Today first) | Before / after line |
|---|---|---|
| Reading layout | Today, Sheet 99 | "Groceries, Home, Exercise and Backup read in fewer sizes. Sheet 99 uses three, not five." |
| Page turn | Slide, Turn, Soften, Rotate | "Pages change with a vertical swipe: slide, turn, soften or rotate." |
| Tess eyes and mouth | Today's setting, Eyes, Eyes and mouth | "Tess blinks, and with the mouth she speaks too. She is never faded." |
| Plan my day | Off, On | "Tess offers the day's plan on Now at 8 am. You say yes or no." |
| Shutdown | Off, On | "One line on Now at 9 pm: what is done, what moves." |
| Energy check-in | Off, On | "One tap on the morning drum: low, steady or high. It shapes the plan." |

## Page 2, WORKOUT (4)
| Row | Values | Before / after line |
|---|---|---|
| Rest timer | On (Today), Off | "A timer after each set and a quiet alert when rest ends. Off: no timer." |
| Swap exercise | Two taps (Today), One tap | "Two taps opens the swap. One tap on the name opens it at once." |
| Forgot Finish nudge | Off (Today), On | "If a workout stays open, Tess asks once whether to finish it." |
| Quiet interrupts | Off (Today), On | "On: notices wait in a group while you work out or cook." |

## Page 3, CONNECTED (3)
| Row | Values | Before / after line |
|---|---|---|
| Calendar | Off (Today), On | "On: events show in Now, titles only, read on the phone." |
| Health | Off (Today), On | "On: reads weight and workouts. Nothing is written back." |
| Link fetch | Today, On | "On: a pasted recipe link is read from the web. It says Reading and the site first." |
- Calendar and Health ask the system once, on the first flip. The build has no entitlements yet, so until it does their value reads **Later** and the tap says so in one line; the row keeps its place.
- Link fetch sends the page to Claude to read. It never turns Tess asks Claude on: with it off the value reads **Needs Claude** and a tap goes to that row. Plan my day, Shutdown and Energy check-in follow the same rule if they use Claude; if Builder B's row does not, drop the state.

## Page 4, SHOWN (6)
**Areas shown**, one row per area, value Shown or Hidden: Body weight, Habits, Money, Reading, People, Upkeep. Each starts at today's set. Showing one adds its word to the index and its page to Home's side; hiding keeps every object and only stops showing it ("Hidden, nothing deleted"). Body weight is masked as Private on shared screens.

## Side (sheet 75)
Side swipe is **THE FLIPS**: what he changed and when ("Reading layout, Sheet 99, 9:02 am"), newest first, row name first, the last 10 only, one 21 line each. Tap a line to flip that one back. It sits beside the section, not inside a page, and reads "No flips yet." when empty. VoiceOver: each row reads "Name, value"; actions are Flip, and Choose on rows with three or more values.

## States
- **Long:** 19 rows over 4 pages, six at most per page; the rail on the right edge shows pages 1 to 4.
- **AX1 and up:** name above, value below; the before/after line stays under the touched row.
- **Reduce Motion / Low Power:** crossfade 150 ms; no preview animation on Page turn.
- **Obsidian:** values `inkSecondary`, the touched value in the area colour at 72%.

## Never
Pills, cards, boxes around a switch, "Enabled/Disabled", a toast per flip, a confirm on a flip (only Everything as before), turning Claude on by flipping a row, a fourth size, italics, a faded Tess.

## For Builder B
One table of rows (name, values, default, line) and one app-side `ReviewChoices` store, not in the catalog or backups. Each feature reads its own key, default Today, so shipping the section changes nothing until he flips. Reading layout also needs Builder A's refit (99 section C).
