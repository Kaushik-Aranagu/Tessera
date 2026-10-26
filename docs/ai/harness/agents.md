# Persistent agents: one per room, each its own character

Kaushik, Oct 26: "multiple agents having their own personalities for each of the rooms ... coordination between
them and Tess, the main agent personality we would be talking to ... we'll only spawn them if a new room is created
or a new app is created ... agents are supposed to persist ... it needs to feel like you're talking to the same
person ... each agent knows exactly what its memory is like ... common memories across all the agents ... their own
memory per agent or a coordinator."

The reading taken: **he talks to Tess.** Room agents work for her and report back in their own character, and she
answers him (she may pass a line on: "The Deck says ..."). Agents reach each other only through her.

Code: `TesseraTess/Harness/Agents/` (`Persona.swift`, `AgentSpec.swift`, `AgentRegistry.swift`,
`AgentNotebook.swift`, `AgentEpisodes.swift`, `AgentContext.swift`) and three system classes in `SystemCatalog`.
Tests: `AgentsTests.swift`, `AgentSpecTests.swift`.

## 1. The agents

| Agent | Room he sees | Reads | Personality |
|---|---|---|---|
| Tess | Tess | Every room | The one he talks to; a chief of staff |
| Today | Bridge | Tasks, lists, routines, occasions (lab) | Keeper of his day, calm, one thing now |
| Notes | Log | Notes | Exact, remembers his own wording |
| Training | Deck | Workouts, exercises, routines, plans, sets | Coach at the chalkboard, numbers first |
| Kitchen | Galley | Recipes, ingredients, cooks, places | Line cook, tickets and timing |
| Watch | Watch | Routines, runs, rests | Groundskeeper, a missed day is weather |
| Lookout | Lookout | Beliefs about him only (weather is live) | Reads the sky in terms of what he'll do |
| Money (lab) | Purse | Spends, pools, inflows, moves | Bookkeeper, "about" amounts, read only |
| Body (lab) | Body | Sleep, steps, resting heart rate | Calm observer, never diagnoses |

`name` stays the budget and night-pass key, so nothing measured so far moves. `title` is what he sees, and
`AgentSpec.named` takes either.

## 2. Objects, and spawning

- **Agent objects.** `AgentRegistry.sync()` mirrors the shipped specs into Agent objects (`tessAgent`) so he can see
  each one. It writes no ops, is idempotent, and updates a row in place when a spec changes. The values in
  `AgentSpec` stay the source.
- **Spawning.** `AgentRegistry.spawn(room:title:classIDs:)` is the only way a new agent appears, for a new room or
  app.
  - A second call for the same room returns the same agent.
  - A shipped room is refused.
  - A name clash gets a number ("Deck 2").
  - A private room ("Therapy") is kept as "Private room", with its room key stored as a digest keyed by this
    install's salt (in the Keychain, after first unlock, this device only; never the store or a phone backup),
    because Agent objects ride in backups and the export. A backup can't confirm a guessed name. After a restore on a new install, that room's next spawn makes a fresh
    "Private room" agent; its notebook and episodes were never copied anyway.
  - A spawned agent gets plain reads plus `remember`, `createNote` and `createTask`, reads its room's kinds, has no
    sub-agents, and starts from a plain personality he can reshape.

## 3. Memory, virtualized

| Memory | Where | Who | Kept |
|---|---|---|---|
| Shared record and beliefs | His objects, `belief` | Every agent, through its slice (`memory-scopes.md`) | As his data |
| Notebook | `notebookPage`, `/memories/<agent>/...` | That agent only | Until it deletes the page |
| Episodes | `agentEpisode` | That agent only | 90 days |

**Notebook walls:**
- The path must be in its own folder, and the page must carry its own name.
- Nothing key-shaped, no secret word, no word of a private thing.
- At most 40 pages of 4,000 characters each.
- A page written under lab is never read under strict, and strict never writes a twin of it.
- The tool is `notebook`, with view, create, str_replace, insert, delete and rename.

**Episode walls:**
- A walled line is stored as "Something private" and held back.
- Anything about a money, health, body or calendar thing is lab only.
- Never in a backup, the iCloud copy or an export: both classes are in `PrivateWords.mirrorClassKeys`.

## 4. Continuity

`AgentContext.blocks(for:)` is where every run of an agent starts:
1. **Who it is** (cached for an hour): its personality, who it works for, and its memory rule.
2. **What it keeps** (cached for five minutes): its notebook's pages, the beliefs in its slice (most important
   first, up to 20), and its last 8 episodes with Tess.

So the Deck that answers on Friday starts from what it said on Tuesday, and the Galley never starts from the Deck's
memory.

## 5. For Core to review

The four places, for each new class:

| Class | SystemCatalog | Ops and ActionRegistry | Copies (PrivateWords) | ObjectPrivacy label |
|---|---|---|---|---|
| `tessAgent` | key and spec | None: written without ops, no action to decode | Copied: rides in backups and the export, so a spawned room's agent comes back with a restore. Nothing private in it (name, room, personality, notebook path) | None: not private |
| `notebookPage` | key and spec | None: written without ops | Never copied: `mirrorClassKeys` (no op, no backup, no iCloud copy, no export) | Always the memory label |
| `agentEpisode` | key and spec | None: written without ops | Never copied: `mirrorClassKeys` | Always the memory label |

- **SystemCatalog:** `tessAgent`, `notebookPage` and `agentEpisode`.
- **PrivateWords:** the last two join `mirrorClassKeys`.
- **TessRun:** the `notebook` tool in `toolSpecs()` and `runTool`, run against `agent`'s scope.
- **Your call: the launch hook.** Call `AgentRegistry(engine:).sync()` once the harness starts, and
  `AgentEpisodes.expire()` with the turns' expiry. The make-a-kind flow (a new room or app) calls
  `spawn(room:title:classIDs:)`.

## 6. Next

- **Tess coordinates (`ask_agent`).** She runs one or more room agents in parallel, each from its `AgentContext`, its
  own scope and its own tools. Each report is kept as an episode, and she answers him.
- **Test-world checks:**
  - Continuity: "what did we decide last week" answered from an episode.
  - Scope: Galley can't reach the Deck's notebook.
  - Spawn: a new room makes one agent, and only one.
