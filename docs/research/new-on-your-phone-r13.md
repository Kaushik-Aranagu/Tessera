# New on your phone: release bbadf141

Release 13 is the next build to install.
Everything below is new compared with e149e66, the build on your phone now (release 8).
Checked against the code that differs between the two. Nothing here was run on a simulator. Exact Tess lines are quoted only where they appear in the code; the rest is described.

## Kitchen, Lists and Recipes
- **Lists is a real place now.** A shelf of your lists, and a page for each one. Counts read like "14 TO GET". Done lists tuck away under a quiet "Put away" at the foot.
  Try: open Lists (where it sits on screen is not traced yet).
- **Run it.** The option word "Run it" starts a list as a run. It then shows on Now with how many are left, and "Done" finishes it. Finishing says so and has UNDO.
- **Pick one.** The option word "Pick one" turns a list into a draw. The shelf marks it "PICK ONE". Hold on the name and one item lifts to the center. Tap takes it. Swipe left to pick again.
- **Reusable lists.** Say "done" on one and Tess asks if you want to reset it for next time. "Reset" takes a hold. "Not now" leaves it. Ten quiet seconds changes nothing.
  Try: finish a packing list.
- **Resetting nothing** is quiet: it says there is nothing to reset and has no UNDO.
- **Swipe a row left to remove it.** UNDO puts it back in place.
- **Put away** sets a run aside and keeps its basket count.
- **Paste a recipe link.** Paste only a link and the key says "Read it" instead of Save. Offline, it says "Recipe link, kept for later." and keeps the link. A link that carries a name or password is refused and never printed back.
- **Same recipe pasted twice** says "<title> is already on Recipes." and writes nothing. A private one says "Private recipe".
- **Recipe page.** Add to Groceries says what was added and has UNDO. A second add at the same size or smaller adds nothing. The portion drum scales to twice the written size. Large text stacks amounts over names. An empty recipe says "No steps yet. Paste them below." A deleted one says "Recipe gone."
  Try: open a recipe and add it to Groceries.
- **Groceries.** "Shopping, finished" has UNDO and brings the basket back. A save that fails says "Didn't save that. Try again." Lines with a price lose the price. Private items read "Private item" until you tap them.
- **Pantry** is built to show what is out or low (read from commit titles, not checked in the code).
- **Workout running.** While a workout is on, a cook or a shop will not start. Tess says "Workout running." and nothing changes.
- **Cooks and plans.** Finishing a cook closes that day's plan task. Home shows a planned cook with what is left to buy.
- **UNDO reads thing first.** A taken-back line leads with the thing, then "taken back".

## Training and rest
- **Your rest weekday** shapes the week. First launch sets Sunday. The Training week marks it as rest. Past weeks keep the rest day they had.
- **Say it to Tess:** type "rest day friday". She sets it as a setting, never a task called "Rest day". Saying the same day again changes nothing and has no UNDO. "Any day" reads "Rest day, any day."
  Try: type "rest day friday", then UNDO.
- **A planned workout beats rest.** If a session is set for today, Now and Home stop saying "Rest day" beside START.
- **Finished workout.** An empty one reads "Workout, done". A private routine title shows as "Private workout". The done line agrees in number ("1 of 1") and drops "0 of 0".
- **A workout with no sets** no longer shows as a session in the Day log.

## Review, Home and Tess
- **Weekday names** in Review are always English.
- **Times** in Claude receipts read the house clock, US month first (read from commit titles).
- **A paused list** reads paused on Home. A running list shows its name and count.
- **A list line said back** puts the thing first. A private line reads "Private item".
- **A task with money** loses the amount. If the saved title is still private, Tess says only "Task added for" the day.
- **A number beside a lift name stays a lift.** "weighed squat at 140 kg" is a bar. A morning weigh-in is still your weight.

## Backups and Settings
- **Save a copy** asks for Face ID first. With no passcode it says to set one, because the copy has your private words.
- **Copy saved.** names the thing it saved. Backups shows the real number of daily copies kept.
- **Restore** warns what the Kitchen will lose before you confirm. One built-in Groceries list always survives.
- **Key line** reads "Key saved." and nothing of the key itself.

## Quietly safer
Walls only. Claude calls refuse every redirect. Claude's replies about recipes are checked and dropped whole if they fail. Private recipes, items and lists are masked in exports and the iCloud copy. A capture miss that holds a key is never spoken back. A stored number that is not a safe whole number reads as no value, so nothing crashes on it.

## Not on screen yet
- The first-launch Sunday rest-day receipt (with UNDO) is written but has no screen.
- A set of line checks on Tess's words is merged. Nothing shows it.
- Claude's finished-workout line on Home is built. It waits behind the Claude switch.
