#!/usr/bin/env bash
# ============================================================
# demo-drift.sh — the Masskette demo move, in one command.
# 1) extension 0 -> 200 (> effective stroke zone sanity): the
#    overlap assert fires when effectiveStroke is forced to 0
# 2) restore: the chain is consistent again -> PASS
# Run from the project root on raven:  ./scripts/demo-drift.sh
# ============================================================
set -u
cd "$(dirname "$0")/.."

echo "=== 1) Forcing overlap: effectiveStroke 180 -> 0 ==="
sed -i 's/export effectiveStroke = 180/export effectiveStroke = 0/' kcl/stackup-x.kcl
grep -n 'export effectiveStroke' kcl/stackup-x.kcl

docker compose run --rm verify
DRIFT=$?
echo "=== overlap verify exit: $DRIFT (expected: 1, FAIL) ==="

echo "=== 2) Restoring driver: effectiveStroke 0 -> 180 ==="
sed -i 's/export effectiveStroke = 0/export effectiveStroke = 180/' kcl/stackup-x.kcl
grep -n 'export effectiveStroke' kcl/stackup-x.kcl

docker compose run --rm verify
RESTORED=$?
echo "=== restored verify exit: $RESTORED (expected: 0, PASS) ==="

if [ "$DRIFT" -ne 0 ] && [ "$RESTORED" -eq 0 ]; then
  echo "=== DEMO OK: the assert caught the overlap, and the chain is consistent again ==="
  exit 0
else
  echo "=== DEMO UNEXPECTED: overlap=$DRIFT restored=$RESTORED ==="
  exit 1
fi
