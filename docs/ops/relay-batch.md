# Relay batch

One message from the coordinator to a Mac lead, carrying everything pending for that lead. Sending several separate relays wakes an idle thread several times; each cold wake re-writes its whole context (see [worker-rotation](worker-rotation.md)).

## Format

Header line: `RELAY BATCH to <lead>, <time PT>, <n> items`. Then numbered items, one block each, four fields, in this order:

```
<n>. CHANGED: <what changed, one sentence>
   WHERE: <file path or PR number (+ head SHA if a PR)>
   ACTION: <what the lead must do, or "none, FYI">
   BY: <deadline with time PT, or "none">
```

Rules:
- Order by deadline, then by action needed; FYI-only items last.
- One sentence per field. Link a file instead of quoting it.
- The lead replies with one line per item (`<n> done` / `<n> blocked: why`), not one message per item.
- Nothing urgent waits for a batch: a deadline under 30 minutes is sent alone.

## Example (from docs/ops/board/ops.md and product.md)

```
RELAY BATCH to ios-a, 6:10 PM PT, 3 items
1. CHANGED: verdict line template is ready for QA and Design to adopt.
   WHERE: docs/ops/verdict-line.md
   ACTION: end every review comment with the verdict line.
   BY: none
2. CHANGED: test.sh speed audit is open; docs-only runs may skip stages.
   WHERE: docs/ops/test-sh-audit.md
   ACTION: none, FYI; tell Ops if a stage you need was skipped.
   BY: none
3. CHANGED: Product asks for a v1 acceptance pass against the latest recordings.
   WHERE: docs/ops/board/product.md (Next, item 1)
   ACTION: add any gaps you find to docs/ops/board/ios-a.md Next.
   BY: none
```
