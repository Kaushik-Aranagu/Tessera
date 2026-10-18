# What Kitchen's rotation hands off (Ops note, 6:45 PM PT Oct 17)

Kitchen's turns run about 318k cache_read, past the ~300k rotation line. Rotate at the next quiet point (no PR number out and unmerged; frozen-PR rule).

The outgoing lead sends a handoff note into ops/rotation-handoffs.md, section "Kitchen", containing:
1. Open PRs by number with the exact head SHA and who owns the next step (QA verdict, Core fix, merge).
2. Rulings still in force that live only in chat: AI-12 groceries accepted, Pantry v2 R1-R20, G139 sticky (private recipe cooked reads "Private item" in Pantry), size words count as unit words in the title rule, plus any ruling after 6:10 PM.
3. Next list from ops/board/kitchen.md (keep 5+) and the gap-discovery lane state.
4. Anything promised to Product or Core (relays sent, answers owed).

The fresh thread brief is the fenced "The block" from handoff-block.md, Kitchen section, which already carries: old thread cmsg_01VTPva3JGXrfvetgUvAWE7MJ6x15H146i8Ubn1hrFjuEJ with session_01TRh7xwt9UhB98fN8BteVgs as the current ids (old ones are retired once the new thread exists), the G rules, and the key message ids. Ops then (a) updates handoff-block.md and team-addresses.md with the new ids, (b) sends the new address to every team and the coordinator, (c) the old thread is resolved by the coordinator.
What does NOT carry: the old context itself. The new lead re-reads kitchen.md and kitchen-addresses.md instead of the old thread.
