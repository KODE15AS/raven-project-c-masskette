#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
git add -A
git commit -m "Add Cadify Masskette Live: interactive audit demo on :8092

FastAPI + zoo CLI backend writes drivers into kcl/stackup-x.kcl and
compiles the whole project via the Zoo API; asserts are the verdict.
Editable Figure 1 (yellow driver boxes + sliders), FILE/ENGINE/AUDIT
status lamps, engine latency + retry metrics, run history
(artifacts/metrics.jsonl) and Cadify-branded Rev 2 figures." \
  --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>"
git push origin main
git log --oneline -3
