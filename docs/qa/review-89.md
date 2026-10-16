# QA: Tess model layer T1, PR #89 (head c0a7bbc)

*Repo maintainer (QA), 2026-10-15 19:15 UTC. Static read; focus asked: can the v2 migration or the migration retry lose or duplicate data on an existing store?*

**Verdict: the v2 migration is safe. The merging retry can't lose anything the new store holds, but it duplicates the starter plan's routines and slots when the old store had the starter plan. Not a risk for tonight's phone install (a first install has no old SwiftData store), so fix it before the next build that could meet one.**

## v2 migration: safe
- `ALTER TABLE op ADD COLUMN route TEXT; ... model TEXT` only adds columns that can be empty. Existing rows keep everything. GRDB runs it once, inside a transaction, before `load()`.
- The insert writes both columns and `load()` reads them. Exports carry `route`/`model` as optional values, so older exports still decode, and a restore copies them across.
- If the migration ever failed, GRDB reports a plain SQLite error, which isn't counted as damage, so the store stays where it is and the app runs from memory (the #84 rule).

## Merging retry: no loss, but duplicates
`restore(into:merging:)` keeps anything whose id is already in the store and adds everything else from the export. That is idempotent: running it twice adds nothing the second time. Nothing in the store is overwritten. But it decides by **id only**, and seeding gives some objects fixed ids and others fresh ones:
- **M1. Doubled starter plan.** The plan and its routines have fixed ids (`StarterContent.planID`, `starter.routine.*`). The slots under each routine get fresh ids (`store.create(slotClass, parent:)`), and so do the plan's `routines` links. If the old store had the starter plan (it seeds the same content), a retry into a seeded store keeps the seeded plan and routines and then **adds the old slots under them and the old routine links**. The result: each routine lists every exercise twice, and the plan lists each routine twice. `aMigrationCanStillRunAfterSeeding` exports from a seeded store too, so it would show this if it counted the plan's routines or a routine's slots.
  - **Fix:** in merging mode, when an object id already exists, also skip the export's objects whose parent already existed before the merge (the store's copy owns that subtree). Skip the export's links whose `from` object already existed. Workouts, notes and tasks have no parent, so they still come across, and links from them to existing routines or exercises are kept. The test should then check that the plan has 6 routines and Push A has its usual number of slots.
  - **What this costs:** changes made in the old build to the starter routines themselves (an added or edited slot) are not carried over on a retry; the seeded version wins. That is the same rule the PR already applies to the routine objects.
- M2 (low). For a class that already exists, the export's fields are skipped, so a field the user added in the old build isn't recreated. Values for it stay stored on the objects but aren't shown. That's fine while there are no user-added fields.

## Router: fine
`TessRouter.run` stamps `route`/`model` only on ops whose actor is `.tess`, so a set typed while the model is thinking isn't mislabelled. It clears the stamp after each route. Grammar errors still answer from the grammar without falling through to the model, as before. The B4 all-or-nothing behaviour is unchanged (it moved into `performSets`), and the new test now actually exercises a mid-phrase failure. #84's L3 (misplaced doc comment) is fixed.

## Re-check at 7239bd2 (19:10 UTC)
M1 fixed: a merging retry skips export objects whose parent is already in the store and links whose source is; `MergeRetryTests` checks the plan's routine count and Push A's slots. **OK to merge after the install.** Low follow-up: the skip is one level deep and doesn't cover the skipped objects' own links, so each old slot's "exercise" link is inserted with no source (harmless, backlinks drop sourceless links), and a skipped object's children would arrive as parentless orphans. Make the skip set transitive and skip links whose source is in it.
