# On-device context size: what Tess can fit

For: Core engine, Product
Date: 2026-10-15

**Answer.** The window is 4,096 tokens per session on iOS 26 and on iOS 27, shared between input and output. No Apple source we found says 8K. Apple's iOS 27 notes point to Private Cloud Compute for "a larger context size", and the WWDC26 lab put that at 32K. Plan for 4K, read the real number at runtime, and treat the "8K" in `ai-and-tess.md` as wrong until the phone says otherwise.

## Evidence

- Apple's guide says "Apple's on-device foundation model has a context window of 4096 tokens per session". https://developer.apple.com/documentation/foundationmodels/managing-the-context-window
- TN3193 says the same and was updated on 2026-03-31 for the iOS 26.4 APIs. https://developer.apple.com/tutorials/data/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window.md
- WWDC26 lab, after the iOS 27 model: "the context size is the same as it was before. It's 4096 and it is a shared window. So if you input 4000 tokens, your response can go up to the remaining 96." It also said "PCC is 32 K". https://developer.apple.com/videos/play/wwdc2026/8121/?time=0
- The iOS 27 update notes a better on-device model but no larger window. They send you to `PrivateCloudComputeLanguageModel` for "a larger context size". https://developer.apple.com/documentation/updates/foundationmodels.md
- There are three model versions (26.0 to 26.3, 26.4 and 27.0), so the number can change with an OS update. https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel.md
- Where "8K" came from: unknown. We found no Apple page, session or reputable post that says 8,192 for `SystemLanguageModel`. Inferred: it is a mix-up with another model or an early guess.

## The APIs

- **Window size.** `SystemLanguageModel.contextSize: Int` returns "the total number of tokens that can be used in a single session, including both input prompts and generated responses". It is `@backDeployed(before: iOS 26.4)`. The page says it can fail when the model is unavailable or Apple Intelligence is off, but the declaration is a plain `get`, so check `isAvailable` first. https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/contextsize.md
- **Counting.** `tokenCount(for:)` is `async throws -> Int` and needs iOS 26.4 (it is not back-deployed). The documented overload takes `Instructions`. Apple says it also counts prompts, tools, schemas and transcript entries, but we did not see those signatures. https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/tokencount(for:).md and https://developer.apple.com/forums/thread/823423
- **After a call.** `Response.usage` (`LanguageModelSession.Usage`) reports the tokens a response used. The WWDC26 lab said it splits input, output and cached tokens. https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response.md
- **Profiling.** The Foundation Models instrument shows tokens per request. It shows zero on the simulator, so profile on the phone. https://www.kodeco.com/books/apple-foundation-models/v1.0/chapters/4-context-management-model-safety

## The overflow error

- On iOS 27 the session throws `LanguageModelError.contextSizeExceeded(_:)`. Its `ContextSizeExceeded` payload carries `contextSize` and `tokenCount`, so we can log how far over we went. https://developer.apple.com/documentation/foundationmodels/languagemodelerror.md and https://developer.apple.com/documentation/foundationmodels/languagemodelerror/contextsizeexceeded.md
- The old `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)` is listed as available from 26.0 to 27.0. Inferred: it is deprecated on iOS 27, and since Tessera targets iOS 27 we catch only the new case. https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/exceededcontextwindowsize(_:).md
- After this error the session will not respond again. Apple says to trim the history or make a new session. https://developer.apple.com/documentation/foundationmodels/managing-the-context-window

## What counts against the budget

Everything in the session counts: instructions, every prompt, tool definitions (name, description, parameters), tool call arguments and tool output, `Generable` JSON schemas including `@Guide` text, and every model response (TN3193, link above). The transcript keeps growing with each turn. Apple advises 3 to 5 tools per request, short descriptions, and running a tool directly when the model would always need its result (managing-the-context-window, link above).

## Budget for one Tess capture (inferred, measure in T3)

The numbers below assume roughly 4 characters per token in English, from Apple's "three to four characters" rule. Our dynamic schemas are not measured yet.

| Part | Rough tokens | Rule |
|---|---|---|
| Instructions (voice, rules, short action list) | 250 | Fixed text, under 3 short paragraphs |
| 10 tool schemas | 900 to 1,200 | About 90 to 120 each; send only the 3 to 5 the use needs (about 450) |
| Context block (today's tasks, running process, recent actions) | 400 | Hard cap; the packer drops the oldest actions first |
| User utterance | 50 | Over 400 means a paste, which goes to Claude |
| One tool call and its result | 200 | Keep tool output to one line ("Done: ...") |
| Response reserve | 300 | The window is shared, so reserve it before sending |
| **Total** | **about 1,650 with 5 tools, 2,400 with 10** | **Target at most 2,500, which is 60% of 4,096** |

Headroom covers tokenizer changes between model versions and our own guesses being off.

## When to trim, reset or route (recommended)

1. **Fresh session per utterance.** Capture is single-turn, so build a new `LanguageModelSession` every time. Never let history pile up. A follow-up ("no, the other one") gets a new session seeded with just the last exchange, as Apple's first-and-last-entry example does.
2. **Preflight count.** Before sending, call `tokenCount(for:)` on the instructions and the context block (the tool cost is a constant we measure once per build). If the total plus the 300 reserve goes over 2,500, trim in this order: recent actions, then tasks done today, then tool count down to 3.
3. **Route to Claude** when, after trimming, it is still over 3,000; when the task needs the class catalog (about 2K tokens by itself) or plan wording; when the utterance is a paste over 400 tokens; or after one `contextSizeExceeded`. Never retry the same prompt on-device.
4. **Log every overflow** with its `tokenCount` and `contextSize` in the `TessCall` record, so the budget gets tuned from real data.

## Check on the phone (paste into a DEBUG button)

```swift
Task {
    let model = SystemLanguageModel.default
    print("Tess ctx:", model.contextSize, "available:", model.isAvailable)
    print("Tess instr tokens:", try await model.tokenCount(for: Instructions(TessVoice.sampleInstructions)))
}
```

Swap `TessVoice.sampleInstructions` for any string if that symbol does not exist. Run it on the iPhone with Apple Intelligence on, not the simulator, and post the two numbers on the board.

## Still unverified

- The `contextSize` value on Kaushik's phone running iOS 27 (expected 4096).
- The exact `tokenCount(for:)` overloads for `Prompt`, tools and transcript entries. Only the `Instructions` one was seen in the docs.
- The real token cost of our 10 `DynamicGenerationSchema` tools, and of one tool round trip.
- Whether the framework counts the response reserve before sending or fails mid-generation.
- The fields of `LanguageModelSession.Usage`. The cache split was heard in the WWDC26 lab, not read in the docs.
- The origin of the 8K figure.
