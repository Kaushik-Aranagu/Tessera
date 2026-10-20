# Review switch addendum (Design item 110)

Kaushik's huddle push (Oct 19, 12:30 PM): anything that needs his opinion ships as a Settings review switch. Rows for the switches added since sheets 100 and 103. Same row grammar as 100: a sentence with a value word that cycles; the sentence never names what is not drawn; each value word is a 44 pt target; no cards, no pills, no toggles.

Page placement (the four-tab Review of #1137: Looks and day, Workout, Connected, Shown):
- Looks and day: "Tab neighbours are **blurred**." (key `tabs.neighbours`, values Blurred / Crisp, default Blurred, his pick 4:38 PM). Also "Reading layout is **off**." stays as in sheet 99.
- Workout: "Calories burned are **off**." (key `caloriesBurned`, Off / On, default Off). On shows the kcal line on the long-press sheet and a finished workout; it needs the Me page's weight and height, so with no profile the sentence reads "Calories burned are **off**. Add your weight under Me." as two lines, the second in `inkSecondary` 16. "Energy check-in is **off**." (key `energyCheckIn`, Off / On, default Off; sheet 112).
- Connected: "Tess asks Claude: **yes / no / later**." is the Claude gate (sheet 106); nothing new here. "Backups restore asks first." is not a switch.
- Shown: the existing rows only.

Rules:
- At most six switch rows on a page (sheet 100). The addendum fits: Looks and day 4, Workout 5, Connected as built.
- A switch whose feature is not built yet is not drawn (no "coming soon").
- Review rows never write under -demo, and are never in settings export, the catalog or backups (ReviewChoices).
- VoiceOver: each row reads as one sentence plus "button, double tap to change to <next value>".
- Reduce Motion: a value change is a 150 ms crossfade of the word.
