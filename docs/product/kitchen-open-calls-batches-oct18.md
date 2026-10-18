# Kitchen open calls, in batches, Oct 18

Product asked for the 225 open PRODUCT CALL gaps in `kitchen-open-gaps-index-oct18.md` (status CALL) cut into batches of about 25, so each batch can be ruled in one pass. Docs only, no new gaps, checkout at the index commit. Defaults are copied or condensed from the hunt's own fix (or Expected) column in `docs/product/kitchen-gap-hunt-NN-*.md`, checked against `/mnt/project-files/tessera/product/decisions.md` (full log to 5:17 AM Oct 18; the repo copy stops at 7:40 PM Oct 17).

**How to rule.** Per batch, answer the last line: YES takes every default in the batch as written; NO means list the ids you want changed. Three kinds of row need more than a yes:

- **CONFLICTS with <date> ruling**: the hunt's own default would undo a ruling already in decisions.md. The default shown is the ruling-consistent one; the hunt's original is named in the cell. A yes takes the ruling-consistent default.
- **no default**: the hunt gives no fix, only "Product to rule" or two options with no pick. It says whether Design or Core input is needed. These cannot be ruled yes; they need an answer or a note to get that input.
- Every other row is the hunt's fix, shortened. Where the hunt lists two options, the default is the hunt's first (or the one a ruling already picks) and the cell says so.

**Order.** Batch 1 holds the before-build gates and the open blockers (of the 26 blockers in the index only G75, G77 and G369 are still open calls; the other 23 are RULED or HIST and are not in this file). Batches 2 to 10 follow feature area: Cook and Recipe, Groceries and Lists, Pantry, Home/Settings/Review, Money/Reading/Notes/Day screens, Widgets/Activities/Intents, Plans/Exercise, Ask slot/capture, launch/notifications (the notification gate calls sit in batch 1).

**Words.** Owners use the index codes spelled out. "Sev" is the hunt tier as copied into the index. Rulings are cited by their decisions.md time stamp (Pacific).

## Batches at a glance

|Batch|Area|Calls|No default|Conflicts|
|---|---|---|---|---|
|1|Before-build gates and open blockers|26|1|2|
|2|Cook and Recipe: reading a pasted recipe|23|0|2|
|3|Cook and Recipe: cook screen and recipe page; Groceries and Lists: Copy list|28|0|0|
|4|Groceries and Lists: masks, Low Power, VoiceOver|22|0|0|
|5|Pantry: grammar, masks and copy|19|1|1|
|6|Pantry: first use; Home, Settings, Review|28|3|0|
|7|Settings, Backups; Money, Reading, Notes|22|0|1|
|8|Day screens; Widgets, Activities, Intents|22|0|0|
|9|Plans, Routines, Exercise|16|0|1|
|10|Ask slot, Speak, capture; launch|19|0|2|
|All||225|5|9|

## Batch 1: Before-build gates and open blockers (26 calls)

### Open blockers (3 of the 26)

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G75|Blocker|Should the Day log show a private list as "Private list" instead of its real name?|In the Day log title lookup, return the list's shown name for list objects ("New list: Private list"); add that test. Same fix closes G104. Matches Oct 17 4:20 PM ruling (op log keeps the raw title; only what he sees masks).|Week review rows and memory lines stop printing a private list name.|Core engine|
|G77|Blocker|May a new or copied list be named with a key, secret or money-looking word?|Refuse in the action when the name looks like a Claude key, holds a secret value or is money-shaped; secret text routes to a private note ("Private note, kept."); same check on CreateList. Product still picks refuse versus strip for a money-shaped name; hunt's fix is refuse.|A list name can never carry a key or secret; a money-looking name is turned away with a plain line.|Core engine, with Product|
|G369|Blocker|Should every masked export carry a "masked" mark so Restore always warns first?|Core writes a top-level masked flag whenever the export masks and decode reads it; the restore warning keys off it; ExportFile.ready stays false until two tests pass (masked file round-trips to the warning, unmasked test file does not). Matches Oct 17 11:07 PM ruling.|A masked file can never restore silently over real data; the Export row stays off until both halves are tested.|Core engine, with Builder B|

### Cook screen gate

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G407|none|Who flips the cook screen on, and what must be green first?|One flip PR sets RecipePage.cookModeReady true and rewrites RecipesOpeningTests line 45 to match; it lands only when scripts/test.sh ends "All green", engine fixtures S01 to S07 and S10 to S15 pass, and a recording shows steps 1 to 8; it goes after A1 to A9 and B8.|The Cook key appears on Now at 0 to buy and nothing can flip it early.|Builder A (clock page owner per Oct 17 11:49 PM ruling), with Ops/QA|
|G193|Important|What must be true before the cook screen is allowed to ship?|Gate the cook-mode PR on: step text masked or hidden for a private recipe, peek rows read "Private item", timers per G189, heading from the one private-text function, no reveal gesture. Add this checklist to kitchen-cook-gate-rows-oct17.md.|No cook screen ships that can print a private recipe's words.|Builder B, with Product|
|G221|Important|Should a cook stay alive while a timer runs or within 45 minutes of the last step?|suspendIfIdle skips a cook while an unstopped timer exists or within 45 minutes of the last step change, else idles at 45 minutes (Oct 17 7:06 PM rule). One reconcile function runs from foreground, launch, time-zone change and clock change, no polling. Tests: idle 46 min suspends, idle 46 min with a flared timer does not, a time-zone change leaves fire times alone.|A cook with a timer never suspends under him; an abandoned cook still clears after 45 minutes.|Core engine, with Builder A|
|G222|Important|How should the cook Lock Screen card avoid the rest card's traps?|Activity carries every timer's end date; each countdown is system timer text; stale date is the soonest end; no sound in the update (the notification is the only alert, Oct 17 9:46 PM). Lead shows Done at stale, "+N" stays, next lead appears at next app run. Title and label masked before reaching the Activity. Stop works with the app suspended. Design confirms the suspended face.|One quiet card that stays right with the app asleep; sound comes only from the notification.|Builder A, with Design|
|G231|Important|Should a receipt like "added" be announced to VoiceOver right away, once?|One announcement helper (high priority, attributed) used for added, nothing and failed, and later for the cook's "Simmer is done.", "Simmer stopped." and Done receipts; silent on a repeat.|VoiceOver users hear each receipt once and promptly, not whenever it queues.|Builder B, with Builder A|
|G232|Important|When ingredients slide off the recipe page, should VoiceOver stop reading them?|Hide the column from the accessibility tree while it is away; focus moves to the sent line, then back to the first row on UNDO. One focus helper serves the page and the cover; no second announcement.|VoiceOver never wanders into hidden ingredients after Add all.|Builder B, with Builder A|
|G251|Important|Should every Tess receipt and refusal be spoken to VoiceOver once, thing first?|One helper inside TessVoice.say: a high-priority announcement, thing first as written, once per line, not repeated when the same line is said again, off when VoiceOver is off. Refusals and "Didn't save that. Try again." use it too.|Receipts stop being silent for VoiceOver users, and many later rows simply reuse this helper.|Builder A|
|G354|Important|What may the cook Lock Screen card show for a private or unnamed timer?|Label goes through the G353 function (private, empty or number-only shows "Timer"). One reading order: soonest timer first ("Simmer, 8 minutes left"), then "Private recipe, cooking". The Done face announces nothing itself; the notification is the audible cue. Stop is a labelled key ("Stop Simmer" or "Stop Timer"). Same Dynamic Type rows as G347.|No private timer label ever reaches the Lock Screen, and there is one reading order.|Research, with Kitchen lead and Design|

### Pantry v2 gate

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G199|Important|Where in app launch does the one-time Pantry backfill run?|Name the call site: after the engine opens, behind settingsAreReal, marker written inside the backfill's own transaction; test that a crash before the marker reruns it harmlessly. Hunt says "never in a demo"; G215 says run once after -resetDemo; default here follows G215 so the two agree.|The backfill runs once per real store and a crash cannot leave it half done.|Core engine|
|G200|Important|Should Tessera save a copy of his data before the Pantry backfill writes?|Write or confirm a one-off "before-pantry" copy beside the rolling copies before the backfill runs (hunt's first option; the other is to state that yesterday's copy is the way back).|The bulk write has a known way back without needing an UNDO.|Core engine, with Builder B (Backups copy)|
|G201|Important|Should the Pantry backfill stay off the first frame and be proven fast on years of history?|Run it off the first frame and hold the Pantry front (not "Nothing yet") until it finishes, or prove the budget with scripts/test.sh --scale and write the number in the PB18 row.|First launch never stalls or shows a false empty Pantry.|Core engine|
|G203|Important|When Egg and Eggs fold into one ingredient, which one keeps the Pantry state?|The oldest id survives; state moves or copies to it; lastBoughtAt takes the later date; everything reads through the key (PantryBook.state(forKey:)); test aRecipeLinkedToTheTwinReadsTheFoldedState. The fold runs only at backfill and capture, never on rename (Oct 17 7:38 PM).|No lost state and no double lines for twin names.|Core engine|
|G409|none|Which wins when the Pantry walk script's appendix and the PE file disagree?|The PE file wins. Fix the appendix (24 rows against 29: PE09 receipt names the items that changed, PE15 gets the no-receipt, no-haptic clause) or point it at the PE file.|The walk grades the current 204 rows, not stale wording.|Kitchen lead, with Ops/QA|

### Notifications gate (G451 to G460 build list)

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G452|Important|Should someone who only trains ever be asked to allow rest alerts?|**CONFLICTS with Oct 16 6:30 PM ruling** (the notification ask fires only on his first "remind me", timed task or cook timer). Hunt's default adds the first logged set as a fourth trigger. Ruling-consistent default: keep the three triggers; a training-only user keeps the in-app rest alert, which the G453 line tells him once; the ask comes with his first timer or reminder.|Training-only users get no locked-phone rest ring until they set a timer or reminder; nobody is asked early.|Product, with Builder A|
|G453|Important|When Live Activities are off, should Tess say the rest will end silently?|When Live Activities and notifications are both off or unasked, say once in the rest line "Rest ends in the app only." and keep the in-app alert. G457 settles the exact fallback words.|He is never surprised by a silent rest, at the cost of one line, once.|Builder A, with Builder B|
|G454|Important|Should "remind me Saturday" ring at 9 am, or carry no time at all?|**CONFLICTS with Oct 16 6:30 PM ruling** ("remind me sat" rings at 9 AM Saturday; a plain "call mum sat" gets no time and no alert). Hunt's default (no time, no ring) contradicts it. Ruling-consistent default: "remind me Saturday" rings at 9 am; a task with no time and no "remind me" gets no ring; fix notifications.md lines 47, 110 and 153 to say so.|Reminders ring when he asks for one; plain tasks stay silent; docs agree with the log.|Product, with Core engine|
|G455|Important|Should Tess warn that Sleep Focus may hold a 5:30 am overnight timer?|Say it once at the first overnight timer ("Sleep Focus may hold this. Allow Tessera in Focus."), or try Time Sensitive once on the phone (unverified on a free team); reword K6.9. Hunt's first option is the default.|He learns once why a Focus-held timer may stay quiet; no new permission.|Product, with Kitchen lead|
|G456|Important|When he changes notification permission in iOS Settings, should Tessera notice and catch up?|Read the authorization on every scenePhase active (not cached); on a flip to allowed run the full reconcile; the Settings row opens Tessera's notification page and shows the state.|Turning notifications on later just works, with no stale off state.|Core engine, with Builder B|
|G457|Low|Should one table hold every notification word so the docs stop disagreeing?|One notification-words table in notifications.md (rest "Timer" and "Rest is up", fallback "It rings in the app only.", hold to 07:00), plus the line "Low Power never changes a ring; the in-app flare follows Reduce Motion". Matches Oct 18 12:23 AM ruling.|Builders copy one set of words.|Research, with Product|
|G458|Important|Should the notification ask wait for his answer and work with VoiceOver and large text?|The ask holds until answered (no timer), is announced once, stacks its answers at large sizes, and "Not now" is a named action; a held ask (quiet hours) says nothing.|Everyone can answer the ask and no timeout loses it.|Design, with Builder B|
|G459|Low|Should Reading, People and two other areas be listed as never sending notifications?|Add the four to section 5 of notifications.md as "never".|The never-notifies list is complete and builders cannot add one by accident.|Research|
|G460|Low|Should cold launch skip the full-history warm-up when Low Power is on?|In Low Power, skip the warm-up and build on the first query.|Cooler, faster launch in Low Power; the first query pays the cost.|Product, with Core engine|

### Settings gate

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G422|none|When the Claude key line opens on Settings page 1, which row folds so the page still fits?|**DESIGN PICK (Oct 18 7:16 AM):** no row folds. Page 1 is "Tess asks Claude" with Key, This month and Receipts opening inside that row, then Page turn: 5 lines at most, under the 6 limit; the open row pushes Page turn down. At AX3 the value drops under the name and the page uses sheet 90's smaller page size (extra lines turn to the next page, Receipts last).|Page 1 never runs past the screen.|Builder B, with Design|

**Rule all as default? Batch 1 (26 calls): YES / NO** (2 conflict rows take the ruling-consistent default shown; 1 row marked "no default" needs an answer, not a yes).

## Batch 2: Cook and Recipe: reading a pasted recipe (23 calls)

### Paste title, steps and duplicates

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G93|Important|If a pasted first line is a short question or shout, should it still be kept as step 1?|In classify, when the first line is a sentence, force it to a step with numbering stripped; add a test for lines ending in "!" or "?".|"Is this the best dal?" stays as step 1 instead of becoming an ingredient.|Core engine|
|G94|Important|Does a first line starting with a number count as an amount or as the recipe title?|**CONFLICTS with Oct 17 5:59 PM ruling** (also 3:43 PM, 4:20 PM, 6:00 PM). Hunt's rule (number plus unit or lowercase noun is an amount; number plus a capitalized word is a title) disagrees with it. Ruling-consistent default: a first line starting with a number is an amount when it is exactly two words ("2 eggs", "2 Eggs", "5 Spice") or when a unit or size word follows the number at any length ("500 g plain flour", "2 large eggs"); three or more words with no unit word are a title ("3 eggs benedict", "7 Up Cake"); a hyphen joining a number to a letter word is a title ("30-Minute Dal").|Two-word names like "5 Spice" become "Untitled recipe"; longer titles starting with a digit stay titles.|Product, with Core engine|
|G95|Low|Should "Two eggs" or "Half a lemon" as a first line count as a quantity?|Accept as is: written-out quantities stay as they are (Oct 17 5:40 PM ruling, low); no number-word test added. Hunt offers either add number words or accept; the ruling picks accept.|"Two eggs" may be taken as a title; no parser change needed.|Product|
|G96|Important|Should a closing quote, bracket or emoji after a period still count as a stop?|Strip trailing quotes, brackets, emoji and spaces before the stop check.|Web and chat copy no longer turns a 12-word sentence into the title.|Core engine|
|G97|Low|Should the title rule work for non-Latin text and cap very long titles?|Count words with word enumeration, add full-width stops and the ellipsis as stops, cap a title at about 80 characters.|A pasted non-English sentence no longer becomes a whole-paragraph title.|Core engine|
|G98|Important|Should a repeat paste with a trailing space or Windows line ending count as a duplicate?|Compare a normalized form (trim, CRLF to LF, trim each line) on both the paste screen and the Tess path.|No second copy of a recipe he already saved.|Core engine|
|G99|Low|Should the duplicate-recipe line use the short recipe name like other receipts?|PasteCopy.duplicateLine calls CreateRecipe.duplicateLine, and the title goes through shortName.|The duplicate line stays short and the two copies of it cannot drift.|Builder B|
|G100|Low|Should the dead "isPrivate" check on recipes be deleted or backed by a real flag?|Delete the three dead checks (Recipes.swift:193, PasteRecipe.swift:591, Groceries.swift:560), the hunt's first option; privacy stays with the one private-text function. If the self-marked private recipe in the Oct 17 3:25 AM ruling is wanted, take the second option instead (add the flag in all four places).|Dead code goes; no behavior change today.|Core engine|
|G101|Low|When two pastes both end up "Untitled recipe", should Tess nudge him to rename?|Say "Untitled recipe" with a rename nudge on the saved line (hunt's first option; the other is numbering them).|He is prompted to name it; Tess "cook untitled recipe" is less ambiguous.|Product|

### Amounts, scaling, times

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G109|Important|Should "1-1/2 cups" read as one and a half cups, not a range?|When the right side is a proper fraction smaller than the left and the left is whole, add them.|Page and Groceries both show 1 1/2 cups instead of "1 to 1/2".|Core engine|
|G110|Low|Should the fraction reader cover every fraction glyph, thousands and a zero denominator?|Complete the fraction map (all vulgar fractions and U+2044), add a thousands rule ("1,000 g" is 1000), add a zero-denominator guard.|No more eaten text or wrong amounts from rarer fractions.|Core engine|
|G111|Low|Should "2 or 3", long-dash ranges and inch or cm sizes read correctly?|Add "or" and the long dash to range words; treat inch and cm sizes as part of the name.|"2 or 3 cloves" reads as a range; "1 inch ginger" keeps its size.|Core engine|
|G112|Important|Should "a pinch of salt" and "a dash" be read without an amount?|Make unit words readable without an amount and add a number-word table; a dash or splash unit is kept as written and never scaled (hunt's own default).|Pinch and dash lines stop being dropped or misread.|Core engine, with Product|
|G113|Important|Should every "to taste" and "as needed" form be flagged as optional?|Flag all three forms (parenthetical "to taste", "season to taste", "as needed") and treat "as needed" as to-taste. Matches Oct 17 4:30 PM rulings R3 and R4.|Groceries, Pantry and CAN COOK stop counting those lines as missing.|Core engine|
|G114|Low|Should pack lines like "1 can (14 oz)" keep their size or fall back to their words?|Keep the first size; fall back to the original words as the name.|Nameless pack lines are no longer dropped and sizes are not lost.|Core engine|
|G115|Low|How should the metric tap show grams: "28.4 g" or whole numbers?|Whole grams above 10, one decimal below.|Metric amounts read like a kitchen scale, not a calculator.|Builder B, with Core engine|
|G116|Important|Should "1 lb 2 oz" or "2 x 400 g" keep only the first amount?|Strip a leading second amount (and "plus", "+", "x") from the name and keep it in the original text; first amount only (hunt's own default).|No junk ingredients in Groceries and Pantry from compound amounts.|Core engine, with Product|
|G117|Important|Should ounces halve cleanly below 4 oz?|Use half-ounce steps below 4 oz.|3 oz halved reads 1 1/2 oz instead of 2 oz.|Core engine|
|G118|Important|Should "half an onion" shrink, not grow, when the recipe is halved?|For unit-less and count units, an original amount under 1 rounds to quarters with a floor of 1/4; test halfAnOnionAtHalfSizeIsAQuarter.|Scaled lines and the Groceries list stop over-counting.|Core engine|
|G119|Low|Should cups snap to thirds as well as quarters?|Round to the nearest of 1/4, 1/3, 1/2, 2/3, 3/4 under 1 cup.|A doubled 1/3 cup reads 2/3, not 3/4.|Core engine|
|G120|Important|Should "Makes 24 cookies" and "Feeds 4" lines set the serving count?|Allow up to three trailing words, add the keywords (Makes, Yields, Feeds, Portions), treat an overflowing number as no number.|Serving counts are picked up from more recipe styles.|Core engine|
|G121|Important|Should durations like "1 1/2 hours" or "half an hour" start the right timer?|Support mixed numbers and fractions, word numbers, "d" for days (clamped) and bare trailing minutes.|Recipe timers and the recipe clock stop misreading longer times.|Core engine|
|G122|Important|What is the final title-versus-amount rule for a recipe's first line?|**CONFLICTS with Oct 17 5:59 PM ruling** (also 6:00 PM). Hunt's rules 3 and 4 ("3 bean chili" is a quantity; number plus a capitalized non-ingredient word is a title) disagree with it. Ruling-consistent default is the G94 rule: two words is an amount, a unit or size word at any length is an amount, three or more words with no unit word are a title, number-hyphen-word is a title. Hunt's rule 5 (title when an Ingredients heading comes later and no other candidate) matches Oct 17 4:30 PM and stays.|One written rule and one test list; no leftover cases from the old wording.|Product, with Core engine|

**Rule all as default? Batch 2 (23 calls): YES / NO** (2 conflict rows take the ruling-consistent default shown).

## Batch 3: Cook and Recipe: cook screen and recipe page; Groceries and Lists: Copy list (28 calls)

### Cook screen and recipe page

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G188|Important|Should a private recipe's cook show no step text, only "Step 2 of 6"?|A private recipe's process stores and shows no step text; the next step reads "Step 2 of 6"; mask at the source (Cooking.swift), not in the row.|Now never prints private step words under a masked title.|Core engine|
|G189|Important|What should a private or unnamed timer label read on screen and aloud?|"Timer", via the one function: a private, empty or digits-only label shows "Timer", body "Timer is done." (Oct 17 10:47 PM G353 ruling picks the word), masked at the source with the one private-text function.|No private timer label is stored or shown raw anywhere.|Core engine, with Product|
|G190|Important|What should the finish line say after cooking a private recipe?|"Private recipe, third time this month." (hunt's first option; the other is silence); add a test before cook mode lands.|The finish line never prints a private recipe's title.|Core engine|
|G191|Low|Should a private finish receipt read "Private recipe, done." with the comma?|"Private recipe, done."|The private receipt matches the thing-first form of every other receipt.|Core engine|
|G194|Low|Should the paste preview hide a private title before he taps Save?|The preview of a private title reads "Private recipe" (hunt's first option; the other keeps it in the field until Save). Product also says whether the preview counts as a live text field.|A private title is never drawn on the preview before Save.|Product|
|G195|Low|Should Tess's shelf line skip private cooks instead of counting them?|Skip private rows in the Tess line. Matches Oct 17 5:05 AM ruling (Pantry line silent after a private cook).|No private cook count leaks onto the shelf line.|Builder B|
|G220|Important|What does the cook screen do in Low Power, and how often does its clock tick?|Add Low Power columns to section C: Low Power equals Reduce Motion for cover and clock (bead still, no breath, no ring, flare is a color change, 150 ms fades, haptics kept); horizon steps down once a minute, except every 10 s in a timer's last minute (Oct 17 9:22 PM ruling). Every figure derives from the absolute end time; seconds use system timer text; minute figures fire at the next minute boundary; ticks live in a leaf view; the timeline pauses when the scene is not active.|The clock page is cheap to run and never drifts.|Kitchen lead, with Design and Builder B|
|G226|Low|Should the Home cook bar redraw every second?|Tick at the pixel cadence (a step every 5 to 10 s) or on the minute for the line; in Low Power or Reduce Motion one step a minute with a 150 ms fade.|Less battery drain on Home with a cook running.|Builder B|
|G227|Low|Should the Reduce Motion fade be 150 ms everywhere?|One number: 150 ms; Design edits sheet 69. Matches Oct 17 9:23 PM ruling (HS43).|One reduced-fade number in every spec.|Design|
|G230|Important|Should "Add all to Groceries" be a button VoiceOver can reach?|Put the action on every row (or on the first row and the rotor), or add a visible "Add all to Groceries" word that is a button; check on a device that the row's action list contains it.|VoiceOver users can send the whole recipe to Groceries.|Builder B|
|G234|Low|Should Home's cook bar be read as minutes left rather than a percent?|Value "6 minutes left" for a cook or timed task; percent only if nothing else is known.|VoiceOver says something useful about the cook.|Builder B|
|G236|Low|Should the recipe context line be read in words ("45 minutes") not as drawn ("45 min")?|Accessibility label in words ("45 minutes, cooked 12 days ago"; "1 hour 35 minutes"); serves left to the drum.|VoiceOver stops saying "min" and "h".|Builder B|
|G237|Low|Should "Show in metric" say something when VoiceOver is on?|Announce the metric text once (high priority) and hold the metric label while VoiceOver runs, reverting when focus leaves the row.|VoiceOver users hear the converted amount.|Builder B|
|G238|Low|Should the recipe Back word be a full 44 pt target with an escape gesture?|44 pt target, label "Back to Recipes" (no hint), escape action that dismisses, edge swipe on the live page; the cover gets the same escape.|Back is easy to hit and works with VoiceOver.|Builder B|
|G239|Low|Should the recipe page read in the same order at every text size?|One order everywhere: hero, context, Serves, Ingredients, "N to buy", steps, Cook; use sort priority or build the drum first in both layouts; add a row mirroring K84.29.|VoiceOver order no longer changes with text size.|Builder B|
|G240|Low|Should step changes stay silent so they do not double-speak with timer ends?|Step change is a focus move only with no announcement; timer end is one announcement and that line is not a live region.|VoiceOver never says the same thing twice on the cook screen.|Kitchen lead|
|G243|Low|Should the recipe page start its single scroll at the XXXL text size?|Render at XXXL on iPhone 17 and, if the column drops under about 3 rows, start the single scroll at XXXL; add XXXL to the page's Dynamic Type row set.|Large-text readers see enough ingredient rows at once.|Builder B|

### Copy list and Lists on Now

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G73|Important|Should "copy packing for lisbon" work as a phrase and from a Copy word on the list page?|Add "copy <list> for <name>" to TessGrammar and a Copy word on the list page. A copy does not open itself; the receipt opens it on tap (Oct 17 8:15 PM). Name "Packing, Lisbon" and receipt "Packing, Lisbon, new list." (Oct 17 3:50 PM and 3:32 PM).|Copy list finally has a way in; undo removes the copy.|Core engine, with Builder B|
|G74|Important|Should Gym bag, Leaving the house and Packing be installed as starter lists?|Seed the three through the paste path, then SetListReusable, with a seeded-once flag so a deleted one never returns; items install capitalized (Oct 17 3:32 PM). Product picks where the marker lives; the ruled pattern for a once-marker is a Settings key (as pantryBackfilled, Oct 17 4:32 PM).|New installs start with three useful lists he can delete for good.|Core engine, with Product|
|G78|Important|Should a running list show as the hero on Now?|Add a branch before the rest and plan branches that renders the running list through HomeLines.line(for: facts.fact(process:)); confirm on a phone.|A list run in progress is visible on Now.|Builder B|
|G79|Low|Should the Now picker show a private list as "Private list"?|Use ListContents.shownName when the subject is a list.|The picker no longer prints a private list's title.|Core engine|
|G80|Low|Is the colon right for "Packing: 6 left." or should it be a comma?|Reorder the guard so a paused list with nothing left says it is paused, and keep the colon (cooks and shops share it); Product confirms the colon.|One form for the list fact; a paused list no longer reads "all done."|Product, with Core engine|
|G81|Low|Which is right for the Lists context line: "2 lists, Packing running" or "2 lists, 1 running"?|Update lists-acceptance.md 13.3 to "2 lists, 1 running" (code is right; a name there could be private; accepted Oct 17 5:20 AM).|Doc and code agree; no list name in the context.|Product|
|G82|Low|Should list names use one privacy check everywhere?|One helper, ListContents.shownName(_:lastWeightKg:), used by every list-name site, in line with the one private-text function.|Two checks that could disagree become one.|Core engine|
|G83|Low|Should a copied list carry its item links and dates?|Copy the links (about); a copy never carries dates (a trip copy should not land on Today).|Copies keep their links but never show up on Today.|Core engine, with Product|
|G84|Important|Should a list phrase that does not match go to Claude or just miss?|G73's grammar rule makes it a phone-only rule; until then offer a one-line miss. Product still rules whether list-verb misses may ever reach Claude.|"Copy packing for lisbon" no longer travels to Claude and then fails.|Core engine, with Product|
|G85|Low|If a private list is copied under a public name, should the copy be marked private?|Confirm no extra private mark: the name is public by the word rule and rows keep their own words; no code change. Private-named copies read "Private list, new list." (Oct 17 4:00 PM).|No code change; the spec states it.|Product|
|G86|Low|Should the six missing Copy list tests be added?|Add the six tests next to LRT:274-352.|Copy list rules are locked in by tests.|Core engine|

**Rule all as default? Batch 3 (28 calls): YES / NO**.

## Batch 4: Groceries and Lists: masks, Low Power, VoiceOver (22 calls)

### Masks and receipts

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G103|Important|Should the object page show "Private item" and "Private list" instead of raw Groceries titles?|Add list item to "Private item" (health, secret, money or title wall), list to "Private list", ingredient to the label its private users get (as PrivateWords already does for export); Builder B tests the page.|Opening a Groceries item or list from the Objects browser or a link never prints a private word.|Core engine, with Builder B|
|G104|Important|Should the Day log mask a private list's name and task titles?|Same fix as G75, done once: title(of:) uses ListContents.shownName for lists and ObjectPrivacy.label for tasks.|Closes the Day log leak for lists and tasks in one change.|Core engine|
|G106|Low|Should stored op summaries be built from the masked label instead of raw titles?|Build summaries through the same label function, thing first. Per Oct 17 4:20 PM ruling the op log keeps the raw title in its payload as data; only the summary text he can see is masked.|Summaries like "Took <recipe> off groceries" stop carrying private titles.|Core engine|
|G107|Low|Should recipe ingredients sent to Groceries pass the same Add-line wall?|Run the text through AddListItem.shownTitle before createGroceryRow.|A medicine ingredient is stored as "Private item", not raw.|Core engine|
|G108|Low|When three or more items are added, should UNDO name the whole add?|Cut the UNDO text at the last ", on " instead of the first ", ".|"Oat milk, eggs and 2 more" is taken back as a whole, not as "Oat milk".|Builder B|

### Low Power, VoiceOver and large text

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G244|Important|Should the shop seam sit still in Low Power instead of redrawing at 60 fps?|In Low Power or Reduce Motion the seam is still and lit. In normal power run the timeline only across the 1.35 s glint, or drive it with one repeating Core Animation.|Big battery saving while a shop or list runs.|Builder A|
|G245|Important|Should the Groceries tick, dab and aisle motion follow Low Power too?|One cached reduced flag (Reduce Motion or Low Power, updated on power-state change) fed through check, AisleHandoff.transition, the peek transition and the breath. Meaning is unchanged: same strike, count and haptics.|Groceries obeys Low Power the way the rest of the app now does.|Builder A, with Builder B|
|G246|Low|Should the aisle fade use the app's 150 ms reduced fade?|Route both through MotionPolicy.reducedMotionFade (150 ms), delete the 0.18 literals, add a test that the reduced transition equals that number.|One reduced-fade number everywhere.|Builder B|
|G248|Low|Should the ambient wash and key sheen pause in Low Power?|Pause the wash and skip the sheen and bead under the flag; the key still fills and completes with the same haptic.|Quieter, cheaper screen with no change in what the key does.|Builder A|
|G252|Important|Should the Groceries Undo word say what was taken back?|Share the Bottom chrome's undo(): run undo and takeBack, say the taken-back line (announced via G251), play .undo. Label "Undo", hint "Puts back what was just done". Fix G108 at the same time.|Undo on Groceries behaves like Undo everywhere else.|Builder B|
|G253|Important|Should shelf rows be read as normal sentences instead of all-caps strings?|Label is the shown name; value in sentence case ("Running, 9 left", "3 of 7", "Pick one", "Nothing to get"); draw the capitals with text case, not in the string; action "Pick one" on a Pick one name.|VoiceOver stops spelling out capitals.|Builder B|
|G254|Important|Should a private Groceries row have Check off and Remove actions for VoiceOver?|Add "Check off" and "Remove" named actions to both rows; build the Groceries swipe so "Private item, removed." and "Private item, back on Groceries." exist; announce via G251.|Private rows are as usable as any other row with VoiceOver.|Builder B, with Core engine|
|G255|Important|After Done on a reusable list, where should VoiceOver focus go?|Announce the ask (G251), move focus to its first word with an accessibility focus state, hold the timeout while focus is inside it; hint on Reset "Unchecks all N".|The Reset ask is not lost to a VoiceOver user.|Builder B|
|G256|Important|Should VoiceOver hear which name Pick one landed on?|Announce the name when it lands ("Dune."; a private one reads "Private item") and "That's all of them."; focus moves to the name; action "Pick again"; hint "Opens it" stays.|The pick is heard, not only seen.|Builder B|
|G259|Important|Should the mirrored Tess line grow instead of being cut at large text sizes?|Let the line grow: no line limit at accessibility sizes, width from the screen minus the gutters; add a receipt and a refusal to the AX5 render set.|Long receipts are readable at the biggest text size.|Builder B|
|G260|Low|Should long list rows wrap and Reset stack at large text sizes?|Remove the line limit; stack the two words at accessibility sizes (ViewThatFits, as the option words already do); lift the cap.|Long list names and Reset stay legible.|Builder B|
|G261|Low|Should moving to a new aisle in a shop be announced?|Announce the new aisle once ("Dairy, 3 left.") and put focus on its header, using the G251 helper and the G255 focus helper.|A VoiceOver shopper knows where the shop moved.|Builder B|
|G262|Low|Should Groceries and the list pages answer the VoiceOver "go back" gesture?|Escape action on the shelf, the list page and Groceries; label the hosting word "Back to Kitchen".|Going back works by VoiceOver gesture.|Builder B|
|G263|Low|Should the running-list row on Now be read in words and say it resumes?|Spoken label "Packing, 6 left, 21 minutes ago", hint "Resumes the list"; the visible text can keep "min".|VoiceOver users know the row resumes the list.|Builder B|
|G264|Low|Should grocery row labels say the thing before the amount?|Label is the thing, then the amount; drop the quantity on a masked row; announce the recipe names when the action runs; value "Done" on a struck row.|Rows read "Milk, 2" not "2, milk".|Builder B|
|G265|Low|Should the Lists option words be real toggles for VoiceOver?|Add the toggle trait; split label from gesture text; move the count to the hint; give the door the running list's state as a value.|VoiceOver users can tell which options are on.|Builder B|
|G266|Low|If a Lists save fails, should Tess say so and buzz once?|Say "Didn't save that. Try again." on both failures (announced via G251) and play .notSaved once per failure on both screens; correct the comment. Matches Oct 17 7:39 PM ruling D3.|A failed Lists save is never silent.|Builder B|

**Rule all as default? Batch 4 (22 calls): YES / NO**.

## Batch 5: Pantry: grammar, masks and copy (19 calls)

### Pantry engine and phrase

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G87|Important|Should Recipes read Pantry state so CAN COOK uses what he has?|After stored state lands, add an "in" cover rule beside covered in Recipes. CAN COOK stays greyed with no state (Oct 17 4:30 PM, R6).|CAN COOK finally reflects Pantry.|Core engine|
|G88|Important|Should the Pantry ledger move into Core before Recipes depend on it?|Lift the type into Core and add the Ingredient state and lastBoughtAt fields; the derived events become the migration seed. The six-field catalog bump is already ruled (Oct 17 8:39 PM).|Pantry state has one home in the engine.|Core engine|
|G89|Important|Should CAN COOK treat staples, optional lines and private items the way Pantry does?|Put staples, optional, to-taste and the private label into one "missing" helper and test the five cases. Oct 17 4:30 PM rulings settle the open points: staples (R3) and optional or "as needed" (R4) are skipped, unknown counts as to check (R5, R6); a private ingredient reads "Private item".|CAN COOK and Pantry can never disagree about what is missing.|Core engine, with Product|
|G90|Low|Should the Pantry hero count stored states the screen never shows, or add a "N private" count?|Leave as is and confirm it in the S-rows: a private line counts in the hero without naming (Oct 17 6:06 AM and 4:30 PM R13). The alternative is an "N private" count.|No new element; the hero number stays honest about private items.|Product|
|G91|Low|Should the Pantry line "Say out of milk" show before the phrase works?|Drop the line until the phrase ships (Oct 17 5:14 AM ruling already drops it); it returns with G92.|No promise the app cannot yet keep.|Builder B|
|G92|Important|What must "out of milk" handle: body phrases, two items, "got milk", unknown names?|Write the fixtures first (out of breath, ran out of, "milk is out", two items in one op, private names read "Private item, out. On Groceries.", price stripped, key-shaped tail refused, "already on Groceries" with no UNDO), then the rule. Rulings fill the two open points: "got" or "bought" sets lastBoughtAt (R10) and a name is admitted only if a known ingredient or aisle guide hit (R8).|The phrase never fires on "out of breath" or "have a call at 3".|Core engine, with Product|

### Pantry copy and masks

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G140|Important|Should Pantry use the one widest private-text check, with the food-word trims?|Apply the trims, make one public function, swap both Pantry call sites to it (Oct 17 4:20, 4:22 and 4:35 PM rulings).|"Dentist" items mask; "Blood orange" and "Energy drink" stay readable.|Core engine|
|G141|Important|Should the ingredient page show "Private item" instead of the raw title and class line?|Add ingredient, list item and list branches to label(of:) using the one function, label "Private item".|Recipes and Groceries links can no longer open a page that prints a private ingredient.|Core engine, with Builder B|
|G142|Important|Should Tess memory and Home's cook title use the one private-text function?|**CONFLICTS with Oct 17 4:22 PM ruling** ("memory keeps its own wall"). Hunt replaces both with the one function. Ruling-consistent default: Home's cook title uses the one function; the memory filter keeps its own wall but gains the missing health check (EngineWall.isHealth) with no title-word widening.|A "Cooked <care title>" line stops reaching memory, without changing memory's own rules.|Core engine|
|G143|Low|Should one Pantry swipe say the same thing the engine stored?|Speak the engine receipt, or share the one function between both.|The spoken line and the stored summary can no longer disagree.|Core engine|
|G144|Low|Should the Pantry cook line use the short recipe name?|Pass RecipeCopy.shortName of the masked title.|No more 12-word Tess lines.|Builder B|
|G145|Low|Should Tess lines keep an ingredient's casing the way receipts do?|**DESIGN PICK (Oct 18 7:16 AM):** yes, Tess lines keep the stored case like receipts ("Rice, added on Trip."); a private item reads "Private item".|One casing everywhere.|Product|
|G146|Low|Should Pantry's "took N things" count private items without naming them?|Count private items in the number, never name them. Matches Oct 17 6:06 AM ruling.|"Tacos took 6 things." when six were used, with no leak.|Product|
|G147|Low|Should private Pantry rows sort last inside a state?|Sort private rows last in a state, by id.|A private row's place no longer leaks which ingredient it is.|Builder B|
|G148|Low|Should the body-weight lookup run once per Pantry read, not per ingredient?|Read it once per facts() pass.|Pantry opens faster with long ingredient lists.|Builder B|
|G149|Low|Should Home get a Pantry hero line, or should the spec sentence go?|Strike the sentence ("never a Home offer" argues for striking).|Home stays as built; the spec stops promising a line.|Product|
|G150|Low|Should the "Bought Sat" wording be wired up and masked?|Wire it after G141, with a private-page test.|Bought days show on Pantry pages, never for a private item.|Builder B|
|G151|Low|Should the missing Pantry tests be added?|Move the label to Entry.spoken and add the six tests.|Private label and summaries are locked in by tests.|Builder B|
|G152|Low|Does a private Pantry line have a tap target?|Confirm: a private Pantry line has no tap target and the swipe still adds ("Private item" to Groceries). Follows Oct 17 4:30 PM R12 and 5:12 AM rulings.|The prompt wording stops mixing the Groceries tap-strike with Pantry.|Product|

**Rule all as default? Batch 5 (19 calls): YES / NO** (1 conflict row takes the ruling-consistent default shown; 1 row marked "no default" needs an answer, not a yes).

## Batch 6: Pantry: first use; Home, Settings, Review (28 calls)

### Pantry first use and backfill

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G204|Important|Should the Pantry backfill write "in" for a basket that was only put away for Later?|Leave put-away baskets out of the backfill (they were always "maybe"); add test aBasketInLaterIsNotBackfilled.|Later baskets never appear as "in" on day one.|Product, with Core engine|
|G205|Low|If he goes back a build and the new store is refused, what should the restore line say?|The restore line names what comes back ("Pantry as it stood on the copy's day") and says that states he told it since then are not in the copy.|He knows what a rollback costs before he confirms.|Builder B|
|G206|Low|Is the iCloud folder copy a full backup (keeps Pantry state) or a leaving-the-phone copy (drops it)?|**RULED (Core, Oct 18 7:15 AM):** leaving-the-phone copy; drops Pantry state like the shared export; the local backup keeps everything. Core adds the Pantry exclusion to the iCloud writer, with a test, in the catalog-bump PR.|Nothing leaks today (Pantry fields do not exist yet).|Core|
|G207|Important|After his first big shop, what should the Pantry page say when nothing is out?|**DESIGN PICK (Oct 18 7:16 AM):** (a). The hero reads "Nothing out" (sheet 78's quiet form), the USUALLY HAVE line shows what is known, and no second line or count is added; a count of what is "in" stays out.|Quiet page, no sums.|Product, with Builder B|
|G208|Important|When should the page teach "out of milk"?|Show the line once per install on the first Pantry open after the backfill (or the first time OUT is empty); gate the text on the grammar test outOfMilkSetsOutAndAddsARow passing in the same build.|The teaching line appears once, and only when the phrase really works.|Builder B, with Product|
|G209|Important|How many known ingredients should CAN COOK need before it stops being grey?|**RULED (Core, Oct 18 7:15 AM):** grey until at least 60% of a recipe's non-staple lines are known, floor of 3 lines; a recipe below the bar is listed after the judged ones as "N to check". Core adds it to PantryBook.canCook on core/pantry-1, with tests.|CAN COOK is not confident on almost no knowledge.|Core|
|G210|Important|Should a first cook on an empty Pantry mark unknown ingredients OUT or LOW?|Confirm the rule as ruled (a cook marks non-staple lines low or out; unknown counts toward the drop, R5, Oct 17 4:30 PM), the hunt's first option. The alternative (low only when the prior state is "in") would change a ruled rule.|First-week Pantry is mostly guesses, and he can correct any line.|Product|
|G211|Low|Should there be a way to set an ingredient back to "unknown"?|A long-press clears to unknown (writes nothing for hasAnyState); the ruled tap cycle in, low, out, in is unchanged. Hunt's first option; the other is a fourth tap step.|A wrong guess can be undone to "I don't know".|Product|
|G212|Low|Should the same last-cook Tess line repeat on every Pantry open?|Say it once per cook, or only on the first open after the cook.|The line is news once, not wallpaper.|Builder B|
|G213|Important|Must the new Pantry phrase and backfill write masked summaries?|Yes, as a requirement on the new ops: masked summaries at the source (thing first, "Private item" for a walled name); the backfill reads "Set up Pantry" with no names; tests pantryOpSummariesAreMasked and a backfill-summary test.|New Pantry ops never leak a private name into history.|Core engine|
|G214|Low|What should the greyed CAN COOK sentence say until Pantry knows something?|Recipes wording: "CAN COOK fills in once Pantry knows a few things"; the information line yields to an open UNDO, as Pantry's does.|The sentence points at something real.|Builder B, with Product (wording)|
|G215|Low|Should demo reset run the Pantry backfill once, not every time?|The backfill honors -demo: it runs once after -resetDemo, and a test says so.|Demo data stays stable between runs.|Core engine|
|G216|Low|Should the finish-shop undo test be renamed and made to prove all three assertions?|Rename the test and add finishShopUndoRestoresStateStateAtAndLastBoughtAt (walk PE20 already requires the three assertions).|The test name says what it checks.|Core engine|

### Home, Settings and Review

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G267|Important|Should proposed plan rows stop redrawing at 30 fps in Low Power?|Under Low Power or Reduce Motion the words sit still at a fixed breath; in normal power drive the breath with one repeating opacity animation, or stop it after a few cycles.|Home, Now and Training stop burning power on a waiting row.|Builder A, with Builder B|
|G270|Low|Should every raw withAnimation call go through the app's motion rules?|Route each through withTesseraAnimation or .tesseraAnimation; delete the dead ternary so the one reduced number is 150 ms.|Every animation obeys Reduce Motion and Low Power.|Builder B|
|G276|Important|When a Settings line vanishes under VoiceOver focus, where should focus go?|Announce each line once (G251 helper); on removal move focus to the element that now holds the answer (the Rest day word after a pick, the "Add a Claude key" word after a remove, the line itself after a check); needs the focus helper from G255.|VoiceOver focus is never lost on Settings.|Builder A, with Builder B|
|G278|Important|Should Settings rows stack at the biggest text sizes?|Stack rows at accessibility sizes (ViewThatFits with a vertical last option), add a third rest-day layout of two words per row, let the rail drop to a vertical list or a smaller label scale; add four rows to the AX5 render set.|Settings is usable at AX5.|Builder B|
|G279|Low|Should each Settings sentence be one VoiceOver element?|Group each sentence as one element with the value as its adjustable or button child, hide separators, add the toggle trait to the switch (value yes or no) and "selected" to the current day; label the day words as days and "Any day".|Settings reads as sentences, not fragments.|Builder B|
|G280|Important|Should VoiceOver hide the pager pages that are off screen?|Hide non-current pages from VoiceOver; move between them with the rail words and a scroll action; announce the page ("Training") on change; give the rail a group label ("Pages") and each word a position.|VoiceOver stays on the page he is on.|Builder B|
|G281|Important|Should "Done. Next one is up." name the thing?|Say "<title>, done. Next one is up." (masked through G275) so the same string drives the receipt, the key label and the answer ("<title>, taken back.").|Receipts follow the thing-first rule.|Builder B|
|G282|Low|Should the paused-context line be read in words?|Give it a spoken label that expands units ("paused 21 minutes ago", "2 hours ago"); drawn text stays inside the 32-character cap.|VoiceOver stops saying "min" and "h".|Builder B|
|G283|Low|Should the training lane be read in sentences, not "4x8"?|Spoken form from the numbers ("Bench, 4 sets of 8, 82.5 kilograms"); scale the target with the name, let the name wrap and the row grow.|The lane makes sense to VoiceOver and at large sizes.|Builder B|
|G284|Low|Should the Start key use the routine's words as written?|Use the word as written; add the header trait to the hero; add the time left as the Finish key's value.|Routine names are not recapitalized.|Builder B|
|G285|Low|Should the queue window stop being a fixed 156 pt at accessibility sizes?|At accessibility sizes drop the fixed window and the fade and lay the rows out in the page's own scroll.|Queue rows are not clipped by large text.|Builder B|
|G286|Low|Should the Home day pick say which day is open?|Mark the open day selected, announce the new hero ("Tuesday, 1 session"), and let the two-finger scrub (escape) return to the week.|VoiceOver users can tell which day is open.|Builder B|
|G287|Low|Should Review lines be read with full weekdays and units?|A spoken label per row: full weekday, then "Bench, 85 kilograms for 8, a best".|Review is readable aloud.|Builder B|
|G288|Low|Should the two old clock-in-words helpers be deleted or moved to the house clock?|Delete contextLine and the two clock helpers with their tests, or turn them into HouseTime.clock and update the expectations.|One clock form in the app.|Builder B|
|G315|Important|Should the Review page build the week once instead of on every redraw?|Compute once per model revision and week, hold it in @State or a small cache keyed like firstUseCache; no wording changes.|Review scrolls and opens faster.|Builder B, with Core engine|

**Rule all as default? Batch 6 (28 calls): YES / NO** (3 rows marked "no default" need an answer, not a yes).

## Batch 7: Settings, Backups; Money, Reading, Notes (22 calls)

### Settings and Backups

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G359|Important|Should the daily backup skip work it has already done today to save power?|Remember the last good day per place in UserDefaults and skip the whole call when the day is done; the late tail uses ">" not ">="; run off the main actor inside a background-task assertion; in Low Power the first daily copy still runs (the safety copy), late-tail refreshes and the folder re-check wait for the next open with power ok; add tests.|Backups cost almost no power after the first one of the day.|Core engine, with Builder A|
|G360|Important|Should the Backups page load its disk facts once, not on every redraw?|Load once in .task into @State (latest, count, failures, folder, "has any history") and refresh only after a pick, forget, restore stage or cancel, or a saved copy; inspect stays out of the render path.|The Backups page stops reading files while scrolling.|Builder B, with Core engine|
|G365|Important|Should Settings say that Tess waits in Low Power Mode?|Add one clause to the yes answer once the automatic jobs exist: "She waits in Low Power Mode." Edit HS12 and G603 to the ruling; the receipts page says nothing for a skip. Matches Oct 17 9:28 PM ruling (Home's automatic call waits in Low Power).|He learns why a job did not run.|Research, with Design and Builder B|
|G367|Low|Should the export file be built off the main screen, with a plain line while it works?|Build the export off the main actor from a snapshot, show one plain line while it works ("Making the file.") and a thing-first result ("Export, saved."), keep the mask in Core; test on the 5-year store.|Export never freezes the app.|Core engine, with Builder B|
|G371|Important|Should choosing a backup folder have an UNDO?|Pick, change and stop-using are one write each with a 10 s UNDO restoring the previous bookmark ("Backup folder, iCloud Drive/Tessera. One copy a day."; "Backup folder, changed to Home/Backups."; "Backup folder, stopped. Copies stay on this iPhone."); remove the local Undo word and timer; a line never repeats a path beyond its last two parts. Matches Oct 17 9:28 PM ruling (folder choice moves into the one slot).|A wrong folder pick is one tap to fix.|Builder B, with Core engine|
|G372|Low|Should backup receipts lead with the thing, not the verb?|Thing first: "Copy, saved.", "Restore, cancelled. Nothing will be replaced.", "Copy, not made. Try again.", "Restore, waiting. What's here now is kept in Backups."; VoiceOver alone hears "Copy, not saved." for a decline (Product confirms); plain, no UNDO.|Backups speaks like the rest of Tess.|Builder B, with Product|
|G373|Important|What should VoiceOver's double tap do on Restore?|**CONFLICTS with Oct 17 11:04 PM ruling** (Restore is a hold key; the named action is "Restore"). Hunt names the action "Replace everything". Ruling-consistent default: named action "Restore" only, no default double-tap completion; announce once "Restore, waiting. The copy from Oct 14 replaces everything next time Tessera opens."; move focus to the "A restore is waiting" title; keep "Cancel restore" reachable; the line sits on the shared Tess line above the keys.|A restore can never complete by accident with VoiceOver.|Builder A, with Builder B|
|G374|Low|Should the before-update copy be named by his 4 AM day and spoken in full?|Name the saved file by TesseraDay (as the rolling name); one day-format function for Backups, Receipts and the restore question ("Oct 14" short, "Tuesday, Oct 14" in the question); VoiceOver reads the full weekday.|Copy names follow his day, not midnight.|Core engine, with Builder B|
|G376|Important|Should receipt rows in Settings start with the thing, not the clock?|Row label thing first: "Plan my day, Thu Oct 16, 12 pm, 1.2 cents." and "Key check, ..., free."; the dots are hidden from VoiceOver; the model name stays drawn.|Receipts read like the rest of Tess.|Builder B|
|G381|Low|Should Put-away rows be read with full weekdays?|accessibilityLabel per row: the title (masked), then the full weekday or "today"; the drawn column keeps its abbreviation.|VoiceOver stops saying "Wed".|Builder B|

### Money, Reading and Notes

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G289|Important|Should opening a note use a plain crossfade in Reduce Motion and Low Power?|Give the Notes push the ArrivalTransition shape fed by the one shared flag; with the flag on, the destination is a 150 ms crossfade, not a zoom; one test.|Notes obeys Reduce Motion and Low Power.|Builder B, with Builder A|
|G290|Important|Should the Notes list stop replaying its entrance every time it opens?|Under the flag the entrance is opacity only and a new row is a 150 ms fade; do not force animateEntrance on a revisit; route the row transition through the policy.|The Notes list is calm on every open.|Builder B, with Builder A|
|G296|Important|Should a note's Links section show "Private item" instead of private titles?|Show ObjectPrivacy.label(of:) where it returns one (as ObjectPage does); make each Links row a button that opens the object, labelled "Link, <name>".|No private title shows under a note.|Builder B|
|G300|Important|Should a note row be read aloud with a natural time ("1 hour ago", "yesterday")?|Give the combined row a spoken label via when(_, spoken: true); round hours to nearest and say "1 hour ago"; weekday from TesseraDay; test the three words.|VoiceOver hears normal times.|Builder B, with Core engine|
|G301|Important|Should a note row fit at the biggest text sizes?|At accessibility sizes drop the one-line limits (three for the title) and stack the time under the text; add the Notes row to the AX5 render set.|Note rows stay readable at AX5.|Builder B|
|G304|Important|Should Reading Finish and Delete spend be reachable by name only for VoiceOver?|Finish: named action "Finish <title>" only, no default double-tap completion (the G229 fix, applied when the key is built; Oct 17 9:29 PM limits the rule to hold keys). Delete spend: named action "Delete <amount word>" on the row and the page, 10 s UNDO ("12.40 lunch is back."). Set aside: one word, a plain button.|No Reading or Money change happens by an accidental double tap.|Builder A, with Builder B|
|G305|Important|Can the Money and Reading drums be used with VoiceOver?|Drums expose label, value ("page 142 of 612", "12 dollars 40") and an adjustable action that steps by 1, with a larger step by rotor; write this into both steers; focus moves on open. (Alternative in the hunt: VoiceOver lands on the typed field and the drum is the sighted alternative.)|A blind user can set a page or an amount in a few swipes.|Builder B, with Product (steer text)|
|G307|Low|Should Money and Reading lines be read in words ("page 142 of 612")?|Give each line a spoken label: "page 142 of 612, started 9 days ago", "groceries, 312 dollars 40"; "p 142" stays the drawn form only.|VoiceOver speaks sentences.|Builder B|
|G308|Important|How long should the Money capture UNDO last under VoiceOver?|Keep the 2 s drying for sighted use only; under VoiceOver the ghost waits for a tap or action and the UNDO is a flat 10 s through the one slot; each list says which action is new (4 s) and which is a change (10 s: SetBookPage, EditSpend). Matches Oct 16 1:35 PM ruling.|UNDO is reachable for a VoiceOver user.|Builder B, with Core engine|
|G309|Important|Should skipping the Groceries total be undoable and named?|Skip gets a 10 s UNDO ("Groceries total, skipped." then "Groceries total is back."); the control is named "Skip the Groceries total"; "asked once" holds for a skip that is not undone.|A mistaken skip can be taken back.|Core engine, with Builder B|
|G310|Important|How should the Money ledger and Reading shelf lay out at the biggest text sizes?|One column at accessibility sizes: the numeral on its own line above the amount and word, the page under the title; each ledger line is one element ("Oct 15, lunch, 12 dollars 40").|Both pages work at AX5.|Builder B, with Product (steer text)|
|G311|Low|Should resuming a book say something?|On resume, move focus to the page value and announce "Dune, page 142" once (G251 helper).|VoiceOver users know the resume worked.|Builder B|

**Rule all as default? Batch 7 (22 calls): YES / NO** (1 conflict row takes the ruling-consistent default shown).

## Batch 8: Day screens; Widgets, Activities, Intents (22 calls)

### Plan my day, Day log, Shutdown, Habits

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G319|Important|After taking back a plan row, should Tess say what was taken back?|In both closures call TessVoice.shared.say("<title>, taken back.") and say("Plan, taken back."), or have the UNDO handler fall back to UndoCopy.takenBack(after:); label the UNDO key "Undo <thing>".|Plan UNDO is never silent.|Builder B|
|G320|Important|Once a plan row is kept, should it stop saying "Proposed" and stop offering Skip?|When kept: label "<title>, <time>, kept" with no "Proposed" and no hint, only an Undo route through the shared slot; drop the Keep and Skip actions; in skip, guard that the row is not kept.|A kept row is plainly kept.|Builder B|
|G327|Important|Should the Day log be read with spoken times instead of "07:10"?|Give each row accessibilityLabel(line.spoken(calendar)) and hide the drawn lead and text from VoiceOver; keep the 24 h column on screen; Research edits DL18 and DL38 to say "best".|VoiceOver speaks "7:10 am", not "07:10".|Builder B, with Research|
|G328|Low|Should only openable Day log rows act like buttons?|Button trait and hint only on rows with an objectID; plain text for the rest; the opened page's back word names Review.|VoiceOver stops promising actions that do nothing.|Builder B|
|G329|Important|Should the Day log mask every kind of private title, not just cooks and recipes?|Route every kind through one function in title(of:): tasks and notes via ObjectPrivacy.label(of:), lists via ListContents.shownName, workouts and routines via routineTitle; bare words stay unmasked (G257); one test per line shape. This is the Core half of G274 and G275.|No private title in the Day log, whatever it is.|Core engine|
|G330|Low|Should Day log bands grow at the biggest text sizes?|Let the band grow: a minimum height, or stack the label over the figure at accessibility sizes; add the three bands to the AX5 render set.|Day log bands are readable at AX5.|Builder B|
|G331|Important|How should VoiceOver hear a Shutdown row move to tomorrow?|Add a VoiceOver column to the flow table: the flip is announced "<thing>, later" (a change, 10 s UNDO "<thing>, taken back"), the count label is a header, "N more" is a button with a "Show N more" action, the ask is one element with two actions and focus returns to the key after it, the closed hero reads as Home's does; habit names follow G334.|Shutdown is usable without sight.|Design, with Research and Builder B|
|G332|Low|Should Shutdown have a large-text layout?|Add the AX layout: the value drops under the title, "5 MORE" counts rows that wrap, the close key stays above the keyboard; render at AX5 before sign-off.|Shutdown is usable at AX5.|Design, with Builder B|
|G333|Important|Should habit rows have spoken labels, hints and sentences?|Add each form to HabitsCopy with a test, from the Research rows (no new wording): the block, the dab, the paused count, the weekday list, the UNDO label, the already-in line; Tess's check-in line is also announced (G251).|Habits can be used by VoiceOver.|Builder B, with Core engine and Research|
|G335|Low|Should wall words match whole words only, so "Mission prep" is not blocked?|Match whole words (a word boundary), keep "missed" and "miss" as words, and add a test with a habit named "Mission prep".|A habit name containing "miss" is not walled by accident.|Core engine|

### Widgets, Live Activities, Siri

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G337|Important|Should a Siri set log refresh the Live Activity?|Post one refresh after every intent write that touches an open workout (the same notification, or rename it tesseraWorkoutChangedOutside), and have the app answer with refreshAfterExternalWrite() and an Activity update; test LogNextSetIntent during a rest.|The Lock Screen card stays right after a Siri set.|Core engine, with Builder A|
|G339|Low|Should the rest "Go" push and digits obey Low Power?|Add a two-line Shared/ReducedMotion helper (Reduce Motion from the environment, Low Power from ProcessInfo, read each time the view is built) and use it for the Go swap (crossfade) and the digits (no roll); same flag for every future widget.|The rest card is calm in Low Power.|Builder A|
|G343|Important|Should the compact and minimal Island presentations have a VoiceOver label?|Label each as one element: "Rest, 42 seconds left" while resting (timer text, not a stale label), "Go, Bench, set 4" when ready, "Push A, set aside" (or "Private workout, set aside") when stale; keep the tick hidden.|The Island is not silent to VoiceOver.|Builder A|
|G344|Important|Should the Lock Screen card read the thing first, not the countdown?|Thing first in one header element: "Bench, set 4. Resting, 1 minute 32 left." (or "Bench, set 4. Go."), then the Done button, then the keys; "Ready at" and the clock read as one element ("Ready at 6:12 pm"); same order on the expanded Island.|The card makes sense when read aloud.|Builder A, with Design|
|G345|Important|Should the Lock Screen keys be named, and the dead "+15" hidden?|Label them with the intent titles: "Add 15 seconds", "Skip rest", "Skip set"; hide the dead "+15" from VoiceOver; set label "Bench, set 4, 82.5 kilograms, 8 reps, log"; carry G242's contrast fix.|Every key says what it does.|Builder A|
|G347|Important|Should the Live Activity scale with Dynamic Type?|Use scalable fonts (relative to a text style) and give the Lock Screen a second layout from accessibility sizes up (the planned set under the countdown, keys in a row below, scale factor only as a last resort); render AX3 and AX5 in Obsidian and the Cobalt sky face.|The card is readable at large text.|Builder A, with Design|
|G350|Important|Should Siri read friendly receipts instead of raw Day log text?|Add a spoken receipt to LogExercise, LogNextSet and a plain CreateTask, and have the three intents prefer receipt(in:) over summary: "Bench, 1 x 8 at 80. Added to today.", "Set 4. 82.5 x 8.", "Dentist, in Later." or "Dentist, Thursday 3 pm.", finish "Push A finished. 6 of 6 exercises, 22 sets." Research owns the wording; this is the code half.|Siri answers sound like Tess, not like a log.|Core engine, with Research|
|G351|Low|Should Siri say "1 exercise", not "1 exercises"?|Pluralize through the shared count helper; fold into G350's wording; the routine title is masked by the G192 fix.|No plural slips in Siri lines.|Core engine|
|G355|Low|Should widget and lock-line specs use 12-hour clocks like the app?|Edit widget-states.md and lockscreen-lines.md to "7:30 am", "6:30 pm", "Re-sign by Thu, 6:10 pm" and the VoiceOver labels in the same form; one HouseClock for the app, the extension and the widgets.|Widgets show times the way the app does.|Research|
|G356|Important|What VoiceOver and large-text rules should the Home widgets follow?|Add a VoiceOver and Dynamic Type column to widget-states.md: each state's label thing first ("Bench, set 4 of 5. Resting, 1 minute 32 left."), one element per widget, system timer text for the count, small widgets truncate to the hero at AX3 and say "More in Tessera" as the tap, StandBy shows the hero only at full contrast; no wash (widget washes were withdrawn Oct 18 1:34 AM).|Widgets are accessible and match the app.|Design, with Research and Builder A|
|G357|Low|Should Shortcuts rows be worded for the ear and stop saying "x"?|Rename the short titles to match, add a requestValueDialog per required parameter in Tess's words ("Which exercise?", "What weight?"), word the summary for the ear ("Log 3 sets of 8 Bench Press at 80 kg"); the unit follows the settings unit when one lands.|Shortcuts and Siri prompts read naturally.|Core engine|
|G358|Low|Which Face ID rule is the right one for the workout Siri keys?|Mark widgets-and-snippets.md:19 superseded by the Oct 16 2:08 PM and Oct 17 10:47 PM rulings and write the one rule: the workout's Done, +15 and Skip run unlocked (a set is not a private fact); writes that create or say anything of his words need Face ID.|Research doc agrees with the ruling.|Research|

**Rule all as default? Batch 8 (22 calls): YES / NO**.

## Batch 9: Plans, Routines, Exercise (16 calls)

### Plans, Routines, Exercise

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G382|Important|Should swiping between week and month stop rebuilding all plan data every frame?|Build the plan read once per store revision (a cached value on the model, or @State refreshed on revision change), keep swipe progress in the rail view as ExerciseViews does; test on the 5-year store that a full swipe builds PlanData zero times.|The week/month swipe stays smooth with years of history.|Builder A, with Core engine|
|G383|Important|Should the Trend wet tip stop animating forever, and sit still in Low Power?|In Low Power or Reduce Motion the tip sits still at 0.75 opacity with no loop; otherwise stop the loop when the page disappears; test trendTipDoesNotBreatheInLowPower.|No hidden animation drains the battery under a pushed page.|Builder A|
|G384|Important|Should exercise page zooms use the Low Power crossfade?|Add the three sources (history, muscle, path) to the same test as PL13 through the one Low Power input; the path buttons' ".up" relation takes the reduced branch.|Exercise pages obey Low Power like the rest.|Builder A|
|G386|Low|Should the exercise rail tick when the page changes by itself on open?|**CONFLICTS with Oct 17 3:55 PM ruling** (R2: no haptic on a user page turn; also Oct 17 5:30 PM). Hunt fires the tick from selection and a settled swipe. Ruling-consistent default: no tick on any page turn and none on appear; remove the raw selection haptic; test that opening an exercise on a remembered sibling plays no haptic.|The rail is silent to touch, as other page words are.|Builder A|
|G387|Low|Should the day-word stagger and press fade follow the app's motion rules?|Route all five through tesseraAnimation and drop the offsets from the two transitions in the reduced branch; a source scan finds no raw animation in Plans or Exercise.|Plans and Exercise obey Reduce Motion and Low Power.|Builder A|
|G390|Important|Should "Add to routine" say what it added and offer UNDO?|Same receipt as the editor, thing first: "Bench press, added to Push A." through the shared Tess line, UNDO 4 s for a new thing (10 s under VoiceOver), .made through tesseraFeedback, routine name through the mask (G389), announced once; menu items speak "Push A, 5 exercises". Tests addToRoutineSaysWhatWasAdded and addToRoutineOffersUndo.|Adding to a routine is no longer silent.|Builder A, with Builder B|
|G392|Low|Should the same movement arrive with the same sets and reps from every door?|One place for slot defaults (the class's rep range, 3 sets), used by both doors, ideally inside AddSlot so Siri and Tess get it too; test addSlotFromExercisePageUsesTheClassRepRange.|Same movement, same defaults, wherever it comes from.|Core engine, with Builder A|
|G393|Important|If a plan write fails, should Tess say so and buzz once?|One failure path for the routine screens: .notSaved once and "Didn't save that. Try again." through the shared voice, announced once, control left where it was; tests for make, drop, move, step, day and add. Matches Oct 17 7:39 PM ruling D3.|A failed plan write is never silent.|Builder A, with Builder B|
|G395|Important|Should days with nothing to open stop reading "dimmed" to VoiceOver?|Days with nothing to open are static text, not buttons and not disabled ("Friday, Pull A, planned"); only done days and today are buttons; test restAndPlannedDaysAreNotDimmedButtons.|VoiceOver reads the week plainly.|Builder A|
|G396|Low|Should VoiceOver announce moving between week and month?|Each page a container with its name ("Week", "Month"); the rail words get the hint "Shows the month"; the same two lines in the shared rail fix the exercise page.|Page changes are announced.|Builder A|
|G399|Important|Should routine reorder work at the biggest text sizes?|Measure each row (as QueueWindow does with onGeometryChange) or compute the target from measured frames; test reorderTargetFollowsMeasuredRowsAtAX3.|Reordering lands where he drops it at AX3.|Builder A|
|G400|Important|Should plan controls re-flow at the biggest text sizes?|At accessibility sizes: the day picker becomes seven rows of at least 44 pt, mode words and slot actions stack, the step line puts its label above its keys, the week page shows day names in full; tests routineEditorLayoutAtAX5ClipsNothing and routinesPageModeWordsStackAtAX5.|Plan screens work at AX5.|Builder A, with Design|
|G402|Important|Should routine editor buttons say which exercise they act on?|Labels "Move Bench press earlier", "Move Bench press later", "Swap Bench press", "Take Bench press out"; after Take out focus goes to the next slot or "Add an exercise"; after a choice focus lands on the new slot; the arrow is hidden; the title is a header; an empty routine says "No exercises yet."; tests slotActionsNameTheExercise and focusMovesAfterTakeOut.|The editor is usable with VoiceOver.|Builder A|
|G403|Low|Should a routine row be read in full words?|Row label "Push A, next, Monday and Thursday, 5 exercises, about 40 minutes"; hint "Opens it"; drawn text keeps abbreviations.|Routine rows speak sentences.|Builder A|
|G404|Low|Should exercise history show full dates, with the year when it is not this year?|Spoken date "Monday, Oct 12"; add the year to any date outside this year, drawn and spoken ("Sep 27, 2025"); test historyDateCarriesTheYearWhenNotThisYear.|Old history entries are unambiguous.|Builder A|
|G405|Low|Should weights in exercise and rep-max pages follow the unit setting, not fixed kilograms?|One spoken-mass helper that follows Format.unit, numbers through Format.mass, set counts through a plain number formatter; pin it before the setting lands.|Pounds users are not told kilograms later.|Builder A|

**Rule all as default? Batch 9 (16 calls): YES / NO** (1 conflict row takes the ruling-consistent default shown).

## Batch 10: Ask slot, Speak, capture; launch (19 calls)

### Ask slot, Speak, capture

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G76|Important|Should Tess's memory turnover stop a medicine name slipping into a memory line?|**CONFLICTS with Oct 17 4:22 PM ruling** ("memory keeps its own wall"). Hunt swaps the guard for ObjectPrivacy.isPrivateWord (the one function). Ruling-consistent default: keep memory's own wall and add the missing health check (EngineWall.isHealth) inside it, with no title-word widening.|"New list: Lexapro refills" can no longer reach a memory line or Home's pack.|Core engine|
|G313|Important|Should the mic bloom and heard words be calm in Low Power?|Read the one shared reduced flag (Reduce Motion or Low Power): the bloom is a still mark at 1.2x, words fade by crossfade, and the level is not fed while the flag is on; his listen, the pause end and the 60 s cap are unchanged.|Speak is calm and cheap in Low Power.|Builder B, with Builder A|
|G314|Low|Should the Write and Speak dry-line timings shorten in Low Power?|**CONFLICTS with Oct 17 9:34 PM ruling** (the Speak dry window in Low Power stays 3 s with a stepped drain; Reduce Motion is 0.8 s). Hunt makes one flag pick 0.8 s and 0.6 s. Ruling-consistent default: Reduce Motion picks the short forms (0.8 s Speak, 0.6 s Write); Low Power keeps 3 s with a stepped drain; the drain goes through withTesseraAnimation; touch cancels, the line empties, then it commits.|Capture is not delayed or hurried differently from the ruling.|Builder B|
|G326|Low|Should the hold-refusal line read "Open Settings" as a control?|In the hold path show the same refusal with its button (or open the layer once as 8a does); say "Open Settings" as a control and "Write" for the other two; build 12b's state labels.|The refusal tells him what to press.|Builder B|
|G428|Low|When the first-send notice and the receipt both want the Ask line, which shows?|Two lines in the one slot, in order: the receipt first, the notice second (or the notice appended to the receipt); one claim, one UNDO. Fits Oct 18 1:20 AM ruling (notice shows on send).|The receipt is never overwritten by the notice.|Core engine, with Builder B|
|G431|Important|Should a Siri question leave the Ask line open?|Siri phrases (commitImmediately) never store an ask, or the engine clears it when the context changes; Siri speaks the question and drops it.|Siri leaves no stuck question in the app.|Core engine|
|G436|Important|Should undoing a capture replace the old receipt with a proper taken-back line?|Same answer for both branches: the decrease haptic, "Tacos, taken back." (thing first, masked), one high-priority announcement, and the old line replaced.|No stale receipt after UNDO.|Builder B|
|G437|Important|Should the open Ask slot hide the page behind it from VoiceOver?|Mark the open slot modal, add an escape action that closes it, label the soul "Close Tess" while open, move focus to the question on open (Design confirms the order: question, Speak, Write, Show).|VoiceOver stays inside the open Ask slot.|Design, with Builder B|
|G439|Important|Should lift-ask answers stack and be readable at large text sizes?|Stack the question over its answers at large sizes (a vertical group with 44 pt answers), no scale-down; spoken labels "2 sets" and "2 kilograms".|Answers to "10 sets or +10 kg?" are not cut off.|Builder B|
|G440|Low|Should the "Show" mode button stay if it does nothing?|Hide the Show row until it ships (the hunt's first option; the other is to give it its one real job).|No button that does nothing.|Product, with Builder B|
|G441|Low|Should typing "undo" undo, as saying it does?|Share one check for "undo" across Write and Speak.|Typed and spoken "undo" behave the same.|Builder B|
|G448|Important|Should refusing the mic stop touching the audio input unsafely?|stopAudio touches the node only if a tap was installed; check sample rate above zero and the channel count before installing the tap; both failures map to .busy.|No crash on a refused or busy mic.|Builder B|
|G449|Important|After he fixes mic or speech permission in iOS Settings, should Speak notice?|Re-read both permissions when the scene becomes active and clear the refusal if they pass; a limited refusal leaves Write only; use micDenied to grey the Speak word; say "Mic is on." once (6c).|Fixing the permission just works.|Builder B|
|G450|Low|Should the Speak refusal line be grouped and not squeezed at large text?|Stack at accessibility sizes; group the line with its word ("Mic is off for Tessera. Open Settings, button"); announce once.|The refusal is readable and one VoiceOver element.|Design, with Builder B|

### First launch and data open

|Id|Sev|Question|MY DEFAULT|If the default stands|Owner|
|---|---|---|---|---|---|
|G442|Important|If setup fails on first launch, should the app say so and retry?|Set a launch note on a failed seed ("Couldn't set up your exercises. Close and reopen the app.") and let the next launch retry (cheap after the first run).|An empty app is explained instead of silent.|Core engine, with Builder B|
|G443|Important|Should the "Not saving this time" warning stay for the whole session?|A plain "Not saving this time." line on Home for the whole session (and the Review header), cleared only by a good launch.|He cannot lose a session of work unknowingly.|Builder B, with Product|
|G444|Low|Should launch notes be worded for the next launch and fit three lines?|Notes are worded for the next launch ("Last time your data couldn't open. It's safe."), the instruction comes first, they fit three lines, announced once.|Old or cut launch notes stop confusing him.|Core engine, with Design|
|G445|Important|Should the old-store move run behind the first frame and stop retrying forever?|Move it behind the first frame, log every failure, set the note for the open failure too, and stop retrying after a counted number of launches.|First frame is no longer blocked by the legacy store move.|Core engine|
|G446|Low|Should the first-launch rest-day receipt hold 4 s at any hour?|Use the shared hold helper; outside 07:00 to 23:00 keep it for the next open.|No receipt appears at 3 am.|Builder B|

**Rule all as default? Batch 10 (19 calls): YES / NO** (2 conflict rows take the ruling-consistent default shown).

## Rows needing more than a yes

**Conflicts (9):** G452, G454, G94, G122, G142, G373, G386, G76, G314.

**No default (5):** G422, G145, G206, G207, G209. Needing Design: G145, G207, G422. Needing Core: G206, G209.

**Hunt rows not found:** none missing in hunts 10 to 27. G407 and G409 sit in checklist rows X1 and X3 of hunt 24, and G422 in row B6 of hunt 25 (no Fix column there; the default is the row's own "how to check" and ownership text).
