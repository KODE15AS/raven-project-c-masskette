#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
git add -A
git commit -m "README: document public Tailscale Funnel URL for the live demo" \
  --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>"
git push origin main
git log --oneline -2
