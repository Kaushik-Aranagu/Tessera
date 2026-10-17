# Review #672 (Core: plan pack uses the Home pack's wall)

Head 78073b3c, merge-tree clean against master 27151f75. Package-only, dormant behind planWordingReady, so no screen change. Design not needed.

**Verdict: QA PASS.** Closes the FIX in qa/audit-walls-d6fd9ca.md.

- `PlanPack.isPrivate` is now secret words or `HomeDonePack.isWalled` (health, money, place, care and people words, key shape, body, set-notation rules). `packTitle` and `isOpen` both go through it, so "Physio at 5", "Call mom about the lawyer" and "Pay Dr Lee" pack as "task", and events still pack as "busy".
- The V13 `otherNames` list stays on the narrow wall (secret words and PrivateFacts), which is right: those names are checked against a reply and never sent, so "Mum's birthday" still catches a reply that names it.
- Tests: the d01 fixture now expects "Book physio" as "task" (every other fixture title unchanged, so nothing else got over-walled); three new rows assert `isPrivate` true, the title absent from `pack.json`, and "Fix bike light" still open.
- Cost, accepted: a task title with a 3-digit number or a decimal ("Print 100 flyers") now packs as "task" too, because the Home wall treats long numbers as private. It only makes plan wording less specific.
