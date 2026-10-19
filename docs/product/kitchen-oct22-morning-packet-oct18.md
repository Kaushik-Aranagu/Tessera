# Oct 22 morning packet (Kitchen lead, Oct 18)

Static check only: `python3 -I scripts/kitchen-week-one.py --self-test` runs clean on master 892befd (Oct 18, 7:10 AM PT). Nothing here was run against Kaushik's real store.

## Order of the morning (Thu Oct 22, Pacific)

| Time | Who | Step | Done when |
|---|---|---|---|
| 8:00 | Builder B (Mac) | Copy the store from the phone: Settings, Backups, make a `.tessera` backup, then copy that file to the Mac. Never point the script at the live store. | One `.tessera` file on the Mac, path sent to the Kitchen lead (path only, no contents). |
| 8:15 | Builder B | `python3 -I scripts/kitchen-week-one.py <backup.tessera> --since 2026-10-15` (add `--titles` only if Kaushik asked; private titles then print as "Private recipe"). If `capture-misses.jsonl` is beside the store, the script reads it; it never rides in a backup. | Counts printed; no title printed. |
| 8:30 | Kitchen lead | Fill the brackets in `kitchen-v2-scope.md` ("The Oct 22 message") from the counts. Mark the default cut as the recommendation. | Message drafted. |
| 9:00 | Kitchen lead | Send to Product (cross-session), full text in the message. | Product has it by 9 AM. |
| 9:30 | Product / coordinator | The riders and signing check (trigger 9:30) runs at the same hour; do not wait on it. | n/a |

## If something is missing

- No backup yet (phone not reachable): send Product the empty-week default from `kitchen-v2-scope.md` with "no counts yet" in the first line, and say the counts follow.
- Script prints "no capture-misses.jsonl": normal; say "capture misses: not read" in the message.
- Script errors on the file: send Product the one-line error text only (no file contents), and keep the default cut.

## What changed since the scope page was drafted (read before sending)

1. Pantry v2 is built but not shipped; week one counts do not include pantry state. Do not report Pantry numbers.
2. No drawn food stand-ins anywhere (Kaushik, Oct 18 1:29 AM): the v2 options list must not offer a recipe-plate wash, a pocket for an Ingredient or any food drawing. A recipe shows his photo or nothing.
3. Private items, recipes and lists are dropped from every count by the script; do not hand-add them back.
4. The message is plain words, one recommendation, options as pictures not letters (Kaushik's rule). Times read "8:30 pm", no "at" before a clock time.
5. Nutrition only if Kaushik asks (sheet 75: the app never sums nutrition).

## Checks I will run before sending

- Row count of the script output against `kitchen-week-one.md` (every row of the table has a count or "not recorded").
- Any row reading "not recorded" goes to Product as a small Core item the same morning.
