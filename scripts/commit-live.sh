#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
git add -A
git commit -m "Slagforkorter rebalances inside a fixed stroke zone; add Cadify-branded reference documents

- Editing extension now SHORTENS effectiveStroke inside a constant
  stroke zone, so calculated pin-to-pin does not move. Editing
  effective stroke is the customer asking for more travel and moves
  the pin. Force-overlap demo fills the zone with the sleeve.
- Two reference documents served at /docs as professionally formatted
  HTML (Cadify logo, Montserrat, print-friendly): the Best Practice
  Rev 1 paper and the dim::distance contribution spec Rev 1, both
  reformatted from the PDFs with figures inline. Linked from a new
  footer on the main page (open in new tab).
- Dockerfile.live: chmod a+rX /app so static docs are readable by the
  non-root uid (fixes 401 from StaticFiles)." \
  --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>"
git push origin main
git log --oneline -3
