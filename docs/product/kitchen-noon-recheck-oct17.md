# Kitchen noon recheck, Oct 17 (K78)

*Docs only. Ruling (decisions 3:55, Oct 17): clocks write "12 pm", never "noon". Scope: every Kitchen doc in `docs/product/` (kitchen-*.md, pantry, lists, groceries, recipe, meal-plan, cook-mode, us-shop, parallel-steps, paste-hardening, widget files). Searched for "noon", "12 pm", "12:00" and "12pm".*

## Changes made

| File | Row | Before | After |
|---|---|---|---|
| `kitchen-refill7-acceptance.md` | K45.17 | "what's for lunch" gives "Dal, noon." | "Dal, 12 pm." |
| `kitchen-refill8-acceptance.md` | K53.6 | The tag wins: "Dal, noon." | "Dal, 12 pm." with the ruling noted |
| `kitchen-refill9-lane1-acceptance.md` | K64 source rules | noon reads "12 pm" in code (flag F5) | same, marked ruled Oct 17 |
| `kitchen-refill9-lane1-acceptance.md` | Flag F5 (K64.6) | Product to say which noon form is the house one | Ruled: "12 pm" |
| `kitchen-copy-recheck-oct17.md` | Open item 4 | No ruling exists | Marked ruled, points here |

## Left alone

- Scenario prose that describes the time of day, not app copy: `kitchen-refill8-acceptance.md` K53.2 and K53.4 ("Dal at noon"), the K53 source rules ("nearest noon"); `kitchen-refill9-lane1-acceptance.md` fixture list ("Dal at noon") and K64.18 ("before noon"); `kitchen-refill7-acceptance.md` K45.17 action column ("Dal at noon").
- `recipe-clock-dst-acceptance.md` RC4 and RC5: "12:00Z" and "12:32Z" are UTC engine times beside the PST/PDT app times, not app copy.
- No "12 pm" app-copy line existed before this pass, so none needed checking. No "12:00" appears as app copy in any Kitchen doc.
- Outside this scope (not edited): `decisions.md` line 740 ("12 is noon", a grammar rule for bare hours) and decision timestamps such as "12:12 PM Oct 16" in the decisions log and the release checklist. The grammar rule is prose about input, not an expected app line; Product may want it reworded.
