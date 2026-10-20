# Huddle batches, Oct 19

Product. Source of the huddle page. 82 features in 12 batches. Target dates are Product estimates, not a written plan (they assume the Mac stays unlocked and test.sh runs once per batch). Row status is not checked against master. Default of every switch is today's behavior.

## Batch 0: The Review section

Settings, first. Every open choice becomes a switch he flips live, so nothing waits on his word. (Design draws it, Builder B builds it). Target Tue Oct 20.

| Feature | Who | Settings switch |
|---|---|---|
| Review section in Settings: one screen, one row per open choice, each with a plain before/after line | Builder B + Design | Is the option list below |
| Reading layouts: refit of Groceries, Home/Now, Exercise page, Backup, literal-size cleanup (reading-layouts-99.md) | Builder A + B | Reading layouts: Today / Reading layouts 99 |
| Page turn: Slide, Turn, Soften, Rotate, plus paged long lists | Builder B | Page turn (4 choices) |
| Rest timer, easy swap, forgot-Finish nudge (week-one training questions) | Builder A | Rest timer / Swap / Finish nudge, each on or off |
| Top bar, stage-coloured titles, area colours, small images (he decided all of these) | Builder A | none, decided: ships directly |

## Batch 1: Look and Home

The visible gap between the board and his phone. Biggest first. (Builder A, with Design and Motion lab). Target Wed Oct 21.

| Feature | Who | Settings switch |
|---|---|---|
| Top bar: one word up top, pull down or tap for the area index (sheet 73 A), each screen declares its side swipe | Builder A | none, decided |
| Titles bolder, a colour per stage, key word leads, done strikes through | Builder A | none, decided |
| Area colours (areaLean) across Kitchen, Training and the rest | Builder A | none, decided |
| Small faded images only where the screen is not cluttered | Builder A | none, decided |
| Muscle figure on Exercise and Routine pages (approved, sheet 91) | Builder A | none, approved |
| Reading-layout refit in Design section C order | Builder A | Reading layouts |
| Tess motion: all 11 ideas and the small mouth, one sheet per pick | Builder A + Motion lab | Tess eyes and mouth (eyes stay a setting) |
| Low Power flag (MotionPolicy.isReduced) so Settings can ship | Builder A | none, gate |

## Batch 2: Training

Daily use first. Live workout stays the best screen in the app. (Builder A). Target Tue Oct 20.

| Feature | Who | Settings switch |
|---|---|---|
| Rest-end alert as the local notification "Rest is up"; Private exercise on the Lock Screen | Builder A | Rest timer |
| Closing face: "<title>, ready to finish", masked version for private workouts | Builder A | none, ruled |
| Easy exercise swap in a live workout | Builder A | Swap: one tap or two |
| Nudge when a workout was left unfinished | Builder A | Finish nudge |
| Widgets, Live Activity and lock-screen Done kept in step with the new look | Builder A | none |
| Set marks: liquid ink drops, one brush circle per set (closed on target, open short, overlap extra rep, flare best, thicker heavier); tap for the numbers (replaces the wave, you picked it) | Design, then Builder A | none, you asked for it |
| Long press an exercise: how it is done, equipment, muscles, about how many kcal | Design, Builder A, Research | Calories burned (off) |
| Me profile: weight (from your entries, Health only if you turn it on), height, birth year, whatever you choose; stays on the phone | Core + Builder B | none |
| Calories burned: estimated from the exercise and your profile, shown as "about N kcal", never a budget | Core + Builder A | Calories burned (off) |
| Training reorganization: new routine names, a clearer Training screen for the gym, a muscle figure on every exercise. Design shows you options first; target after you pick | Design, then Builder A + Core | Pick from Design options |

## Batch 3: Tess and Claude

Tess keeps her walls. The in-app switch Tess asks Claude still gates everything. (Core, Builder B, AI architecture). Target Thu Oct 22.

| Feature | Who | Settings switch |
|---|---|---|
| What was sent log: every Claude job writes a Sent row, 30 days or 500 rows, Clear button | Core + Builder B | Receipts list |
| "Asking Claude." line on Now with Cancel, 8 second hard cap, "Cancelled." | Core + Builder B | none |
| Reinstalled phone asks once about a found key (blocker G687) | Core then Builder B | none, blocker |
| PowerState and Low Power gate; first-send notice; key check row; outside spend file | Core | none |
| Offline drain: kept for later, retried when back online | Core | none |
| Plan wording and recipe reading by Claude through the one door | Core | Tess asks Claude |
| Capture past the grammar on the phone (Foundation Models fallback) | Core | On-phone fallback |
| Visible memory: what Tess has learned as facts you can edit or delete | Core + Builder B | Memory page |

## Batch 4: My day, connected

Tess sees the calendar and the body, then plans the day and closes it. Counts only, never a guilt list. (Core engine, Builder B screens). Target Fri Oct 23.

| Feature | Who | Settings switch |
|---|---|---|
| Calendar mount and Health mount, read only | Core | Calendar, Health: on or off |
| Plan my day at 8 AM: rules first, Claude wording on top | Core + Builder B | Plan my day |
| Shutdown at 9 PM: counts, roll items over, one line for tomorrow | Core + Builder B | Shutdown |
| Day log (Time Machine): a page per date built from the op log | Core + Builder A | none |
| Focus block with a halfway check-in; first-step splitter after 3 idle days | Core | Focus helpers |
| Energy check-in on the rep drum, paired with sleep | Builder B | Energy check-in |
| Quiet interrupts: low priority notices held and grouped | Core | Quiet interrupts |

## Batch 5: Make it mine

The OS part: classes he can shape. Check what is already built before starting a row. (Core, Builder B). Target Sat Oct 24.

| Feature | Who | Settings switch |
|---|---|---|
| Add a field to any class by typing "rating: 4" | Core | none |
| Saved queries; computed fields from the formula language | Core | none |
| Class inspector page | Builder B | none |
| Tess answers from the log ("best bench at 5") and edits by voice ("move dentist to friday") | Core | none |
| "What Tess did" receipt with undo; export and import a class package | Core + Builder B | none |
| Body weight trend and Habits as a building block | Builder B | Body weight, Habits shown |

## Batch 6: Kitchen

Groceries, recipes, pantry and cook. The Oct 22 morning packet is Kitchen's. (Builder B, Builder A for the clock page, Kitchen). Target Thu Oct 22.

| Feature | Who | Settings switch |
|---|---|---|
| Clock page (cook) end to end, US units, timer voice, finish line | Builder A | Cook timer voice |
| Recipe page, Pantry screens, link fetch for recipes | Builder B | Link fetch |
| Groceries with Tess, meal plan to groceries, store shop receipt | Builder B | none |
| Kitchen v2 waits for a week of use, scoped from his answers | Kitchen | none, waits |

## Batch 7: Money, Reading, People, Upkeep

Four small areas. Each one is a class, phrases, a page and a front page, and each writes into the Day log. (Core engine, Builder B screens). Target Sat Oct 24.

| Feature | Who | Settings switch |
|---|---|---|
| Money: "spent 12.40", receipt total after a shop, month line | Core + Builder B | Money area |
| Reading: a book as a process, resume on Now, shelf | Core + Builder B | Reading area |
| People: mentions, last talked, birthdays as dated tasks, @ in editors | Core + Builder B | People area |
| Upkeep: chores with an interval, the stalest drifts toward Now, never red | Core + Builder B | Upkeep area |

## Batch 8: Backups and safety

Before he trusts it with a week of data. (Core, Builder B, Research). Target Thu Oct 22.

| Feature | Who | Settings switch |
|---|---|---|
| Backup rules: Documents/Backups only, stamp and warn on restore, refuse restore mid workout or cook, keep first copy plus 3 | Core | none, ruled |
| Quiet restore offer line; launch note queue; signing-lapse warning in the app | Builder B | none |
| Private words wall in every copy; key, bookmark and flags never in a backup | Core | none, never relaxed |

## Batch 9: Stretch: Tess grows up

The big ones that were parked or pushed to Later. Anything that sends to Claude is off by default, behind Tess asks Claude, inside the $50 a month cap. Walls and key rules unchanged. (Core, AI architecture, Motion lab, Builder B). Target Wed Oct 28.

| Feature | Who | Settings switch |
|---|---|---|
| Tess reads the screen: she picks her own roam and motion from what is on screen and how you touch it, small fast model, no images ever | Core + Motion lab + AI arch | Tess reads the screen (off) |
| Tess as chief of staff: area experts as bounded jobs, she gathers their facts and presents one view | AI arch spec, Core | Tess experts (off) |
| Build me an app from one sentence, using only the block catalog, shown as a ghost you accept | Core + Builder B | Build with Tess (off) |
| Week story and Home lines in Claude wording, with the memory profile written on the phone only | Core + AI arch | Home lines (off) |
| Rules and automations: "when X finishes, do Y", every action undoable | Core | Automations (off) |
| Two-way calendar sync, after the read-only mount has a week of use | Core | Calendar (off) |
| Remix editor and code view for classes; your own app tiles on Home | Design + Builder B | none, new screens |
| Apple Watch: sleep and resting heart rate first, then one-screen set logging with the crown. Allowed Oct 19; starts with a signing check | Builder A | Watch (off) |
| Share Extension from Safari: parked until you get the paid developer account (later); the Shortcut route works now | Builder B | none, parked |

## Batch 10: Stretch: Kitchen v2

Pulled in now (it was held for a week of use). Twelve features, engine first, screens after. Rows: kitchen-v2-build-ready-rows-oct19.md. (Kitchen, Core, Builder B, Builder A for cook). Target Sat Oct 31.

| Feature | Who | Settings switch |
|---|---|---|
| Pantry state: have it, low, out, with no counting; recipe page shows need against have | Core + Builder B | Pantry state (off) |
| What can I cook: rank by what is missing, ties by not cooked lately | Core + Builder B | Can cook shelf (off) |
| Running low by rhythm: a dim "usually by now" line, never auto-added | Core | Pantry state |
| Store aisle order learned from check-offs | Core | none |
| Week of dinners strip | Core + Builder B | none |
| Recurring groceries (setting the flag is the tap) | Core + Builder B | none |
| Leftovers: cook double plus one undated Later task | Core + Builder B | Leftovers (off) |
| Recipe edit in place | Builder B | none |
| Parallel steps in one cook: roast and sauce, several timers at once | Builder A + Core | none |
| Hands-free cook mode: "next", "back", "timer", on-phone speech, tap-opened, grammar only | Builder A | Hands-free cook mode (off) |
| Link reader v2: second reader, Claude as the last resort | Core + Builder B | Link reader v2 (off) |
| Cook notes into the recipe: optional note on Finish | Builder A + Core | none |

## Batch 11: Reference library

Nutrition first, then anything useful for training, groceries and work: public sources collected into our own library on the phone, so features can look things up without a call. Sources and licences are listed in an inventory file. (Research, Core, Kitchen). Target Wed Nov 4.

| Feature | Who | Settings switch |
|---|---|---|
| Nutrition table: calories, protein, fat, carbs per food from a public-domain source (inventory of sources and licences first) | Research + Kitchen | Nutrition (off) |
| Training reference: exercise names, muscles, equipment, standard load steps from open sources | Research + Core | none |
| Grocery reference: pack sizes, aisles, common swaps for a US kitchen | Research + Kitchen | none |
| Exercise drawings: our own short animations for every exercise and 9 equipment drawings (no third-party media), plus a calorie (MET) table | Design + Research + Core | none |
| Library inventory: one list of every reference set with source, licence, size and date | Research | none |
| Library on the phone: read-only objects, no calls, refreshed by an app update, never mixed with his own data | Core | none |
