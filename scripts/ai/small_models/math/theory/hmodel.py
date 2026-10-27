"""Threshold model of the hub cost: a node cited n times has its score on every unrelated ask raised by
delta = h * eta * n (h = 0.266, measured common-mode drift); it intrudes into an ask's top-10 with probability
Pbar((g - delta)/sigma) instead of Pbar(g/sigma) (g = 0.253 = theta_10 minus the mean node score, sigma = 0.127 = sd of
ask-node scores). Predicted extra intruders per ask, summed over cited nodes, relative to eta = 0.02, vs the measured
hub cost H_c (unrelated-visit loss)."""
import json, sys
import numpy as np
from math import erf, sqrt
sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import chats
C = chats()
ns = []
for c in C:
    cnt = np.zeros(len(c["nodes"]))
    for _, ev, _ in c["qs"]:
        cnt[ev] += 1
    ns.extend(cnt[cnt > 0])
ns = np.array(ns)
# a cite visit sequence is random: at a given time a node has on average half its cites; use n/2 as the typical count
Pbar = lambda z: 0.5 * (1 - np.vectorize(erf)(z / sqrt(2)))
h, g, sig = 0.266, 0.253, 0.127
meas = {0.02: 0.0046, 0.05: 0.0123, 0.1: 0.0296, 0.2: 0.0876}
pred = {}
for eta in meas:
    pred[eta] = float(np.sum(Pbar((g - h * eta * ns / 2) / sig) - Pbar(g / sig)))
for eta in meas:
    print(f"eta {eta:<5} predicted extra-intruder mass ratio {pred[eta] / pred[0.02]:5.2f}   measured H_c ratio {meas[eta] / meas[0.02]:5.2f}   linear {eta / 0.02:4.1f}")
