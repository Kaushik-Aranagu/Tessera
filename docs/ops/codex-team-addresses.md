# Codex team addresses

Created Oct 24, 2026, about 2:40 AM PT. These are current Codex lane chats,
separate from the historical Claude addresses in team-addresses.md.

All lane chats belong to the Tessera project. The coordinator created each lane
with its own handoff, ownership boundaries, an initial read-only assignment,
and permission to delegate bounded work when useful. All thirteen lanes were
observed active after dispatch; ongoing availability is subject to account
and session limits.

## Coordinator

- Title: Tessera - Coordinator
- Thread: `01a16d40-2f63-7c31-bf5a-eb255707135e`
- Host: `local`
- Project: `c81c4d45-029f-4614-94f3-de13304247b9`
- Checkout: `/Users/kaushikaranagu/Documents/ChatGPT/Tessera 2`
- Coordination rules: [codex-lanes.md](../handoff/codex-lanes.md)

## Lane chats

| Lane chat | Thread | Host | Initial assignment |
| --- | --- | --- | --- |
| Tessera - Core | `01a16d47-9ca1-7ee0-bc8f-122a1224fe34` | local | Read-only recovery of core ownership, live state and ready queue |
| Tessera - AI Architecture | `01a16d47-a3a2-7fa0-a251-56e6649ae4a5` | local | Read-only recovery of ai ownership, live state and ready queue |
| Tessera - Builder A | `01a16d47-b119-7561-98d3-9d9ade59a64b` | local | Read-only recovery of builder a ownership, live state and ready queue |
| Tessera - Builder B | `01a16d47-b901-7a02-96a4-1b43b3bf3195` | local | Read-only recovery of builder b ownership, live state and ready queue |
| Tessera - QA | `01a16d47-cfef-78f0-a125-c9be1b29349f` | local | Read-only recovery of qa ownership, live state and ready queue |
| Tessera - Design | `01a16d47-e04d-78c3-a4a9-bd5d99cb5109` | local | Read-only recovery of design ownership, live state and ready queue |
| Tessera - Gestures | `01a16d47-f6ce-79f3-b286-7b8d9c702086` | local | Read-only recovery of gestures ownership, live state and ready queue |
| Tessera - Weather | `01a16d48-190d-7390-ae27-c1be1ac2ad7b` | local | Read-only recovery of weather ownership, live state and ready queue |
| Tessera - Motion | `01a16d48-3240-74e0-b62b-b8f8a6aaf877` | local | Read-only recovery of motion ownership, live state and ready queue |
| Tessera - Kitchen | `01a16d48-4bcc-77a3-9eeb-3120f6b530b0` | local | Read-only recovery of kitchen ownership, live state and ready queue |
| Tessera - Research | `01a16d48-5a17-7b00-a972-88771cc507f9` | local | Read-only recovery of research ownership, live state and ready queue |
| Tessera - Product | `01a16d48-6f05-7902-a787-b18e13555946` | local | Read-only recovery of product ownership, live state and ready queue |
| Tessera - Ops | `01a16d48-8c73-7df2-97a8-858fd696216f` | local | Read-only recovery of ops ownership, live state and ready queue |

## Dispatch rules

- Use the existing chat for its lane. Do not create a duplicate when assigning
  the next bounded task. The user authorized this multi-lane workflow.
- Bootstrap reports return in each chat. The coordinator collects progress
  with wait_threads, preserves returned cursors, and sends follow-up assignments
  within the user's authorized scope. Bootstrap prompts do not authorize
  unsolicited external messages or cross-chat messaging by recipients.
- Lane chats start in the shared checkout for read-only recovery. Before edits,
  obtain a separate worktree and reserve overlapping files with the coordinator.
- Each lane can delegate to its own available subagent team. Do not assume
  another lane's active-agent limit, or unlimited project-wide concurrency.
- Existing Mac jobs and their worktrees retain their owners. No more than
  three heavy jobs run globally through mac_lanes.sh. Installs use its device lock.
- QA and Design review independently. Only a fully gate-passed exact release
  head may be named for installation. A lane report is not itself a gate pass.
- Keep DONE / OPEN / NEXT handoffs at clean milestones. Future scheduled
  wakeups require a separate explicit request; none were configured here.
