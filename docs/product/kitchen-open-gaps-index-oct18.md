# Kitchen open-gaps index, Oct 18

One index of every Kitchen-lead gap with a G id in `docs/product/kitchen-gap-hunt-*.md` (hunts 2 to 27), so Core, Builder A and Builder B can pick work by owner. Docs only (checkout at master 892befd). Severity and owner are copied from the hunts; no new gaps; summaries are 15 words or fewer.

**Status.** RULED = the hunt's own "Rulings in" block (or inline ruling) accepted a fix, or hunt 24 or 25 tags the row [RULED]. CALL = PRODUCT CALL (open): no accepted ruling is recorded in the hunt; it covers plain builds too. CLOSED = CLOSED IN CODE (none: see below). HIST = HISTORY: hunts 2 to 9, early board rounds, not re-graded (code status of G1 to G39 is in `kitchen-gap-status-oct17.md`).

**CLOSED IN CODE: none.** Hunts 13, 14 and 24 say G139, G181, G182, G184 are fixed on branches (#912, core/g105b) pending merge. git grep on this checkout: `titleShown` is still in RecipePage.swift, `revealed` and "Shows it" in ShopTrip.swift and GroceriesView.swift, `pantryPrivate` nowhere, 0xA4601A in PantryColour.swift. Those rows stay RULED.

**Owner codes** (the "With" column): C Core engine, A Builder A, B Builder B, K Kitchen lead, P Product, D Design, R Research, O Ops/QA. A row sits under the first owner the hunt names, sorted blocker first. Sev: B blocker, I important, L low, - none given. Severity qualifiers (inferred, spec) are dropped; the tier is kept.

## Totals

| Hunt | Ids | Gaps | Block | Imp | Low | None | RULED | CALL | HIST |
|---|---|---|---|---|---|---|---|---|---|
|2|G6-G11|6|0|0|0|6|1|0|5|
|3|G12-G18|7|0|0|0|7|0|0|7|
|4|G19-G25|7|0|0|0|7|0|0|7|
|5|G26-G33|8|0|0|0|8|3|0|5|
|6|G34-G39|6|0|0|0|6|3|0|3|
|7|G40-G50|11|0|0|0|11|0|0|11|
|8|G51-G61|11|0|0|0|11|5|0|6|
|9|G62-G72|11|1|7|3|0|0|0|11|
|10|G73-G92|20|2|9|9|0|0|20|0|
|11|G93-G108|16|0|8|8|0|2|14|0|
|12|G109-G122|14|0|9|5|0|0|14|0|
|13|G139-G152|14|1|3|10|0|1|13|0|
|14|G181-G195|15|4|7|4|0|8|7|0|
|15|G196-G216|21|2|11|8|0|4|17|0|
|16|G217-G243|27|1|17|9|0|12|15|0|
|17|G244-G266|23|1|12|10|0|5|18|0|
|18|G267-G288|22|2|10|10|0|8|14|0|
|19|G289-G311|23|3|17|3|0|11|12|0|
|20|G312-G335|24|1|16|7|0|10|14|0|
|21|G336-G358|23|1|16|6|0|10|13|0|
|22|G359-G381|23|1|17|5|0|12|11|0|
|23|G382-G405|24|1|13|10|0|8|16|0|
|24|G406-G410|5|0|0|0|5|3|2|0|
|25|G411-G422|12|1|0|0|11|11|1|0|
|26|G423-G441|19|2|12|5|0|12|7|0|
|27|G442-G460|19|2|11|6|0|2|17|0|
|All|||411|26|195|118|72|131|225|55|

Hunts 10 to 27 alone: 344 gaps. Per-hunt counts match each hunt's Counts table (hunt 13 has none; hunts 2 to 8 give no severity). Not in any hunt: G1 to G5, G123 to G138, G153 to G180.

| Owner | Gaps | Block | Imp | Low | None | RULED | CALL | HIST |
|---|---|---|---|---|---|---|---|---|
|Core engine|134|15|56|27|36|36|69|29|
|Builder A|54|1|35|13|5|20|30|4|
|Builder B|138|8|57|50|23|31|85|22|
|Kitchen lead|7|0|5|1|1|4|3|0|
|Product (rulings, specs)|46|2|25|18|1|22|24|0|
|Design|14|0|8|4|2|7|7|0|
|Research|13|0|9|4|0|7|6|0|
|Ops, QA, Mac leads, or no owner|5|0|0|1|4|4|1|0|

Hunts 10 to 27 only, by first-named Mac lead: Core 98, Builder A 50, Builder B 112.

## Before-build gates (blockers by feature)

All 26 blockers are placed below. Status in brackets: R = RULED, C = CALL, H = HIST.

**cookModeReady** (false at `Features/Recipes/RecipePage.swift:13`; the flip PR is G407 [C]). The only ruled gate is **G217** [R], no kitchen timer rings (Builder A, with Core). Hunt 24 adds slice rows (not blockers): G221, G222, G354, G218, G228, G229, G231 to G233, G235, G241, G242, G251, G258, G323, plus the Low Power and haptic rulings G219, G223 to G225, G247, G249, G385; and G410 [R] (Builder A owns the clock page). G193 (cook screen not built) is the unbuilt screen itself. Recipe-page blockers on the same flip: **G181, G182, G183** [R] (private recipe title and ingredient names), **G184** [R].

**Pantry v2 flip** (no code flag; 204 walk rows go green). Blockers: **G139** and **G184** [R] (private cook names in Pantry, fix on core/g105b, not on master), **G196** [R] (export leaks Pantry state), **G198** [R] (sticky private mask has no home), **G369** [C] (export never writes the masked flag; boarded for Core before the export row). Rows that gate it: G406 and G105 [R] (the one private-text function), G102 [R] (no reveal), G182 and G183 [R], G197 [R], G199 to G201 backfill [C], G203 [C], G409 [C] (walk appendix stale).

**Notifications G451 to G460** (zero `UNUserNotificationCenter` on master; hunt 27 makes them Core's build-gate list). Blocker: **G451** [R] (a timed-task notification would print a private task title on the Lock Screen). Open calls: G452 (training-only users never asked), G453 (Live Activities off, rest ends silent), G454 ("remind me Saturday" 9:00 vs no-time ruling), G455 (Sleep Focus holds the 5:30 am timer), G456 (denied/allowed route), G458 (no VoiceOver row); low: G457, G459, G460. Shared path: G217, G353, G336, G338 [R]. Also **G447** [R], first mic ask leaves the mic live (Speak, shipped code).

**Settings (sheet 93, Review foot, Backups, Health)**. Blockers: **G412** [R] (no `SettingsView`; Review foot SETTINGS word), **G272** [R] (Review, Settings, Backups covers draw no Tess line or UNDO; on the walk list), **G369** [C]. Needed with it: G411, G413 to G415, G421, G375, G377 to G380, G273, G277 [R]; G422 [C]. Habits and Shutdown: **G334** [R] (a habit has no mask), then G416 to G420.

**Private-text mask, other features.** G75 [C], G77 [C] (Lists copy), G274 [R] (Home), G295 [R], G299 [R] (Notes), G303 [R] (Spend, Book), G348 [R] (widgets), G389 [R] (routines). Core lands the one private-text function first (hunt 18 ruling).

**Other blockers.** G250 [R] (Lists and Groceries hide the Tess line and UNDO; inferred, walk list), G423 [R] (cook gate and 600-character cap not in code), G434 [R] (Ask slot line and UNDO read from two places), G62 [H] (hunt 9: huge size or time crashes the recipe page).


## Gaps by owner and severity

### Core engine (134)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G62|B|Huge size or time crashes the recipe page|HIST|B|
|G75|B|Day log prints a private list name raw|CALL||
|G77|B|Copy list accepts key-shaped, secret, money names|CALL|P|
|G139|B|Private cook lists real ingredient names in Pantry|RULED||
|G183|B|Private recipe ingredient rows print real names|RULED|B|
|G184|B|Private cook still lists real names in Pantry (G139)|RULED||
|G196|B|Export would leak Pantry state; R18 has no code|RULED||
|G198|B|Sticky private mask has no stored home|RULED||
|G274|B|Private routine or workout prints raw on Home|RULED|B|
|G295|B|Edited note skips the private check|RULED|B|
|G303|B|Spend and Book have no mask; amounts print raw|RULED|P,B|
|G369|B|Export masked flag never written; restore silent|CALL|B|
|G389|B|Private routine title shows on six more sites|RULED|A|
|G423|B|Cook gate and 600-char cap not in code|RULED||
|G451|B|Timed-task notification would print private title|RULED|P|
|G63|I|Link read errors give the wrong messages|HIST||
|G64|I|Kept link keeps fragment and query items|HIST||
|G66|I|Re-sending a recipe says "7 added" again|HIST|B|
|G73|I|Copy list has no phrase, line or screen|CALL|B|
|G74|I|Three starter lists never seeded|CALL|P|
|G76|I|Memory turnover lets a medicine name through|CALL||
|G84|I|Copy phrase goes whole to Claude, then fails|CALL|P|
|G87|I|Recipes never read the pantry|CALL||
|G88|I|Pantry ledger must move to Core first|CALL||
|G89|I|CAN COOK claims differ from what Pantry reads|CALL|P|
|G92|I|"Out of milk" rule has parsing holes|CALL|P|
|G93|I|Short rejected first line not kept as step 1|CALL||
|G96|I|Closing quote or emoji breaks the stop check|CALL||
|G98|I|Duplicate check misses trailing space or CRLF|CALL||
|G103|I|Object page prints raw Groceries titles|CALL|B|
|G104|I|Day log prints a private list name raw (see G75)|CALL||
|G109|I|"1-1/2 cups" read as a range|CALL||
|G112|I|"Pinch of", "a dash", number words unread|CALL|P|
|G113|I|"To taste" and "as needed" variants unflagged|CALL||
|G116|I|Compound amounts create junk ingredients|CALL|P|
|G117|I|Ounces never halve cleanly below 4 oz|CALL||
|G118|I|Half an onion scales up when recipe shrinks|CALL||
|G120|I|"Makes 24 cookies" meta lines unread|CALL||
|G121|I|Fraction and word durations unread|CALL||
|G140|I|Pantry skips the one widest private-text check|CALL||
|G141|I|Ingredient page prints raw title and class line|CALL|B|
|G142|I|Memory filter passes health or care titles|CALL||
|G187|I|Kitchen paths use different private-title checks|RULED||
|G188|I|Cook step text sits under a masked title on Now|CALL||
|G189|I|Timer labels stored and shown raw|CALL|P|
|G190|I|Finish line prints recipe title unmasked|CALL||
|G197|I|Masked private ingredient still exports its dates|RULED||
|G199|I|Backfill placement in launch order undecided|CALL||
|G200|I|Backfill is a bulk write, no UNDO or prior copy|CALL|B|
|G201|I|Backfill cost on years of history unmeasured|CALL||
|G203|I|Egg/Eggs fold: which object keeps the state|CALL||
|G213|I|New phrase and backfill ops need masked summaries|CALL||
|G221|I|Idle rule unbuilt; a cook never suspends|CALL|A|
|G292|I|Reading and Money slots: no end, no quiet hours|RULED|P|
|G293|I|Two Claude paths touch Money in Low Power|RULED|B,P|
|G309|I|Skip is irreversible and names no thing|CALL|B|
|G329|I|Day log leaves workout and other titles raw|CALL||
|G337|I|Siri set log tells the Live Activity nothing|CALL|A|
|G350|I|Siri reads Day log text aloud raw|CALL|R|
|G352|I|Face ID rule needs two intents|RULED|P|
|G353|I|Timer notification words conflict across fixtures|RULED|R,A|
|G359|I|Daily backup costs power on every background|CALL|A|
|G366|I|Overnight wrap-up lines land in quiet hours|RULED|B|
|G368|I|Export mask words miss newer private kinds|RULED|P|
|G424|I|Offline inbox never read; promise unkept|RULED|B|
|G426|I|"Sent to Claude" notice skipped on a miss|RULED||
|G427|I|Sent notice and receipt quote health titles|RULED|P|
|G431|I|Siri question leaves ask open, no screen|CALL||
|G442|I|Failed seed leaves app empty, no line|CALL|B|
|G445|I|Legacy store move blocks first frame, fails silently|CALL||
|G456|I|Notification permission flip has no route or re-read|CALL|B|
|G71|L|Link read drops a private title silently|HIST||
|G79|L|Now picker takes the raw list title|CALL||
|G82|L|Two privacy predicates for list names|CALL||
|G83|L|Copy drops item links and date|CALL|P|
|G86|L|Copy list test gaps|CALL||
|G97|L|Title rule is Latin-only|CALL||
|G100|L|Dead isPrivate flag on recipes|CALL||
|G106|L|Op summaries store raw titles|CALL||
|G107|L|Recipe-to-Groceries rows skip the Add-line wall|CALL||
|G110|L|Fraction, thousands, zero-denominator holes|CALL||
|G111|L|"2 or 3", em-dash ranges, inch sizes|CALL||
|G114|L|Pack lines lose size or are dropped|CALL||
|G119|L|Cups snap to quarters, losing thirds|CALL||
|G143|L|One swipe has two walls, two receipt sources|CALL||
|G191|L|Private finish receipt lacks the comma|CALL||
|G202|L|Backfill marker home unnamed|RULED||
|G215|L|Demo reset reruns the backfill|CALL||
|G216|L|Undo test name claims more than it asserts|CALL||
|G335|L|Wall words match by substring ("miss" in "mission")|CALL||
|G351|L|"1 exercises" plural slip in Siri lines|CALL||
|G357|L|Shortcuts row reads "x"; kilograms fixed|CALL||
|G367|L|Export builds the whole file on the main actor|CALL|B|
|G374|L|Before-update copy named by calendar day|CALL|B|
|G392|L|Same movement arrives with different ranges|CALL|A|
|G428|L|First-send notice overwrites the receipt|CALL|B|
|G432|L|Siri reads capture line aloud when locked|RULED|P|
|G444|L|Stale or cut launch notes in Ask line|CALL|D|
|G6|-|Built-in Groceries list can be deleted|HIST||
|G7|-|Deleting a recipe leaves its grocery rows|HIST||
|G8|-|Finish line ordinals wrong (21st, 22nd, 23rd)|HIST||
|G9|-|Timer over 24 h offered, then refused|HIST|B|
|G10|-|Key removal waits 10 s before Tess calls stop|HIST|B|
|G11|-|Rename onto an existing ingredient key|RULED||
|G16|-|List tool adds Groceries lines the plain way|HIST||
|G21|-|No way to mark a recipe Private|HIST|B|
|G22|-|Timer grammar accepts 25 hours, message unclear|HIST||
|G23|-|Cook month count uses calendar day, not 4 AM|HIST||
|G26|-|Restore confirm line hides what changes|HIST|B|
|G27|-|Stale cook survives a restore|HIST|B|
|G28|-|Backup and export show private words|RULED||
|G29|-|Groceries list after a restore|HIST||
|G31|-|Claude receipts miss the link read|HIST||
|G32|-|Link read ignores the Tess asks Claude switch|RULED||
|G34|-|Siri read-back of a private grocery|RULED||
|G35|-|Shortcuts description and prompt|HIST||
|G36|-|Export operation log carries private words|RULED||
|G37|-|Export carries deleted and shared ingredient names|RULED||
|G38|-|Masked export and restore warning|HIST|B|
|G40|-|List tool picks the wrong list by prefix|HIST|B|
|G41|-|Check and move receipts print raw item title|HIST||
|G42|-|Renaming a Groceries section breaks aisles|HIST||
|G44|-|A shop never goes idle|HIST|B|
|G45|-|Pantry cannot tell a remove from a clear|HIST||
|G46|-|Pantry loses what a deleted recipe cook used|HIST|B|
|G48|-|Pantry read walks every deleted child|HIST|B|
|G54|-|Link on the Paste screen is never read|HIST|B|
|G56|-|Cook key silently suspends a workout|RULED|B|
|G59|-|Title from first line; duplicate pastes|HIST|B|
|G406|-|One private-text function (Dr Patel, Dr Pepper rules)|RULED||
|G415|-|Units row "mi" has no reader|RULED|P|
|G417|-|Shutdown tomorrow line is a raw-text path|RULED|B|
|G419|-|Habit check-in op rules|RULED||
|G421|-|Key-removal receipt and the UNDO slot|RULED|P|

### Builder A (54)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G217|B|No kitchen timer rings; no notification exists|RULED|C|
|G219|I|Low Power not read by motion policy|RULED|D|
|G222|I|Cook Live Activity traps if copied from rest|CALL|D|
|G224|I|Soul Low Power form half built|RULED||
|G225|I|Reduce Motion over-dims Tess working marks|RULED|D|
|G241|I|Hold key ignores accessibility-size rows|RULED|B|
|G244|I|ProcessSeam redraws at 60 fps in Low Power|CALL||
|G245|I|Dab flight and bloom ignore Low Power|CALL|B|
|G247|I|Zoom, lift, blur ignore Low Power|RULED|B,D|
|G251|I|Tess receipts are silent to VoiceOver|CALL||
|G267|I|Plan rows redraw at 30 fps in Low Power|CALL|B|
|G268|I|Many animations key off Reduce Motion alone|RULED|B|
|G276|I|Settings control vanishes under VoiceOver focus|CALL|B|
|G304|I|Reading Finish key: one double tap completes|CALL|B|
|G323|I|START WITH writes up to seven ops on one tap|RULED|P|
|G336|I|Rest sound only rings if app process is awake|RULED|C|
|G343|I|Minimal, compact Island have no VoiceOver element|CALL||
|G344|I|Lock Screen reads countdown first, no thing|CALL|D|
|G345|I|Two "Skip" keys; "+15" read without unit|CALL||
|G346|I|Lock Screen Done changes silently under VoiceOver|RULED|D|
|G347|I|Live Activity ignores Dynamic Type|CALL|D|
|G373|I|Restore completes on one VoiceOver double tap|CALL|B|
|G382|I|Week/month swipe rebuilds plan data every frame|CALL|C|
|G383|I|Trend wet tip animates forever under pushed page|CALL||
|G384|I|Exercise page zooms skip Low Power crossfade|CALL||
|G390|I|Add to routine says nothing; no UNDO|CALL|B|
|G391|I|Add-to-routine menu offers routines not in plan|RULED|P|
|G393|I|Failed plan write: no warning or line|CALL|B|
|G394|I|Tapping today can do nothing|RULED|C|
|G395|I|Disabled days read "dimmed" to VoiceOver|CALL||
|G399|I|Reorder breaks at accessibility-size rows|CALL||
|G400|I|Plan controls overflow at AX sizes|CALL|D|
|G401|I|Editor writes one step per swipe, five UNDOs|RULED|C|
|G402|I|Editor buttons lack exercise name; focus lost|CALL||
|G430|I|Success haptic plays after a miss or timeout|RULED||
|G453|I|Live Activities off: rest ends in silence, unsaid|CALL|B|
|G248|L|Ambient wash and key sheen ignore Low Power|CALL||
|G249|L|Three Groceries haptics bypass the map|RULED|B,P|
|G271|L|Home finish plays a raw medium impact|RULED|B|
|G339|L|Rest "Go" push and digits ignore Low Power|CALL||
|G386|L|Rail ticks haptic on appear with no touch|CALL||
|G387|L|Day-word stagger, press fade bypass policy|CALL||
|G388|L|Plans pages never roll the day (no polling)|RULED||
|G396|L|VoiceOver crosses week to month unannounced|CALL||
|G397|L|Month grid starts Sunday, week starts Monday|RULED||
|G398|L|Month heading wrong between midnight and 4 AM|RULED||
|G403|L|Routine row reads abbreviations, noisy hint|CALL||
|G404|L|Exercise history shows abbreviated weekdays|CALL||
|G405|L|Kilograms hard-coded in exercise and rep maxes|CALL||
|G12|-|Plan week ignores the weekly rhythm|HIST||
|G13|-|Week page never draws a rest day|HIST||
|G14|-|Week counts days, not sessions|HIST||
|G25|-|No Kitchen widget|HIST||
|G413|-|Haptics off has no gate; 27 raw sites|RULED|B|

### Builder B (138)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G181|B|Private recipe hero reveals title on one tap|RULED|C|
|G182|B|Original-text screen reveals title and body|RULED||
|G250|B|Lists and Groceries hide Tess line and UNDO|RULED|A|
|G272|B|Review, Settings, Backups covers: no Tess line, UNDO|RULED|A|
|G299|B|Delete note: no confirm, line or UNDO|RULED||
|G412|B|No SettingsView; Review foot SETTINGS word|RULED||
|G434|B|Ask slot line and UNDO read from two places|RULED||
|G447|B|Cancelling first mic ask leaves mic live to 60 s|RULED||
|G65|I|Kept-for-later recipe link has no door|HIST|C|
|G67|I|Send UNDO lives in page state|HIST||
|G68|I|Every ingredient row adds the whole recipe|HIST||
|G69|I|Recipe page breaks at large text sizes|HIST||
|G78|I|A running list has no hero on Now|CALL||
|G186|I|Private recipe name drawn at 66 percent ink|RULED||
|G192|I|Routines print raw titles outside workout session|RULED|C|
|G193|I|Cook screen not built; cookModeReady false|CALL|P|
|G208|I|Only the empty Pantry teaches "out of milk"|CALL|P|
|G230|I|"Add all to Groceries" not a VoiceOver stop|CALL||
|G231|I|Add receipt announced at default priority|CALL|A|
|G232|I|Slid-off ingredient column stays readable|CALL|A|
|G252|I|Groceries Undo word says nothing after|CALL||
|G253|I|Shelf rows read all-caps strings|CALL||
|G254|I|Private row lacks Check off and Remove actions|CALL|C|
|G255|I|Done on a reusable list drops VoiceOver focus|CALL||
|G256|I|Picked name not announced; focus stays hidden|CALL||
|G259|I|Mirrored Tess line cut at AX sizes|CALL||
|G269|I|Cover zoom from the Home word ignores Low Power|RULED||
|G273|I|Settings carry their own UNDO beside the app one|RULED||
|G275|I|Private task title reaches Home unmasked|RULED|C|
|G277|I|No element called Settings for VoiceOver|RULED||
|G278|I|Settings rows keep shape at AX sizes|CALL||
|G280|I|Pager exposes off-screen pages to VoiceOver|CALL||
|G281|I|"Done. Next one is up." names no thing|CALL||
|G289|I|Note row zoom ignores Reduce Motion, Low Power|CALL|A|
|G290|I|Notes replay entrance animation every open|CALL|A|
|G291|I|Money, Reading steers lack Low Power forms|RULED|P|
|G296|I|Note Links section prints private titles|CALL||
|G298|I|Writing a note says nothing; no UNDO|RULED|A|
|G300|I|Note row spoken with abbreviated time|CALL|C|
|G301|I|Note row squeezed at AX sizes|CALL||
|G305|I|Drums unusable without sight (142 swipes)|CALL|P|
|G308|I|Money capture UNDO fixed 4 s under VoiceOver|CALL|C|
|G310|I|Ledger and shelf layouts undefined at AX sizes|CALL|P|
|G312|I|Plan wording Claude call self-starts in Low Power|RULED|C|
|G313|I|Mic bloom and heard words animate in Low Power|CALL|A|
|G315|I|Review page rebuilds the whole week per pass|CALL|C|
|G319|I|Plan UNDO says nothing after taking back|CALL||
|G320|I|Kept plan row still reads "Proposed", can Skip|CALL||
|G321|I|Plan rows past five are text, not actionable|RULED|D|
|G322|I|One skip spends the plan offer for the day|RULED|C,P|
|G324|I|Speak via VoiceOver never ends on silence|RULED||
|G325|I|Settled Speak sentence not announced, can't stop|RULED||
|G327|I|Day log row reads 07:10 clock to VoiceOver|CALL|R|
|G333|I|Habit rows lack spoken label, hint, sentence|CALL|C,R|
|G360|I|Backups page does disk checks inside body|CALL|C|
|G371|I|Choosing a backup folder has no UNDO|CALL|C|
|G376|I|Receipt lines start with the clock|CALL||
|G429|I|Phrases with "best" or "?" skip the router|RULED|C|
|G433|I|Phrase waiting on Claude: frozen line, no Cancel|RULED|A,D|
|G435|I|Bare Undo for last 2 s with no line|RULED||
|G436|I|Undoing a capture leaves old receipt|CALL||
|G439|I|Lift-ask answers truncate at AX sizes|CALL||
|G443|I|Memory-session warning clears when Tess opens|CALL|P|
|G448|I|Mic refusal paths touch input node unsafely|CALL||
|G449|I|Mic and Speech Settings round trip not re-read|CALL||
|G70|L|Failed send: no warning haptic or retry|HIST||
|G72|L|Small residuals: "12 months ago", raw animations|HIST|C|
|G91|L|Pantry line promises an unbuilt phrase|CALL||
|G99|L|Duplicate line prints the full title|CALL||
|G108|L|UNDO names only the first of three added items|CALL||
|G115|L|Metric tap shows 28.4 g style numbers|CALL|C|
|G144|L|Tess line uses full recipe title|CALL||
|G147|L|Private rows tie, shuffle, leak aisle position|CALL||
|G148|L|Body-weight lookup runs per ingredient|CALL||
|G150|L|"Bought Sat" wording unused and unmasked|CALL||
|G151|L|Pantry tests missing (private label, summaries)|CALL||
|G195|L|Tess shelf line reveals private cook counts|CALL||
|G205|L|Going back a build refuses the new store|CALL||
|G212|L|Same last-cook Tess line repeats every open|CALL||
|G214|L|CAN COOK greyed-word sentence points at nothing|CALL|P|
|G226|L|Home DrainBar redraws every second|CALL||
|G234|L|Home cook drain read as percent|CALL||
|G236|L|Context line spoken as drawn ("min", "h")|CALL||
|G237|L|"Show in metric" silent under VoiceOver|CALL||
|G238|L|Back word is a 32 pt target|CALL||
|G239|L|VoiceOver order differs by text size|CALL||
|G243|L|Recipe page scrolls only from AX1 up|CALL||
|G246|L|Aisle fade bypasses MotionPolicy (180 vs 150 ms)|CALL||
|G260|L|Long list rows cut; Reset squeezed|CALL||
|G261|L|Aisle change in shop announces nothing|CALL||
|G262|L|Groceries has no back word|CALL||
|G263|L|Running-list Now row reads "min", folds Resume|CALL||
|G264|L|Row labels put amount before the thing|CALL||
|G265|L|Lists option words lack toggle trait|CALL||
|G266|L|Two Lists writes ignore a failed save|CALL||
|G270|L|Raw withAnimation calls skip MotionPolicy|CALL||
|G279|L|Settings sentences read in fragments|CALL||
|G282|L|Paused-context line spoken as drawn|CALL||
|G283|L|Training lane read with "x" and no unit|CALL||
|G284|L|Start key capitalizes routine words|CALL||
|G285|L|Queue window fixed at 156 pt at AX sizes|CALL||
|G286|L|Day pick has no selected state or announcement|CALL||
|G287|L|Review lines spoken abbreviated, no unit|CALL||
|G288|L|Two helpers still build clocks in words|CALL||
|G294|L|Note row time word goes stale|RULED||
|G307|L|Spoken forms are drawn forms ("p 142 of 612")|CALL||
|G311|L|Resuming a book announces nothing|CALL||
|G314|L|Dry-line timings follow Reduce Motion only|CALL||
|G326|L|Hold refusal reads "Open Settings still works."|CALL||
|G328|L|Day log rows lack button trait and hint|CALL||
|G330|L|Day-log bands fixed height at AX sizes|CALL||
|G372|L|Backup receipts lead with the verb|CALL|P|
|G381|L|Put-away rows read abbreviated weekdays|CALL||
|G441|L|Typed "undo" does not undo|CALL||
|G446|L|First-launch rest-day receipt holds 4 s, any hour|CALL||
|G15|-|Empty clear-done claims success, no UNDO|HIST||
|G17|-|Pantry merge order for state and date|HIST|C|
|G18|-|Pantry staple exception order|HIST|C|
|G19|-|Home shows no planned or done cook line|HIST||
|G20|-|Home says "at" before a time|HIST||
|G24|-|Pantry bought-day word|HIST|C|
|G33|-|Empty Kitchen page on Home|HIST||
|G39|-|Claude receipt clock form|HIST||
|G43|-|Finish shop gives no line or UNDO|HIST|C|
|G47|-|Pantry "already on" check counts open rows only|HIST||
|G49|-|"1 list" context text|HIST||
|G50|-|Pantry Tess line uses the full recipe title|HIST||
|G51|-|"Recipes" always opens the oldest recipe|RULED||
|G52|-|Paste: first save loses line and UNDO|HIST||
|G53|-|Private recipe title drawn raw on its page|HIST|C|
|G55|-|Cook key starts a cook nobody sees|RULED|C|
|G57|-|Portion drum stops at 12|HIST||
|G58|-|Failed send to Groceries leaves column stuck|RULED||
|G60|-|Context line reads "1.6 h", "94 days ago"|HIST||
|G61|-|Key refusal on Paste points at Settings|RULED|C|
|G414|-|Settings row value grammar (Off/On)|RULED|P|
|G416|-|Habit words take the raw name|RULED||
|G422|-|Page 1 height with the key line open|CALL|D|

### Kitchen lead (7)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G218|I|Keep-awake unbuilt and has no end|RULED|P,A|
|G220|I|Cook specs lack Low Power rows, tick cadence|CALL|D,B|
|G228|I|Two reading orders for one cook screen|RULED|P|
|G233|I|Timer spoken-value cadence missing|RULED|A|
|G235|I|Timer-end overlay: focus and Stop unclear|RULED|D|
|G240|L|Two announcement rules can double-speak|CALL||
|G409|-|Pantry walk script PE appendix stale (24 vs 29)|CALL|O|

### Product (rulings, specs) (46)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G334|B|A habit name has no mask|RULED|C,B|
|G348|B|Widget spec has no mask rule for private words|RULED|R,C|
|G94|I|Titles starting with a digit read as quantities|CALL|C|
|G102|I|Tap-to-reveal prints the raw private item|RULED|B|
|G105|I|Three different private-item walls|RULED|C|
|G122|I|First-line title versus quantity rule|CALL|C|
|G204|I|Backfill writes "in" for a basket in Later|CALL|C|
|G207|I|Pantry page reads thin after the first shop|CALL|B|
|G209|I|CAN COOK un-greys after one known ingredient|CALL|B|
|G210|I|First cook on empty Pantry guesses OUT and LOW|CALL||
|G223|I|Rulings disagree on Low Power haptics|RULED|A|
|G229|I|Hold keys complete on a VoiceOver double tap|RULED|A|
|G257|I|Lists and Groceries use different private checks|RULED|C|
|G258|I|Groceries Done, Lists Reset: one double tap|RULED|A|
|G297|I|Private note row reveals words on one tap|RULED|B|
|G302|I|Ship lists lack thing-first rule|RULED|C|
|G306|I|Spend page uses 24-hour clock, day-first dates|RULED|B|
|G349|I|No Spotlight spec; masked objects may be indexed|RULED|R,C|
|G370|I|Backup receipts vs sent-job log ruling|RULED|C|
|G375|I|Remove-key flow: ruling and code disagree|RULED|B|
|G377|I|Quiet hours, day start as steppers (sheet 93)|RULED|R,C|
|G378|I|Delete everything: what it removes unstated|RULED|R,C|
|G385|I|Page-turn slide only shortens in Low Power|RULED|A|
|G438|I|Typed sentence can't be cancelled under VoiceOver|RULED|B|
|G452|I|Training-only users never get the notification ask|CALL|A|
|G454|I|"Remind me Saturday": 9:00 ring vs no-time ruling|CALL|C|
|G455|I|Sleep Focus holds the 5:30 am overnight timer|CALL|K|
|G80|L|Three separators for one list fact|CALL|C|
|G81|L|Lists context: doc and code disagree|CALL||
|G85|L|Private list copied under a public name|CALL||
|G90|L|Stored pantry states the screen never shows|CALL||
|G95|L|Written-out quantities pass as titles|CALL||
|G101|L|Two pastes both saved "Untitled recipe"|CALL||
|G145|L|Tess line lowercases names, receipts do not|CALL||
|G146|L|Dropped private ingredients skew the count|CALL||
|G149|L|Home Pantry hero line not built|CALL||
|G152|L|Prompt mixes Groceries tap-strike with Pantry|CALL||
|G194|L|Paste preview shows a private title before Save|CALL||
|G206|L|iCloud copy would carry Pantry state|CALL||
|G211|L|No way back to unknown|CALL||
|G338|L|Set-aside workout card lingers on Lock Screen|RULED|A|
|G380|L|Private routine workouts go to Apple Health|RULED|C|
|G425|L|Inbox refuses phrases the online path sends|RULED|C|
|G440|L|A mode that does nothing: "Show" button|CALL|B|
|G460|L|Full-history warm-up on cold launch in Low Power|CALL|C|
|G418|-|No slot for the habit ask on Shutdown|RULED|D,B|

### Design (14)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G242|I|Dim text near 3:1; no Increase Contrast|RULED|B,A|
|G317|I|Shutdown close has no Low Power rows|RULED|R,B|
|G331|I|Shutdown row flip not spoken for VoiceOver|CALL|R,B|
|G356|I|Home widgets lack VoiceOver, Dynamic Type rules|CALL|R,A|
|G364|I|Review shows the started week, not the ended one|RULED|B|
|G379|I|Health export row means two things|RULED|B,C|
|G437|I|Ask slot overlay leaves page behind reachable|CALL|B|
|G458|I|Notification ask has no VoiceOver, large-text row|CALL|B|
|G227|L|Reduce Motion fade 200 ms vs 150 ms|CALL||
|G318|L|Habit check-in has no motion row|RULED|R|
|G332|L|Shutdown has no accessibility-size layout|CALL|B|
|G450|L|Speak refusal line squeezed, ungrouped|CALL|B|
|G411|-|Sheet 93 folder copy behind the rulings|RULED|B|
|G420|-|No Low Power rows in Habits, Shutdown specs|RULED||

### Research (13)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G316|I|Monday week-story Claude call is automatic|RULED|C,B|
|G340|I|Widget reload rule missing; build would poll|RULED|A|
|G341|I|Pre-written widget entries are unruled landings|RULED|P,A|
|G342|I|Spotlight index write timing unspecified|RULED|C|
|G354|I|Cook Activity could show a private timer label|CALL|K,D|
|G361|I|Job table has opposite Low Power axis|RULED|C|
|G362|I|Week story lands in quiet hours or too early|RULED|P,B|
|G363|I|No rule for a Monday that got no story|RULED|P|
|G365|I|Settings words never say when Tess waits|CALL|D,B|
|G355|L|Widget spec draws 24-hour clocks|CALL||
|G358|L|Research doc contradicts the Face ID ruling|CALL||
|G457|L|Notification words differ across docs|CALL|P|
|G459|L|Never-notifies list omits Reading, People, more|CALL||

### Ops, QA, Mac leads, or no owner (5)

|Id|Sev|Summary|Status|With|
|---|---|---|---|---|
|G185|L|Sticky Pantry not built; mask is live (closed)|RULED||
|G30|-|Kitchen switch in Settings (non-goal)|RULED||
|G407|-|Flip PR for cookModeReady, with test rewrite|CALL||
|G408|-|Mirror decisions.md into the repo|RULED||
|G410|-|Name one owner for the clock page|RULED||
