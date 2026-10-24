# 231 Kitchen landing: summary, Cook, cooking

Board: https://claude.ai/artifact/P8MtexZsp5T39K6X5PSZnr (r46). Answers Kaushik's 6:07 PM Oct 23 note. Builds on 226 (four bands) and 227. Pantry and Recipes pages come later as their own rounds.

## Colors
Kitchen A8701F light / C49A5E dark for the name and large numbers. Small Kitchen-colour words (Cook now, Undo, Cooking, "Garlic is ready") use a text shade 93611A in light (4.9:1 on paper; A8701F is 3.9, too low for 15 pt); dark keeps C49A5E (8.1:1).

## Landing, not cooking
- Top row: "Kitchen", day word.
- Headline: "Tonight you could make", the dish name 46 pt in Kitchen colour, "25 min, you have all 8 things", "another".
- Fun: the dish name is a reel. "another" or a swipe up on the name rolls it vertically to the next dish you can make with what's here; its line wipes in after. Tap the name to open the recipe.
- Brief: "Eggs and milk run out first. Spinach wants using by Sunday."
- Body, Pantry: three numbers (Outfit ExtraLight 44): on hand, low (Kitchen colour), to get. They count up on arrival. Tap opens Pantry (designed next).
- Body, Recipes: "You can make 4 now" (opens Cook), "Pasta on Thursday", "Dal, last made Tuesday".
- Foot: "Cook", Tess.

## Cook (page)
"With what's here", "What are we cooking?", brief "4 you can make now. 2 need one thing." Rows 44 pt: name, minutes, "Cook now". Ones missing a thing in ink 2 with "needs feta". Foot "New recipe" (brief becomes "Tell Tess, paste a link, or type it in."). Left edge back.

## Recipe (page)
Name, "25 min, serves 2, 6 steps", brief "You have all 8 things. Last made two weeks ago.", ingredient lines with amounts. Foot "Cook now".

## Cooking (the landing taken over)
- Top row "Cooking" in Kitchen colour.
- Top band: dish name (opens recipe), "Step 2 of 6", step title 26 pt, and the step's timer at 72 pt with its word ("garlic"). A step with no timer shows the soonest running timer instead; with none, the step's note.
- Brief: "Then: zest the lemons. Into the pan, then the juice." Last step: "Last step. Enjoy it."
- Body: Timers as plain lines, soonest first, at most 3. A finished timer turns into words ("Garlic is ready") in Kitchen colour, and the big number goes Kitchen colour reading 0:00 "ready". On the phone: local notification or Live Activity, sound follows the silent switch.
- Below, the rest of Kitchen in ink 3, two lines: "Pantry 24 on hand, 3 low", "Pasta on Thursday".
- Foot: "Next step", last step "Done cooking". Done returns to the landing with "Cooked. Pantry took 6 things. Undo" for 10 s.

## Rules kept
No cards, bars, rings or chart furniture; no food drawings; no pixels; clip reveals only; Reduce Motion lands in one step; fixed slots (224): dish name one line, Tess short form past 18 chars; one action word in the foot.

## Reviewer fixes (Oct 23, 6:22 PM PT)
1. Private recipes: the reel, "Tonight you could make", Cook now rows and the planned line skip a private recipe or show its shownLabel. A private dish name never reaches a notification, Live Activity or notice (they read "Your dish" and "Timer done").
2. Missing-thing words ("needs feta") are ink 2. Ink 3 only for the shrunk Kitchen lines while cooking.
3. "Dal, last made Tuesday".
4. Fixed slots: step title 26 pt in a two-line slot (58 pt, bottom-aligned); timer name one word (Tess short form); count labels fixed ("on hand", "low", "to get"). The 46 pt reel is clipped to its 52 pt slot while it rolls.
5. New recipe: "paste a link" fetches the page on the phone and parses it on-device; only with asksClaude on and his ask does it go to Claude. "Tell Tess" follows the usual Tess rule.
6. 93611A is dE 16.4 from the nearest Ember stop (E5341C). VoiceOver reads each count's final value from the start ("Pantry: 24 on hand, 3 low, 5 to get"); the digits rolling are hidden from it. The reel and the count-up land in one step under Reduce Motion.

## Drift fix (Oct 23, 7:45 PM PT)
- The separate "Cook" page is superseded. Cook now opens the Recipes page (233) on its "Ready now" place, in the wheel view. Its rows, foot word and New recipe follow 233 v4. The landing's "You can make 4 now" line opens the same page.
- The recipe page is shared with 233. It has the fixed lines "Keep at the top" and "Plan for", shows up to five ingredient lines, and its foot word follows the recipe: Cook now, Get it, or Get 2 things.
- Dials in 232 and 233 use the same spec: three 64 pt slots, a 44 pt focus at weight 600 in the Kitchen colour with its count in Outfit 200, neighbours at 26 pt in ink 2 (233 v5), and looping. Wheels (230, 233) put every row in ink 2 or darker.
- Every receipt follows one pattern: "Thing, what happened. Undo", for 10 s, and the newest replaces the line.
