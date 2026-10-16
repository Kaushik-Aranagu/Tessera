# Parked ideas

For: AI architecture team. Ideas Kaushik wants kept, not built. Nothing here gets research, API calls or spend until he says to pursue it.

## Tess as her own agent (Kaushik, Oct 16, 8:53 AM PT, in the Tess motion lab thread)

**What he said, in short.** The weak link is how Tess roams: "after it spreads the pattern it's making is very predictive", so he wants it "more interactive and more depending on what's on the screen" instead of "hard-coded stuff".

**The idea.**
- Tess is her own agent, "just like how this project is being handled": a coordinator that keeps "its context growing", maintains "its memories", and tracks every thread, task and agent it runs. "Maybe like a Siri."
- She knows "what's going on on the screen" and "how the user is interacting with it".
- Her motion and roam come from that awareness, "instead of having to do a hard like deterministic check". A "very fast API call" to Claude, or a small model, picks "what kind of action Tess could do in terms of motion, in terms of roaming".
- Models he named, as he said them: "the new CLM models Jev", "trying out Jeff", and to "fine-tune and like RL some model locally", "on device models we can train locally". (Inferred, not confirmed with him: "CLM" may mean small language models, and "Jev" / "Jeff" a model family whose name the dictation lost.) His reason: "we want lightweight stuff", and Tessera "is not a general purpose thing", with very few baseline scenarios.
- No images sent: "of course we don't want to send images".

**Open question he named.** Latency: "maybe it's not too feasible, maybe it's too high latency."

**Status.** Parked. "For now, maybe just keep it in notes and we'll pursue it when we have the effort, time, resources and the credits." The near-term roam fix is the Tess motion lab's, on its own. When this is picked up, it sits under the one switch "Tess asks Claude" and the house rules in `architecture.md` (the phone computes, nothing leaves the phone with the switch off).

## Tess as chief of staff (Kaushik, Oct 16, 11:27 AM PT, project chat)

**What he said, in short.** Tess should eventually work the way this project works: "Tess would be managing everybody", with "a broader picture of what's going". She is "the first point of contact to me", while "there could be other experts in other areas". Tess does the "communicating and getting all of that done and collecting it and presenting it to me". The hierarchy: the top has the broad view, and "the deeper you go, they have lesser of the broader view, but more of the deeper view". Experts are trusted with their area; Tess checks in now and then rather than doing everything herself.

**Status.** A later goal, not current scope: "maybe that's for later. Once we have Tess as a AI agent first built up properly". It sits with "Tess as her own agent" above. No research, calls or spend until he says.

**How today's pieces leave room for it** (so it "helps while building from downwards"):
- **AI-2 TessJob + ClaudeClient** (`claude-client.md`). A TessJob is already one bounded ask with its own model, tool, budget and outcome. Later an expert is a kind of job, and Tess's top-level job hands out jobs and gathers their outcomes. Keep each job self-contained (its own pack, tool and validator) and keep ClaudeClient the only door, so experts inherit the walls for free.
- **Soul signals** (`soul-signals.md`). The HomeFacts diff is Tess's broad view of the day, computed on the phone. Experts report back as facts, not as screen changes, so the one router still decides what Tess shows.
- **Memory shape A** (`memory-experiment.md`). One profile block, written only on the phone, is the shared broad context. Experts read the slice their area needs; none writes memory, same as Claude today.
- **Router and walls** (`architecture.md` section 7). SecretWords, the money and body wall, the "Tess asks Claude" switch and the $50 ledger sit in front of every call, so any number of experts stays inside the same lines. An expert never gets a wider pack than its job needs.
