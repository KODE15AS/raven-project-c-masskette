#!/usr/bin/env bash
# ============================================================
# demo-drift.sh — the Masskette demo move, in one command.
# 1) stroke 180 -> 200: the chain no longer closes -> FAIL
# 2) restore 180: the chain closes -> PASS
# Run from the project root on raven:  ./scripts/demo-drift.sh
# ============================================================
set -u
cd "$(dirname "$0")/.."

echo "=== 1) Changing driver: stroke 180 -> 200 ==="
sed -i 's/export stroke = 180/export stroke = 200/' kcl/stackup-x.kcl
grep -n 'export stroke' kcl/stackup-x.kcl

docker compose run --rm verify
DRIFT=$?
echo "=== drift verify exit: $DRIFT (expected: 1, FAIL) ==="

echo "=== 2) Restoring driver: stroke 200 -> 180 ==="
sed -i 's/export stroke = 200/export stroke = 180/' kcl/stackup-x.kcl
grep -n 'export stroke' kcl/stackup-x.kcl

docker compose run --rm verify
RESTORED=$?
echo "=== restored verify exit: $RESTORED (expected: 0, PASS) ==="

if [ "$DRIFT" -ne 0 ] && [ "$RESTORED" -eq 0 ]; then
  echo "=== DEMO OK: the assert caught the drift, and the chain closes again ==="
  exit 0
else
  echo "=== DEMO UNEXPECTED: drift=$DRIFT restored=$RESTORED ==="
  exit 1
fi
