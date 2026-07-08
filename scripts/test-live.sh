#!/usr/bin/env bash
# End-to-end test of the live API: PASS -> FAIL (drift) -> PASS (restore).
set -u
URL=http://localhost:8092/api/commit

run() {
  echo "=== commit: $1 ==="
  curl -s -X POST -H 'content-type: application/json' -d "$1" "$URL" \
    | python3 -c 'import json,sys; r=json.load(sys.stdin); print("result:", r["result"], "| latency:", r["latency_ms"], "ms | attempts:", r["attempts"], "| call:", r.get("call_id")); print("msg:", r["message"])'
  echo
}

run '{"stroke":180,"extension":0,"spacer":23,"spec":442}'
run '{"stroke":200,"extension":0,"spacer":23,"spec":442}'
run '{"stroke":180,"extension":0,"spacer":23,"spec":442}'
echo "=== metrics.jsonl ==="
tail -n 3 "$(dirname "$0")/../artifacts/metrics.jsonl"
