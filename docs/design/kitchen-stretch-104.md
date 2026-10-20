# 104. Kitchen stretch: Pantry, Can cook, Week of dinners, the clock with overlapping timers, hands-free cook

Spec only; Builder B takes it with the Kitchen lead. Not yet okayed by Kaushik. Extends 78 (Pantry front and side), 67 (the Kitchen week), 69 (the recipe clock) and 99 (recipe-step rules: step in 28, ingredients and sentences in `read` 21, 330 pt column, ink-word Next, his photo or nothing, no drawn food, no cards). Each screen declares its side (sheet 75). Type: 44 / 28 / 21 / 16 only.

## 1. Pantry (78, kept, with the new switch)
- Front as 78: hero "4 out, 2 low", groups OUT, LOW, USUALLY HAVE, one 21 line per thing, state word right.
- Switch: Settings Review, Pantry state (103). Hidden shows no Pantry anywhere; Shown adds the area word and the ingredient peek rows.
- **Side: OUT AND LOW**, as 78. Empty: "Nothing yet."

## 2. Can cook shelf (on Recipes)
- A shelf at the top of the Recipes front, one line per recipe in 21, newest cooked last. The recipe name leads in ink; the right-hand 16 word is what is missing in plain count: "Ready" or "1 short". Never a percent, never a list of what he lacks on the front.
- Order: Ready first, then 1 short, then 2 short; nothing beyond 2 short. Six rows a page (sheet 90); the vertical swipe turns the page.
- Heading: the section word CAN COOK at 16 strong in the area colour; title stays the Recipes 44. A recipe with a photo shows his photo as the small faint plate (88) at the right of the lead row only; with no photo, nothing.
- Tap: the recipe page, with the ingredient peek open on what is short.
- **Side: WHAT IS SHORT**: for the tapped recipe, the missing lines each with an ink word "Groceries" that adds it ("Cumin, on Groceries.", UNDO). Empty: "Nothing short."
- Private recipes read "Private recipe" at 100% ink and never rank by name.
- Empty shelf: "Nothing is ready yet." in `read`, one line, no image.

## 3. Week of dinners
- A page of seven rows, Monday to Sunday by his week start, each a day word in 16 and the dinner in 21 (one line). No dinner: "Nothing planned" in `inkSecondary`. The page is a list, not a calendar grid.
- Tap a row: the day opens in place with the choices under it: his recent dinners and "Something new" as plain ink words. A pick sets the dinner and adds what is missing to Groceries in one line ("Tacos, 10 added.", UNDO), as sheet 67.
- Cooked tonight is struck through when done; the one haptic is the done haptic.
- Header: title 44 "Dinners", context line 16 "week of Oct 19". No band, no image.
- **Side: THE WEEK'S SHOP**: what the planned dinners need, grouped as Groceries groups it, counts only. Empty: "Nothing to buy."
- Private dinners read "Private recipe" and add their missing lines as "Private item" on Groceries.

## 4. The clock page with overlapping timers (cook mode)
Builds on 69's clock; this is the one-step-at-a-time view of the same page.
- **One step a screen.** Step in 28 regular in a 330 pt column; step number and total in 16 ("3 of 8"); ink word **Next** bottom right, **Back** bottom left in `inkSecondary`. Vertical swipe turns the step in the user's page-turn word; a horizontal swipe is the side.
- **Overlapping timers.** A timer inside a step shows its time as a 44 numeral beside the step. When two run at once, they stack as two lines under the step, each name in 16 and its time in 28, the one ending sooner on top. Never more than three lines; a fourth step's timer joins the list with the ink word "more" (tap opens them all in place).
- A timer that ends: its line lights in the area colour at 72% and the step word beside it is the one thing that moves; the haptic is one soft tap, the same as the rest-end alert's single beat (one haptic per moment; two ending in the same second share one).
- The bead from 69 stays as a 2 pt line at the foot showing where he is on the clock, never a progress percent.
- **Side: THE WHOLE CLOCK**: sheet 69's page, steps laid on time with the lit ones, so a swipe sideways shows the plan and back returns to his step.
- Reduce Motion / Low Power: the lit change is a 150 ms crossfade; no swell.
- Private recipe: the name reads "Private recipe"; steps are his own words, so they show only after a tap on the lock-free page and never on a lock screen or Live Activity.

## 5. Hands-free cook
- Settings Review, Hands-free cook (103). When on, a small ink word at the top right of cook mode, **Listening** in 16, lights only while the microphone is on; there is no always-on ear.
- Words: **Next**, **Back**, **Repeat**, **How long** (reads the nearest timer in a plain sentence in Tess's voice, 21 cobalt). Nothing else is acted on; anything else is ignored and shows nothing.
- Spoken line from Tess: one short line when a timer ends ("Rice is ready.") and not otherwise; the speech is plain, no tone words.
- If the system says no to the microphone: one 16 line "Tap Next instead." and the word **Listening** never appears.
- **Side:** the same THE WHOLE CLOCK.

## States common to all
- Empty, one, long (more than six rows turns the page, never a long scroll), AX1 and up (name above value, one column, the 28 step becomes 21 strong), Reduce Motion and Low Power (150 ms crossfade), Obsidian (area colour at 72%).
- Private: every title reads "Private recipe", "Private item" or "Private workout" at 100% ink, in the rows, the side, the receipt and VoiceOver.

## Never
Cards, pills, a progress percent, a drawn food stand-in, a stock image, an always-listening mark, a timer count beyond three lines, italics, a fourth size.

## For Builder B and the Kitchen lead
Can-cook ranking is Core's count of missing lines, with staples and "to taste" lines excluded as in sheet 67. The timers come from the step's own time when the recipe has one; none is invented. Cook mode is behind `cookModeReady`; hands-free adds the switch only.
