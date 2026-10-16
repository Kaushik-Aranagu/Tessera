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
