#!/usr/bin/env bash
# ============================================================
# verify.sh — the executable stack-up audit
# Compiles the KCL project against the Zoo API. If any assert
# in stackup-x.kcl fails (e.g. the Masskette does not close),
# the compile fails and this script reports FAIL.
# Writes artifacts/verify-report.json for the status page.
# ============================================================
set -uo pipefail

KCL_DIR="${KCL_DIR:-/work/kcl}"
ART_DIR="${ART_DIR:-/work/artifacts}"
mkdir -p "$ART_DIR/export"

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG_FILE="$ART_DIR/verify-last.log"

echo "== Masskette verification $STAMP =="            | tee "$LOG_FILE"
echo "== zoo $(zoo version 2>/dev/null | head -n1) ==" | tee -a "$LOG_FILE"

# Retry transient engine hangups (API-side); real assert failures are final
STATUS=1
for ATTEMPT in 1 2 3; do
  ATT_LOG="$ART_DIR/verify-attempt.log"
  echo "-- attempt $ATTEMPT --" >>"$LOG_FILE"
  zoo kcl export --deterministic --output-format=step "$KCL_DIR" "$ART_DIR/export" >"$ATT_LOG" 2>&1
  STATUS=$?
  cat "$ATT_LOG" >>"$LOG_FILE"
  [ $STATUS -eq 0 ] && break
  grep -q "engine hangup" "$ATT_LOG" || break
  sleep 3
done
rm -f "$ART_DIR/verify-attempt.log"

if [ $STATUS -eq 0 ]; then
  RESULT="PASS"
  MESSAGE="Masskette closed: all asserts passed, STEP exported."
else
  RESULT="FAIL"
  MESSAGE="$(grep -m1 -Eo '[A-Za-z-]+[a-z-]* drifted[^│╰]*|assert failed[^│╰]*|must (be|end|stay)[^│╰]*' "$LOG_FILE" | head -n1)"
  if [ -z "$MESSAGE" ]; then
    MESSAGE="$(grep -m1 -Eo 'semantic:[^│╰]*|engine hangup[^│╰]*' "$LOG_FILE" | head -n1)"
  fi
  MESSAGE="${MESSAGE:-KCL compile failed, see verify-last.log}"
fi

jq -n \
  --arg time "$STAMP" \
  --arg result "$RESULT" \
  --arg message "$MESSAGE" \
  --arg log "$(tail -c 4000 "$LOG_FILE")" \
  '{time: $time, result: $result, message: $message, log: $log}' \
  > "$ART_DIR/verify-report.json"

echo "== $RESULT: $MESSAGE ==" | tee -a "$LOG_FILE"
exit $STATUS
