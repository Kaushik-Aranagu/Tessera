# Money: the receipt total instrument (M5 screen 5, steer)

> **US shop (item 25):** aisle names, amounts, fractions, pack sizes and merging for a US kitchen are in `kitchen/us-shop.md`, which wins over this sheet's metric and UK examples.

For Builder B, after Core's `ShopReceipt` and `LogShopTotal` (ship-list-m5-money slice 3). It is drawn to `no-buttons.md`. Recording: `recordings/money-dial.mp4` (source `studies/money-dial.html`).

## The ask lives in Now
- While a total is awaited, Now reads **"Groceries total?"** at Hero, with the context line "the shop you finished at 5:40" in Body.
- **Tap Now** to z into the instrument: the Now line grows into the title, and the rest of Home fades back. There is no sheet and no card.

## The instrument
- **Label:** "GROCERIES · 5:40 PM" (16/700). **Title:** "Total" at 44.
- **The amount dial is the weight dial's sibling, as two drums on one baseline:**
  - **Whole units:** 96 Light tabular, 100pt rows. A drag tracks the finger; a flick coasts with an ease-out cubic over about 620ms and ticks `.selection` once per number.
  - **The dot:** at 96, fixed between the drums.
  - **Cents:** 56 Light tabular, 60pt rows, drag with momentum, `.selection` per step.
  - Both drums fade to 25% at the top and bottom edges (a mask, never a box). The current row is full ink.
  - The drums open on the last shop's total.
- **One sentence under the dial (Body 21):** "In **no currency**. Last shop was **41.60**."
  - **The currency is a value word.** A tap cycles none, €, £, $, ₹ (rolled, 380ms). It is stored as chosen and never converted.
  - **"41.60" is a value word too.** Tapping it sets both drums to it.
- **Rather type?** Tap the numeral and it becomes a field in place at the same size, with the decimal pad. Return goes straight to Log.

## Acting
- **"Log £38.20"** is a stroke word in sage at Title 34 that tracks the drums live. A tap logs it via `LogShopTotal(amount, typed, currency?)`, with `.made` (Motion lab #963: the drums travel 420 ms to the amount, e.g. "41.60", then `.made` once).
- **SKIP** is a label word on the right, calling `SkipShopTotal`. The question never comes back.
- **After logging:** the instrument folds up (scale 0.96, −20pt, fade, 360ms), the next Now rises in its place, and Tess says **"Groceries, £38.20. Logged."** beside her soul with UNDO. After a skip she says "No total. Fine."
- There is no `.success`, no confetti, and no month total here. The month line lives on the Month page.

## Accessibility and Reduce Motion
- Each drum is an adjustable element: "Pounds, 38" and "Pence, 20" with increment and decrement. The currency reads "Currency, pounds, button".
- **Reduce Motion:** the drums step without coasting, the z is a cross-fade, and the fold is a fade.
