# Kitchen choices as Review switches (Oct 19)

Kitchen lead, for Product's Review section (`review-choices-oct19.md` rows 1 to 19; these continue at 20). Docs only, nothing built or run. Rule from Product's huddle push (12:30 PM PT Oct 19): every open choice is a Settings switch he flips live, default is today's behavior, and off or default must look and act exactly like master. Rows keep the Review copy rules: plain words, no "at" before a clock time, one before/after line each.

## Rows

| # | Name | Values | Default | Screen it changes | Before / after |
|---|------|--------|---------|-------------------|----------------|
| 19 | Link fetch (Product's row, wording added) | Off / On | Today | Recipe from a website | Off: a link is never opened; you paste the recipe text. On: Tess reads the page and fills the recipe, "Reading <host>." |
| 20 | Cook timer voice | Alert only / Alert and spoken line | Today's setting | Cook mode, when a step timer ends | Alert only: the notification and the flare, nothing said. Alert and spoken line: Tess also says it, "Simmer is done." |
| 21 | Pantry state | Off / On | Off | Recipe page, Groceries, Pantry screen | Off: no "have it / low / out" state anywhere, Groceries as today. On: each ingredient can say have, low or out, and Groceries skips what you have |
| 22 | Can cook shelf | Off / On | Off | Kitchen front page | Off: no shelf. On: a CAN COOK shelf of recipes you can make now; it stays grey until 60% of a recipe's lines are known (floor 3), unknowns read "1 to check" |
| 23 | Hands-free cook mode | Off / On | Off | Cook mode | Off: cook mode as built, you touch the Next key. On: you can move through the steps by voice (the exact words are not written yet; Design and Builder A decide) |

## Notes for Product

- Row 19 is Product's. The before/after line is added; "Reading <host>." is DEC 522.
- Row 20: "timer voice" is read here as whether Tess speaks the timer end. I could not find a written definition. Builder A confirms what master does today and sets the default to that. If it means something else (a voice choice), say so and this row is redone.
- Rows 21 and 22 depend on the Pantry v2 work (`core/pantry-1`, 868e25d1, not merged at writing). Until it merges the rows ship disabled with the default.
- Row 23 is the "hands-free cook mode moves up" outcome of week-one question 3 (`kitchen-week-one-questions-oct22.md`); nothing is built yet, so it is a placeholder row.
- Week-one question 2 (a recipe from a website) is row 19. Question 1 (do you want to know what you already have) is rows 21 and 22. Question 3 (reached for something else) is row 23; its Paper and Messages answers lead to an at-the-shop mode review, which is a review and not a switch, so no row.
- Oct 22 morning packet is unchanged: counts at 8:00, message to Product by 9:00. Kitchen v2 stays scoped from his answers.
