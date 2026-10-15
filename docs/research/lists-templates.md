# Lists: templates, pick one, paste

For: Kitchen lead (Lists), Product lead, Core engine
Date: 2026-10-15

## What others do

**Reusable lists: reset or copy?**
- Things has no template feature. You keep a project or checklist to-do in Someday and Duplicate it each time; dates are not adjusted ([Things support](https://culturedcode.com/things/support/articles/2693493/)).
- Apple Reminders: More > Save as Template, then More > Templates > Create. Later edits to the list do not change the template, so it is a snapshot ([Apple](https://support.apple.com/en-asia/119953)).
- Todoist: a template makes a new project or imports into an existing one ([Todoist](https://www.todoist.com/help/articles/introduction-to-templates-in-todoist-uofJ8i40M)). Notion database templates prefill new pages; repeating templates make a new page on a schedule ([Notion](https://www.notion.com/help/guides/automate-work-repeating-database-templates)).
- Checklist apps (Checklist by Koji Ito, packing apps) do both: "Uncheck All" to reuse in place, plus templates for a fresh copy ([App Store](https://apps.apple.com/app/id521946672)).
- Pattern: task apps copy; packing and checklist apps reset. Copy suits a one-off trip that you will edit; reset suits a daily routine.

**Pick one.** We found no native random or "next" pick in any of these apps. People use Shortcuts or separate decider apps. Open space, no convention to follow.

**Pasting a block of text.**
- Things: Cmd+V of plain text makes one to-do per line ([shortcuts sheet](https://kapeli.com/cheat_sheets/Things.docset/Contents/Resources/Documents/index)).
- Todoist: pasting several lines asks "Add X tasks?" with an option to keep it as one task ([Todoist](https://www.todoist.com/help/articles/add-or-manage-multiple-tasks-in-todoist-PcPoskdUp)).
- AnyList: one item per line, auto-categorised ([AnyList](https://help.anylist.com/articles/paste-items/)); quantity lives in a separate field, not parsed from the name in the docs ([AnyList](https://help.anylist.com/articles/add-item-quantity/)).
- Reminders grocery lists sort items into sections and remember a section you move an item to ([Apple](https://support.apple.com/en-la/105086)). Paprika merges recipe ingredients into an aisle-sorted grocery list ([Paprika](https://paprikaapp.com/)).
- Nobody we checked documents nested paste. Bullets and numbers are mostly left to the user.

## Changes to ship-list-lists.md

1. **Slice 4, add "Copy" next to "Reset".** A reusable list gets a second verb: copy it as a new list with everything open ("Packing, Lisbon"). Why: both camps exist for a reason; a trip list gets edited and should not change the master. One engine command, no template object. Keep the word "reusable", not "template" (see conflict below).
2. **Slice 3, read quantities and flatten nesting.** Read "2 x milk", "milk x2", "milk (2)" and "500g flour" into the item's quantity. An indented line under a plain line becomes an item in a section named by that parent line (one level, matches "flat with one level of sections"). Strip "-", "*", "•", "1.", "1)", "a)". Why: pasted recipes and notes are full of these; nobody else handles nesting, so flattening is enough.
3. **Slice 3, the whole paste is one undo step.** No "Add 12 items?" prompt like Todoist; Tess's line ("Twelve things, two sections") plus one undo replaces it. Why: fewer questions, ADHD-friendly, and undo already exists.
4. **Slice 3 and 8, pasting into an existing list merges.** Same name already open: add to its quantity. Same name already checked: uncheck it. Why: AnyList, Paprika and Reminders all avoid duplicates; on a reusable list a re-paste then acts like a partial reset.
5. **Slice 7, define a skip.** Swiping a pick away is a "skip", not a pick: it does not set `pickedAt`. Picking never checks the item. Why: otherwise the 7-day weighting learns from rejections and hides things you just did not fancy tonight.

## Conflict with M3 slice 10

M3 slice 10 makes a new **user class** from a "List" template ("items with done"). Lists says every list is one instance of the kitchen `List` class. If slice 10 builds a class per list, Films and Packing become two schemas and Lists can't show them on one shelf. Fix: slice 10's List template creates a `List` object (as ship-list-lists.md already says), and only Tracker and Log make new classes. Also "template" means a class blueprint in M3, so Lists should avoid the word for reusable lists.

## For Kaushik (yes/no)

- Reusable lists get both Reset and Copy? (recommend yes)
