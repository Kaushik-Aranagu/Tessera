# Review: PR #316, lows from #305, #306 and #309, plus the bare add (head 06ebf46)

QA thread, Oct 15 PT. Static review. Base 865e465, which is current master. 9 files (+112/-15). Most of the TessGrammar changes are comment-only, "mum" to "mom".

**Verdict: PASS.** One should-fix (S1, a no-op capture gets a record) and one low can ride a later PR.

## Checked
- **#306 L1, closed:** the otherNames overlap now compares whole words (PlanWording.swift:149-153). An empty title no longer drops every name, and "pasta" no longer overlaps "pastry bake".
- **#306 L2, closed:** "busy" is not remembered for the day (:466-469).
- **#306 L5, closed:** `URLError.cancelled` and `CancellationError` inside `send` now throw `CancellationError` (:588-593), so a closed view is never remembered as "other".
  - On a 20 s timeout, `withDeadline`'s sleep child throws `timeout` first, so a timeout is still remembered as one.
- **#305 L1, closed:** a test seeds v5 over a v4 store (packageVersion set back to 4). The look setting and the object count are unchanged.
- **#305 L4, closed:** `clearWaiting()` soft-deletes every waiting phrase.
  - Low for Builder B: this has no ops, so there's no UNDO. The undo rule wants a 10 s UNDO on a destructive write, so either ask first or keep the rows until the UNDO window closes.
- **#309 L4, the bare add, closed:** a bare name (no amount, no unit, not from a recipe) joins the first open row for that ingredient, sized or not, and leaves the count alone (Groceries.swift:181-190). "1 (15 oz) can chickpeas" then "buy chickpeas" stays "1 can". Two "oat milk" stay one row. Sized adds still add.
- **#309 L3, pound cake:** "1 pound cake" is now amount 1, no unit, name "pound cake". "1 pound carrots" is still lb (tested).
  - Low: `name.hasPrefix("cake ")` also turns "1 lb cake flour" and "1 pound cake flour" into "pound cake flour" with no unit, and cake flour really is sold by the pound. Match only `name == "cake"`, and only when the unit word was "pound"/"pounds" and not "lb".

## S1 (should fix): "already on Groceries" still writes a record with UNDO
- When the bare add finds the row, `addGroceryShare` returns it without writing anything. `AddGroceries` then returns a record with no ops, and capture says "Chickpeas, already on Groceries." (TessCaptureEngine.swift:310-323).
- That record still goes back as the capture's record. From the Write line, which isn't commitImmediately, it becomes a pending ghost with an UNDO that undoes nothing, and an empty op row in the log.
- Fix: when `!made` and nothing changed, discard the record and return the line with no records (`records: []`, no UNDO), the way a reply is shown. Test it with a pending context, not only `commitImmediately: true`.
