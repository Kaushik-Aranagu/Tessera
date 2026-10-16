# QA review 354: scripts/kitchen-week-one.py (Kitchen lead)

*QA, Oct 16, about 2:00 AM Pacific. PR #354, head `bcaa763`. Static read against the real GRDB schema
(`TesseraCore/Sources/TesseraCore/Model/TesseraDatabaseSchema.swift`) and the catalog on master. The cloud has no
Simulator, so the demo-store run the coordinator asked for needs a Mac session. These findings come first anyway,
because F1 zeroes every count.*

## Verdict: FIX FIRST (on a real store, every count prints 0)

### F1. Class keys carry a "system." prefix

The script maps `classDef.systemKey` and then filters on bare names: `live("recipe")`, `"cook"`, `"process"`,
`"kitchenTimer"`, `"list"`, `"listItem"`, `"ingredient"`, `"task"`. On a real store the stored key is
`SystemCatalog.Key.systemKey`, which is `"system.\(rawValue)"` (`SystemCatalog.swift:25-27`), so every class
lookup comes back empty. The recipes, cooks, timers, grocery and planned-cook lines all print zero, and the script
doesn't fail. The synthetic store must have used bare keys.

**Fix:** strip the prefix when building `classes`, e.g. `(k or "").removeprefix("system.")`. Then add a check:
exit non-zero if `system.recipe` isn't found at all, so a wrong store can't print a clean row of zeros.

### F2. Values written by older builds are skipped silently

`FieldValues` decodes two forms: the keyed object used now, and the flat `[id, value, id, value]` array that
earlier builds wrote (`FieldValue.swift`, `init(from:)`). Objects that haven't been written since then still hold
the array. The script calls `json.loads(raw).items()`, which raises `AttributeError` on a list. It catches that
and marks the object `_unreadable`, so those objects lose every value: no `cookedAt`, no `isStaple`, and so on.
**Fix:** when the JSON is a list, pair it up (`zip(a[::2], a[1::2])`). Also print how many objects were
unreadable, so it's never silent.

### F3. "link" recipes can never be counted

There's no `sourceURL` field in the catalog. A recipe stores only `sourceText` (`SystemCatalog.swift:271`), and
`CreateRecipe` writes the parsed source text (`Kitchen/Recipes.swift:147`). So `how["link"]` is always 0, and
linked recipes count as "pasted". Two options: tell link recipes apart by the op's route or summary, or say in the
output that link and paste can't be told apart.

## Checked and fine

- **Read-only.** It opens with `mode=ro` and never writes.
- **Dates.** Row dates are Unix seconds, which matches the schema ("dates as seconds since 1970"). Dates inside
  `values` are Swift's default 2001-reference seconds, which matches `Models.swift`'s plain `JSONEncoder`.
- **Values.** The `FieldValue` shape `{"date": {"_0": …}}` is the synthesized Codable, and field ids match
  `fieldDef.id` (uppercase UUID strings).
- **Op table.** `route` is only checked if present (migration v2), which is correct.
- **Names exist on master.** These field keys: `sourceText`, `lastOpenedAt`, `cookedAt`, `ownerApp`, `endReason`,
  `endsAt`, `shares`, `isStaple`, `subject`. These action names: `createRecipe`, `editRecipe`, `stopKitchenTimer`,
  `addGroceries`, `checkListItem`, `startShop`, `finishShop`.
- **Safety.** Standard library only. No network, no `exec` or `eval`, no shell, no key handling.
  `capture-misses.jsonl` is read only if it's present.

## Lows

- `--since` builds its date as UTC midnight. "Since Oct 15" in Pacific starts 7 hours earlier than he'd expect.
  Give the time zone with the date, or document it.
- The Groceries list is found by title. `Groceries.listID` is a stable id in the engine, so match on that instead,
  in case he renames the list.

## The demo run

Once F1 and F2 are in, a Mac session (Core or a Builder, on the Simulator) should:

1. Run `-demoTime 18:10 -resetDemo`.
2. Copy `~/Library/Developer/CoreSimulator/Devices/<id>/data/Containers/Data/Application/<id>/Library/Application
   Support/Tessera/tessera.sqlite` somewhere else.
3. Run the script on the copy.

The demo seeds recipes, a cook and Groceries rows, so a non-zero recipe and grocery line is the pass. QA can read
the output if it's pasted into the shared folder.

## Addendum: re-check at `ea0f9b1` (Oct 16, about 2:50 AM Pacific): PASS

Trial merge onto master: clean. 2 files (+243/-1): scripts/kitchen-week-one.py, docs/product/kitchen-v2-scope.md.
It compiles (`python3 -I -m py_compile`); not run against a store here.

- **F1 closed.** `classes` strips `"system."` (`removeprefix`), and the script exits 1 with a plain message when
  there is no `recipe` class, so a wrong store can't print a clean row of zeros.
- **F2 closed.** `value_pairs` reads both the keyed object and the older flat `[id, value, …]` array, and an
  unreadable count prints as a WARNING line at the top instead of being dropped silently.
- **F3 closed.** One count, "pasted or from a link", with a comment saying why the two can't be told apart; the
  capture-miss log still counts links that failed to read.
- **Lows closed.** `--since` is midnight Pacific (`ZoneInfo("America/Los_Angeles")`). Groceries match on
  `Groceries.listID`: `stable_id("kitchen.groceries")` reproduces `SystemCatalog.stableID` exactly (SHA-256 of
  `"tessera:<name>"`, first 16 bytes, version 5 and variant bits set, uppercased).
- **scripts/ checks.** Standard library only, opens with `mode=ro`, no network, no `exec`/`eval`, no shell, no key
  handling, writes nothing.

The demo-store run still needs a Mac session; I'll read its output when it's in the shared folder.
