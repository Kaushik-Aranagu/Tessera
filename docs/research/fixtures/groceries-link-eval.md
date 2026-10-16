# Groceries link eval: the `linkItems` gate fixture (AI-12)

*Kitchen lead, 2026-10-16. The fixture behind the match eval in `docs/product/groceries-ai-acceptance.md`. The AI thread runs it (3 runs, Haiku 5.5, effort low, 8 s) with the same harness as `grammar-miss-claude.md`; Core's pack snapshot test uses the same week. Every row is checked against the 10 seed recipes in `docs/product/kitchen-seed-recipes.md`.*

## The planned week

| Handle | Recipe (seed) | Day |
|---|---|---|
| r1 | Salmon rice bowl | Tue |
| r2 | Chilli con carne | Wed |
| r3 | Shakshuka | Thu |
| r4 | Tomato and basil pasta | Sat |

Uncovered ingredient handles in the pack, after staples and the phone's own same-key links are taken out: i1 salmon fillets, i2 basmati rice, i3 avocado, i4 cucumber, i5 spring onions, i6 lime, i7 beef mince, i8 onion, i9 red pepper (r1 none; r2, r3), i10 chilli powder, i11 ground cumin (r2, r3), i12 chopped tomatoes (r2, r3), i13 kidney beans, i14 tomato puree, i15 beef stock, i16 smoked paprika, i17 eggs, i18 feta, i19 parsley, i20 spaghetti, i21 cherry tomatoes, i22 parmesan, i23 basil.

**Shared ingredients.** An ingredient two planned recipes use (red pepper, ground cumin, chopped tomatoes) is one handle listing both recipes. The ask names the sooner recipe ("Capsicum, for the chilli?"); KEEP covers both.

## Rows the phone links itself (never in the pack)

Same `IngredientLine.key`, so the list merges them silently; the snapshot test proves they're absent from the pack.

| Typed | Links to |
|---|---|
| 2 limes | i6 lime |
| eggs | i17 eggs |
| spring onion | i5 spring onions |
| salmon fillet | i1 salmon fillets |
| 400g chopped tomatoes | i12 chopped tomatoes |

## The 24 candidate rows

**Must** rows come back in every run with exactly that pair. **Never** rows come back with no pair in any run (any pair is a false pair). **Either** rows may come back with the named pair or nothing; any other pair is false.

| # | Typed row (ingredient title in the pack) | Expect | Pair | Why |
|---|---|---|---|---|
| 1 | scallions | must | i5 spring onions | Same thing, US name |
| 2 | capsicum | must | i9 red pepper | Same thing, other name; shared handle, ask names the chilli |
| 3 | bell pepper | must | i9 red pepper | |
| 4 | ground beef | must | i7 beef mince | |
| 5 | tinned tomatoes | must | i12 chopped tomatoes | |
| 6 | tomato paste | must | i14 tomato puree | |
| 7 | parmigiano | must | i22 parmesan | |
| 8 | veg stock cubes | never | | The chilli wants beef stock; the soup isn't planned |
| 9 | beef stock cube | must | i15 beef stock | |
| 10 | cherry toms | must | i21 cherry tomatoes | Shortening |
| 11 | coriander | never | | Not parsley, not basil |
| 12 | lemongrass | never | | Not lime |
| 13 | lemons | never | | Not lime; the traybake and soup aren't planned |
| 14 | spring greens | never | | Not spring onions |
| 15 | sour cream | never | | Nothing planned uses it; not feta |
| 16 | chilli flakes | never | | Not chilli powder |
| 17 | cumin seeds | either | i11 ground cumin | A form of the same spice; he may mean it |
| 18 | red onion | either | i8 onion | A variety; the chilli can take it |
| 19 | brown rice | either | i2 basmati rice | A variety; the bowl can take it |
| 20 | sweet potatoes | never | | Nothing planned uses potatoes |
| 21 | coconut milk | never | | Nothing planned uses milk |
| 22 | linguine | either | i20 spaghetti | Pasta swap he'd accept |
| 23 | rocket | never | | Not basil |
| 24 | paprika | either | i16 smoked paprika | He may mean it |

## Pass bar

- 10 of 10 must rows pair correctly in 3 of 3 runs.
- 0 false pairs in all 72 row-runs (a never row with any pair, or a must or either row with a different pair).
- At most 6 pairs per call, one per row; a reply breaking that is dropped whole by the phone and counts as a failed run.
- The pack snapshot for this week holds the 23 ingredient titles, the 24 row titles with their handles, and no amounts, typed text ("400g", "2 "), prices, shops, notes or `checkedAt`. The 5 phone-linked rows are absent.
- Cost: about 1,500 tokens in and 150 out per call, under $0.001 a run.

## A note on "either"

The gate is asymmetric on purpose: a missed link costs one duplicate row he can delete, a wrong link puts the wrong thing in his basket. The instructions tell the model to leave a pair out when unsure, so "either" rows exist to keep that caution from being scored as a miss.
