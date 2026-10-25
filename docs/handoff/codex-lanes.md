# Codex lane coordination

Recovered Oct 24, 2026, about 2:37 AM PT from the Oct 24 lane handoffs,
the older Ops team matrix, and live branch, PR, and Mac job state.
This is the Codex dispatch map. The lane handoffs remain the detailed queues.

## Current budget override: Oct 24, 5:14 AM PDT

Kaushik explicitly revoked the 54% usage stop. He wants the remaining weekly
allowance used productively by tomorrow, with approved designs built, tested,
verified and installed on his phone. At this checkpoint the live account was
57% used, 43% remaining. Do not preserve that remainder for the Friday reset.

- The working target remains Sunday Oct 25 at 5:00 AM Pacific. Use the remaining
  allowance for useful shipping work, not repeated reports or spending for its
  own sake. Stop at the actual provider limit or the work-window cutoff.
- Keep the small pipeline. A lane waiting on CPU work is not a reason to wake
  all teams. Pipeline the next ready implementation slice, with independent
  review when a concrete diff is ready.
- First clear build 78's simulator launch failure, complete its exact-head
  gate and matching Release compile, then install the reviewed named head.
- Next ship approved Pantry, Training, Home/Mosaic and Notes slices in dependency
  order. New Design experiments remain distinct from approved build sheets;
  retrieve current acceptance before implementing later design changes.
- Passed gates, independent QA and Design acceptance still govern installation.
  Preserve the sample store, privacy walls, signing and one-device-install lock.
- Previous 54% ceiling, budget-stop entries and deleted heartbeat are historical.
  Every new dispatch must carry this override so lanes do not stop at 54%.
- Check usage at shipping milestones, use appropriate Sol/Luna effort, batch
  handoffs and keep CPU continuations moving without model-driven polling.
- Future coordinator turns were also set to Sol/low through the supported
  thread API under Kaushik's model-management instruction. Native app UI
  control was blocked, but the explicit thread model override succeeded.

## Current scheduling: small pipeline

Kaushik corrected the execution policy after the initial broad dispatch.
Persistent lane chats are responsibility queues, not a standing parallel fleet.
The coordinator owns model selection, usage pacing and correct handoffs.

- Default: one implementation lane active. At most one independent reviewer
  joins for a bounded review when a concrete diff is ready. Other lanes park.
- Build and test jobs proceed through the Mac scheduler while model turns are
  idle. Do not keep a model awake to poll a long-running CPU job.
- Sequence: implementation, small handoff, independent review, complete gate,
  matching Release compile, coordinator release decision. Pipeline only useful
  independent work, with no duplicated scans or validation.
- No lane may autonomously fan out subagents or pull extra queue items. A
  coordinator assignment must authorize the bounded delegation and concurrency.
- Routine status, extraction and docs: Luna at low effort. Implementation:
  Sol at low effort, medium only when the concrete task warrants it. Independent
  review: Sol, with effort scaled to risk. Astra is a specific escalation after
  a documented blocker, never a whole-fleet default.
- Each dispatch explicitly sets the chosen model and effort. Idle chats need
  not be woken merely to change settings. Do not inherit an expensive default
  when resuming them. This coordinator's own model remains user-controlled.
- Reuse concise DONE / OPEN / NEXT handoffs and exact hashes; do not replay full
  transcripts or ask multiple lanes to recover the same evidence.
- Check account-wide usage at batch boundaries. Report meaningful burn or a
  constraint; do not buy credits, consume reset credits, or invent a monetary
  conversion for plan percentages. The observed baseline was 40% weekly used.
- Model-driven followups are infrequent: the paced coordination heartbeat runs
  every two hours within the bounded work window below. Report meaningful
  completion, failure or a decision, not unchanged status.

## Superseded work-window allowance plan (historical)

Kaushik asked to pace work through Sunday at 5 AM Pacific. On Oct 24 at
2:51 AM PDT the live account showed 46% weekly used, 54% remaining, with the
weekly reset on Friday Oct 30 at 4:43:35 PM PDT. Sunday is the work cutoff,
not the observed provider reset. Recheck the live reset at batch boundaries.

- Work cutoff: Sunday Oct 25, 2026 at 5:00 AM PDT (12:00 UTC).
- Soft Tessera budget until then: eight more account-wide percentage points.
  Stop new model dispatch at 54% weekly used, or at the cutoff, whichever comes
  first. This is a coordinator guard, not a provider-enforced spending cap;
  usage includes other chats and cannot be attributed entirely to Tessera.
- The budget is rounded down from an even share of the remaining allowance
  through the actual Friday reset. It leaves at least 46% before other usage.
- At either stop condition, park model work at safe checkpoints. Preserve
  files and already-running CPU jobs; do not buy credits or use reset credits.
- Each future task brief must carry the cutoff, current budget state, explicit
  model/effort, bounded scope and no-fanout rule. Do not awaken parked lanes
  just to repeat this policy.
- Heartbeat: tessera-paced-coordination-through-sunday, every two hours,
  bounded through the cutoff. Its prompt checks time/usage first, permits only
  compact changed-state coordination, and requires quiet on unchanged state.
  Scheduled runs do not merge or install. Disable further runs when the cutoff
  or budget guard is reached.

The current priority is the minimal build 78 correction at c08c2537. Its
complete gate was observed running in the ios-a Mac slot after other lanes
were told to park. It has not yet passed the complete release gate.

## Authority and capacity

- Kaushik's latest instructions govern. Current code and observed results settle
  implementation facts. Prefer the Oct 24 handoffs to the Oct 16-18 Ops boards
  for current work; verify branch heads before assigning a task.
- This chat coordinates priorities, dependencies, shared-file ownership, and
  integration. Workers receive one bounded task and return evidence here.
- Each lane now has a separate persistent chat under the Tessera project.
  Each lead owns its queue and may delegate bounded work only as authorized
  by the current small-pipeline scheduling policy above.
  Current chat addresses are in ../ops/codex-team-addresses.md.
- The coordinator's current subagent team has four active slots including the
  coordinator. That is not a project-wide limit on lane chats. Each lane must
  respect the team capacity actually exposed in its own session.
- QA and Design remain independent from the implementation they review.
  Lane count and subagent capacity are separate from Mac heavy-job capacity.
- Every heavy build or test uses scripts/ops/mac_lanes.sh. Existing jobs count
  toward the three-slot limit. Phone operations use its device lock.
- Use each lane chat for persistent context and its subagents for bounded tasks.
  The coordinator can collect lane results and assign follow-up work. Do not
  duplicate existing workers or Mac jobs.
- All lane chats initially share the coordination checkout for read-only
  bootstrap. Before any implementation, claim a separate worktree and reserve
  shared files; never switch the shared checkout beneath another lane.
- Do not assume perpetual background execution. Future wakeups require an
  explicit automation request. Existing shell jobs may continue independently.

## Lane ownership

| Lane | Owns | First queue / handoff |
| --- | --- | --- |
| Coordinator | Priorities, cross-lane dependencies, integration and authorized merges | This chat; CODEX.md and latest user state |
| Core | Object engine, schema, domain APIs, privacy walls | core.md; resolve build 78 package blocker, then test-store stamp and runner |
| AI architecture | Harness, agents, context, memory, eval design | ../ai/harness/HANDOFF.md; finish current AI stack checks and wiring |
| Builder A | Tess layer, mosaic, Training, shared wheels, release execution | builder-a.md; build 78 gate, Training 230 simulator review |
| Builder B | Home layout, Today, Settings, Kitchen screens, Notes, Lists, Routines | builder-b.md; Pantry 1417 fixes, then approved Notes 246 |
| QA | Independent review of exact heads; privacy, data safety and gestures | qa.md; review every changed head and integrated results |
| Design | Approved specs, visual acceptance, type and color | design.md; Notes 246 is approved, Notes 247 is draft |
| Gestures | GestureTuning, GestureKit, touch regions and tap safety | gestures.md; verify the 1391 then 1393 chain and positive UI tests |
| Weather | Weather room and Core adapter | weather.md; compile Core source and room/adapter before wiring |
| Motion | Tess and room transitions, reduced-motion acceptance | ../ops/board/motion.md is historical; current sheets govern |
| Kitchen | Domain acceptance and recipe/pantry behavior | Core owns engine; Builder B owns screens; current sheets govern |
| Research | Focused API, performance and eval questions | Pull a bounded question from an active lane |
| Product | Spec decisions and ready-queue upkeep | Separate Product chat; current handoffs and dependencies |
| Ops | Dispatch map, branch/PR evidence and Mac capacity | Separate Ops chat; mac-lanes.md and codex_handoff.sh |

## Initial recovery workers

The first three workers were read-only audits, not build or merge owners:

- core_ai_lane: Core/AI heads, test results, ready work and existing ownership.
- ios_design_lanes: Builder A/B, Design, Gestures and Weather dependencies.
- qa_ops_lanes: independent gate rules, historical matrix and Mac scheduling.

Their audits do not constitute QA approval of any code head.

Thirteen persistent lane chats were subsequently created, alongside this
Coordinator chat. Each received a bounded read-only bootstrap assignment;
all thirteen were observed active. Creation and bootstrap do not constitute
permission to edit a shared checkout or evidence of passing code gates.

## Existing work: do not duplicate

At the recovery snapshot, all three Mac slots were occupied:

- core-ai: swift test for 1398 at 2377e39e. The existing script subsequently
  handles 1399 and 1400. A separate script queues a 1395 rerun.
- ios-a: build 78 Release device build. Its prior gate failed package and app
  tests; a successful device compile alone does not clear the release.
- ios-b: Pantry QA unit tests.

The AI results include the Pantry nonisolated fix from 1412 merged into the
tested tree. Do not call them passes on the unmodified PR head.

77.1 at 488280ed was reported installed at 1:53 AM PT. PR 1392 was then merged
with Kaushik's authorization; master became f8803d66. Verify current state
again before the next integration or release operation.

## Shared-file reservations

Before parallel edits, reserve files in each task brief. Use a separate
worktree for each implementation task; subagents share a filesystem by default.

- Home layout and mosaic: assign HomeMosaicPage.swift and HomeOneThing.swift
  to one worker at a time.
- Training and mosaic: assign AppAccents.swift and Shared/SurfacesV2.swift to
  one color-token owner.
- Mosaic and Pantry: coordinate ReviewChoices.swift and Settings changes.
- Gesture branches: coordinate GestureStabilityUITests.swift and gesture-policy.md.
- Review Pantry 1417 ancestry and final diff before integration: its observed
  diff also contains Home, mosaic, Settings and color files.

Do not reset, switch, merge into, or edit a worktree owned by an active job.

## Task brief and completion

Every task states its lane, purpose, permitted files, base and exact head,
acceptance criteria, dependency, and whether it may edit or run a build.
Workers report changes and exact validation, distinguish a partial check from
the full gate, and stop at their assigned boundary. Only the coordinator
advances integration and authorized release steps.

Rotate at a clean milestone using the existing three-line handoff:

```text
DONE: completed work, PR and exact head, validation
OPEN: remaining issue and dependency
NEXT: first concrete action
```

## Rules carried forward

- Install only the named exact head after the required gate and reviews pass.
  Every changed head needs review again. Reviewers do not approve their own work.
- Never read, copy, print, log or commit the Claude API key. Do not run a paid
  live eval as a capacity probe. One $100/month Claude spending cap covers the
  phone and Mac runner. The runner stops at the smaller of $50 and $100 minus
  the phone's monthly spend.
- Health, calendar, body and location data stay out of logs, backups and widgets.
  Sample data never touches the real store. Keep the existing privacy walls.
- UI and backend have equal weight. No cards, pills or stock SwiftUI look.
  Build approved sheets; draft Notes door pages 247 are not approved work.
- Preserve existing guards. Report a blocked action and its reason; never
  reroute around it. Use the current Mac slot protocol instead of old locks.
- The historical Claude model tiers, inferred dollar quotas, cache timings and
  thread addresses do not describe Codex capacity. Inherit this chat's model
  settings unless Kaushik requests otherwise.
