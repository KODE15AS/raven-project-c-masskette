#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
git add -A
git commit -m "Fix Masskette Live per review: fixed piston STA, extension sleeve, calculated pin-to-pin, light Cadify theme

- Piston stays on its fixed station; the extension (slagforkorter) is a
  sleeve in front of the piston face that subdivides the stroke zone and
  reduces the effective stroke. When extension > 0 the figure draws the
  sleeve, a dedicated extension STA and an effective-stroke dimension.
- Tube now runs all the way to the end of the gland zone.
- Pin-to-pin is calculated only: the spec input is gone, replaced by a
  read-only 'calculated pin-to-pin' field; the closing assert in KCL is
  the single source of the spec. Backend no longer accepts a spec value.
- Light cadify.no-style theme with soft shadows and the real Cadify logo." \
  --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>"
git push origin main
git log --oneline -3
