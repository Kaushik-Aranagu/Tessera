#!/bin/bash
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 HF_HUB_OFFLINE=1 TOKENIZERS_PARALLELISM=false
cd /tmp/claude-0/algos/review/rerun
for s in b1_encoder b2_scoring b2b_batch b3_pyramid b3k_kmeans_tree b4_bm25 b5_internode b6_train b7_paths b2h_hnsw; do
  echo "=== $s start $(date +%T) load $(cut -d' ' -f1 /proc/loadavg)"
  /tmp/e1/bin/python -I $s.py > logs/$s.log 2>&1
  echo "=== $s exit $? end $(date +%T)"
done
echo ALLDONE
