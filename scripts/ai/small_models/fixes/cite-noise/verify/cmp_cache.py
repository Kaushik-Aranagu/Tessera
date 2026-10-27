import pickle, numpy as np
a = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/chats.pkl", "rb"))
b = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/verify/chats_fresh.pkl", "rb"))
assert len(a) == len(b) == 10
mx = 0.0
for x, y in zip(a, b):
    assert x["ids"] == y["ids"] and x["docs"] == y["docs"] and x["text"] == y["text"] and x["qs"] == y["qs"]
    mx = max(mx, float(np.abs(x["nodes"] - y["nodes"]).max()), float(np.abs(x["asks"] - y["asks"]).max()))
print("ids/docs/text/qs identical; max abs vector diff", mx, "; questions", sum(len(c["qs"]) for c in a))
