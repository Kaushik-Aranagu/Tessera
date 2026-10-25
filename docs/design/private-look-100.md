# 100. Private-look acceptance rows (P2-P6), one pass on the Mac

From the audit on sheet 99 section 3. Each row is one thing to look at, on one screen, with a pass condition a builder can check in a single walk. Rule behind all of them (sheet 92 section 3, G102): a masked thing is one string, in the same type, weight, colour and place as the real thing. No lock, no dimming, no asterisks, no reveal.
Setup: `-demo -resetDemo -demoTime 18:10`, Porcelain and Obsidian, Dynamic Type default and the largest. Make the private things from made-up phrases only: a workout titled with a health word, a list "Pills", an ingredient "ibuprofen", a recipe "Dentist cake". Take one screenshot per row, with a normal twin beside it on the same screen.

| Row | Screen | Steps | Passes when |
|---|---|---|---|
| **PL1** (P1, builder B) | Recipes shelf | Add "Dentist cake" and "Weeknight dal". | Both rows draw at the same ink, size and weight. "Private recipe" is 100% ink (not 66%); the day at the right sits in the same column on both. |
| **PL2** (P2, #885) | Groceries list and SHOP mode, a list page | Add "ibuprofen" next to "milk". Tap each once. | Both rows read at the same size, ink and indent. Neither shows a hint or changes text on tap; the private one strikes into the basket like the other. VoiceOver reads "Private item, puts it in the basket" and "Milk, puts it in the basket" (a list page: "checks it off"). |
| **PL3** (P3) | Groceries basket | Put both in the basket. | Both rows sit at the same lightness (the checked tier, 35% ink) with the same strike. The private one is not lighter or heavier, and a tap takes either back out. |
| **PL4** (P4, #895) | Home, Now, Review, Day log | Finish a workout with a health word in its title, then look at all four. | The hero reads "Private workout" at the hero's size and weight in the hero's place. The context line is the time or "Today", not a count of exercises. Review and the Day log read "Private workout" with the time at the right, as any line, and list no sets. No lock, no dimming anywhere. |
| **PL5** (P5, #912) | Object page, from a recipe, Groceries and a Linked-from row | Open "ibuprofen" and "Pills" and the recipe "Dentist cake". | The header reads "Private item" / "Private list" / "Private recipe" in the title type. The class line prints the class only ("object : Ingredient"), no words of the title. Child rows, Linked-from rows and link handles read the same label. The page shows no fields, notes or contents. |
| **PL6** (P6, all of the above) | Every row in PL1-PL5 with a trailing time, count or state | Compare the masked row with its twin. | The trailing column is pinned to the same right edge, with the same gutter. A short masked label never pulls the time or state inward, and never centres. |

- **Haptics:** none of these rows plays one. A masked row is information.
- **Largest Dynamic Type:** "Private workout" is longer than a short real title ("Push A"). It may wrap to two lines (hero form wraps), never an ellipsis; the time stays at the right on the first line.
- Record each row as PASS or FIX with the screenshot name. A failing row names the file and line to fix.
- Row PL1 is a known fix: `RecipesShelfView.swift` draws a private row at 66% (`row.isPrivate ? 0.66 : 1`). Draw it at 1.
