# QA review: #457 Siri "Add a Task" secret guard (Core, QA I3)

Head checked: `2f2d9d9` (core/siri-task-wall, 1 commit). `git merge-tree` against master is clean. Static review only; Core reports 444 package and 137 app tests green.

**Verdict: PASS.**

- **Secrets.** `CreateTaskIntent.add` (Intents.swift:134-145) does three things:
  - Refuses a Claude key with `TessRouter.keyLine`, writing nothing.
  - Files `SecretWords.hasValue` text as `CreateNote(body:isPrivate: true)`, as `.intent`. Its title is "Private note", there are no links, and Spotlight is skipped by #422's private-note rules.
  - Otherwise makes the task as before.

  So "door code 4417" never becomes a task title, a Spotlight item or anything Claude sees; this path has no Claude call at all. The rule is the Bar's: `hasValue`, not `mentions`. So "reset my PIN" stays a task, as it does when typed, and the test pins that.
- **Money and body.** Nothing to wall here. #451's wall is about what reaches Claude, and Add a Task never calls Claude. "pay rent 2100 friday" said to Siri becomes a task titled that way. That is the decided W4 shape (a payment to do is a task) and stays on the phone. Claude only sees task titles through the Plan my day pack, which audit A4 screens before it is wired.
- **Plain tasks.** Unchanged: the same `CreateTask` with `startsAt`, and the same "<summary>." dialog.

**Siri's spoken lines (Design):** two are new to Siri, and both copy existing lines exactly.
- "Private note, kept." is `SecretWords.title` + ", kept.", the SW3 line, with no UNDO, since Siri has none.
- "That looks like a Claude key. It goes in Review, under Claude." is the Bar's key line.

## Lows (non-blocking)
- L1: a spend said to Siri ("spent $23.47 at trader joe's") becomes a task. Typed in the Bar, the same phrase is a miss ("Didn't catch that."). That's a difference in where it files, not a leak; MU1 (spends on the phone) is where it gets a real home.
- L2: the private note drops `startsAt`, which is correct, since a secret has no time. The test file holds a fake key literal for the refusal check. It is clearly a placeholder, but the docs-side secret grep would match it if the test were ever copied into docs.
