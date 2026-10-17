# Review #669 (Core: two-decimal measures before a cooking unit are not money; addToList items test)

Head 56968341, merge-tree clean against master 54f793b7. Package-only, no screen change. Design not needed.

**Verdict: FIX FIRST (one item). The items test is fine.**

## The hole (Product asked for exactly this check)
`withoutMeasures` strips the number from `\d+[.,]\d{2}` plus a unit and leaves the unit, so a line is judged without its amount, and the money and body walls both need an amount. The unit list includes currency and body words:
- **"pounds"** is GBP. "paid 12.50 pounds for shoes" becomes "paid pounds for shoes": no amount, so not money-shaped, so it is sent.
- **"lb", "lbs", "kg", "pounds"** are body units. "weighed 82.50 kg this morning" becomes "weighed kg this morning" and "182.50 lb" likewise: his weigh-in line is no longer body-shaped and goes out.
- Any currency code with a decimal amount before a listed unit ("2.50 g usd") loses its amount the same way.
- The strip also fires after a currency sign ("$1.25 cups"). The test passes only because the leftover "$cups" still counts as a sign; that is fragile.

## Fix asked
1. Drop "pounds" from the list (it is a currency word; leave "1.50 pounds chicken" walled, fail-closed).
2. Only strip when the amount is a recipe-sized number (10 or less for cups, spoons, ounces, pounds and litres; say 1000 or less for g and ml, but only below 1000 so a body or money figure cannot hide), so "182.50 lb" and "82.50 kg" stay body-shaped.
3. Do not strip when a currency sign sits right before the number: `(?<![$£€¥₹]\s?)`.
4. Add the negative tests: "paid 12.50 pounds for shoes", "weighed 82.50 kg this morning" (with and without lastWeightKg), "$1.25 cups", "2.50 g usd".

## Checked, correct
- Regex: `\b\d+[.,]\d{2}\s*unit\b` with `(?i)`; "flour 2.50" (no unit) stays walled; "1.25 cups flour", "0.75 tsp salt" and "2.50 oz butter" pass in the new test.
- The items test: one addToList call with 15 items; count <= 10 and pending ghosts equal the returned records.

## Delta 5c23521b (merge-tree clean vs master 54f793b7)
Closed: "pounds" is out; money words, currency signs and weigh words skip the strip; amounts are capped (10, under 1000 for g and ml); the negative tests cover the six cases. The no-op return is the whole match, so over-cap amounts are untouched.

**Still FIX FIRST: the "10 kg or less" case Product asked about leaks.**
"8.50 kg today" (a baby's or a pet's weight, no weigh word, nothing near his last weight) is walled before the strip only because of `isBareWeight`'s last branch: a body word (`kg`) plus a decimal. The strip turns it into "kg today": the decimal is gone, `isBodyShaped` then has no number (`guard hasNumber`), and it is sent. Same for "9.20 lb this morning" and "7.80 lbs". The cap does not help; 10 or less is exactly where small bodies live.

Fix: take `kg`, `lb` and `lbs` out of the strip's unit list (they are the body units: PrivateFacts.bodyUnits). Keep cups, spoons, oz, g, ml and l. Recipes lose nothing new: "1.5 lb chicken" is already walled by the decimal-plus-body-word rule. Add negative tests for "8.50 kg today", "9.20 lb this morning" and "7.80 lbs", with lastWeightKg nil and 82.

## Delta 864bd4fc: PASS
kg, lb and lbs are out of the strip (regex now cups, spoons, g, grams, ml, l, litres, oz, ounces). The six new cases (8.50 kg today, 9.20 lb this morning, 7.80 lbs, each with no last weight and with 82) assert the line is not sent. None of the remaining units is a body unit (PrivateFacts.bodyUnits is lb, lbs, kg, kgs, pounds, kilos), so no body figure can pass as a measure.
