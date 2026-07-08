#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
git add -A
git commit -m "Rework drivers per review: effectiveStroke is the customer input, pin-to-pin is pure output

- The customer picks effectiveStroke (yellow box in the chain); the
  physical stroke zone = effectiveStroke + extension is derived and
  reported in the side panel, not typed anywhere.
- When extension > 0 both extension and effective stroke get yellow
  editable boxes in the chain row.
- The audit no longer asserts a fixed pin-to-pin total: it fails on
  internal contradictions (segment overlap, tube/head-bush mismatch).
  The stale 'spec 442' error is gone.
- New station planes drawn and exported: end cap and head bush.
- Demo button is now 'Force overlap' (effectiveStroke -> 0)." \
  --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>"
git push origin main
git log --oneline -3
