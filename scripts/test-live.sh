#!/usr/bin/env bash
# End-to-end test of the live API.
# PASS -> FAIL (overlap: effectiveStroke 0) -> PASS with extension -> PASS baseline.
# pin-to-pin is calculated; the audit only fails on internal contradictions.
set -u
URL=http://localhost:8092/api/commit

run() {
  echo "=== commit: $1 ==="
  curl -s -X POST -H 'content-type: application/json' -d "$1" "$URL" \
    | python3 -c 'import json,sys; r=json.load(sys.stdin); print("result:", r["result"], "| latency:", r["latency_ms"], "ms | attempts:", r["attempts"], "| call:", r.get("call_id")); print("msg:", r["message"])'
  echo
}

run '{"effectiveStroke":180,"extension":0,"spacer":23}'
run '{"effectiveStroke":0,"extension":40,"spacer":23}'
run '{"effectiveStroke":186,"extension":44,"spacer":68}'
run '{"effectiveStroke":180,"extension":0,"spacer":23}'
echo "=== metrics.jsonl ==="
tail -n 4 "$(dirname "$0")/../artifacts/metrics.jsonl"
