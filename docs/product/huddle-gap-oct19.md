# Huddle gap list, 6:15 PM Oct 19

Product. Everything on the huddle page that is NOT yet on Kaushik's phone in release 23 (1e7a0760). Sources: Builder A, Builder B, Core, Design, Kitchen, Research status messages. "22d2" = master 087863ec + #1137 + #1145; "22e" = #1143, #993 rebuild, then small items.

## In 22d2 / 22e (nearly there)
| Feature | Owner | PR / branch | Waits on |
|---|---|---|---|
| Settings tabs (PeekTabs) | Builder B | #1137 82c83259 | QA PASS + Design PASS, in 22d2 |
| Kept-phrase fix | Core | #1145 7ad8446f | QA with notes, in 22d2 |
| Growing ask box, Return send, private mask in Sent | Builder B | #1143 0fefe162 | Design re-pin + AX5 screenshot, 22e |
| Link wait line with host first | Builder B | #993 rebuilt on master | QA, 22e |
| Page turn (Slide, Turn, Soften, Rotate) | Builder B | ios/settings-next 05723c93 | opens after #1137 |
| Kept-phrase follow-ups (Claude failed = stays in Ask; "To sort" label) | Core + Builder B | stacked on #1145 | Core branch; label is Builder B view work |
| Exercise long-press detail + GIFs | Builder A | #1140 | Kaushik's yes for the force-push of Builder A's own branch; GIF import (71 downloads) on the Mac |

## Built or being built, needs one more release
| Feature | Owner | State | Waits on |
|---|---|---|---|
| Money + Reading objects | Core | #1148 a1ed817e at QA | QA; grammar phrases and NowPicker rules not built |
| Day log | Core then Builder A | core/day-lines started | DayStory.lines, then Builder A screen |
| Apple Watch | Builder A | #1138 merged, not embedded | his watch on; phone side is in 23 |

## Not started (starting now in parallel)
| Feature | Owner | Waits on |
|---|---|---|
| Reading layouts refit | Builder A | nothing; behind "Reading layout" switch |
| Set marks (ink drops) | Builder A | Design spring values in #1144 (merged) |
| Clock page (cook) | Builder A | nothing |
| Widgets / Live Activity / Lock Screen look | Builder A | nothing |
| Tess motion (11 ideas, mouth), Low Power MotionPolicy, top-bar re-trace fixes | Builder A | Design motion picks |
| Small faded images | Builder A | Design pick |
| Parallel steps, hands-free cook, cook notes | Core engine, Builder A screens | Kitchen rows (#1103), sheet 114 |
| Me profile page | Builder B | sheet 108 s3 |
| Me profile object, Calories burned, Training rename migration | Core | MET list (#1132/#1139) |
| Plan my day, Shutdown, Energy check-in | Core engine, Builder B screens | sheet 112 (energy) |
| Class inspector, What Tess did + undo, class package, body weight + Habits | Core engine, Builder B screens | sheet 113; after DayStory.lines |
| Groceries with Tess, meal plan, shop receipt | Builder B | ios/kitchen-v2 |
| Money, Reading, People, Upkeep screens | Builder B (Core engines) | #1148 for Money/Reading |
| Restore offer, launch note queue, signing-lapse warning | Builder B | sheet 111 |
| Build me an app, Remix editor and code view | Core engine, Builder B screens | after B4/B5 |
| Kitchen v2 (pantry state, what can I cook, running low, aisle order, week of dinners, recurring groceries, leftovers, recipe edit, link reader v2) | Engine Core, screens Builder B | Kitchen rows, sheet 114 |
| Review switches for all of the above (weekStrip, repeatItems, cookDouble, parallelSteps, cookNotes, fixRecipe, usuallyLine, aisleOrder, classInspector, energyCheckIn, caloriesBurned) | Builder B | next small PR |
| Reference library downloads (USDA, FoodKeeper, wger, CNF), nutrition + grocery tables | Core/Mac | batch 11, Mac |
| Exercise pictures (smoother set), About page credits | Motion lab, Research, Builder A | Kaushik's verdict on the traced sample |
