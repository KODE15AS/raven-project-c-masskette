#!/usr/bin/env bash
# Build and start the Cadify Masskette Live service (:8092).
set -u
cd "$(dirname "$0")/.."

# normalize line endings on everything that came from Windows
sed -i 's/\r$//' live/main.py live/static/index.html Dockerfile.live docker-compose.yml README.md 2>/dev/null

docker compose build live || exit 1
docker compose up -d live || exit 1
sleep 3
docker compose ps live
echo "--- /api/state smoke test ---"
curl -s -o /tmp/live-state.json -w "http %{http_code}\n" http://localhost:8092/api/state
cut -c1-300 /tmp/live-state.json
echo
echo "--- index smoke test ---"
curl -s -o /dev/null -w "index http %{http_code}\n" http://localhost:8092/
curl -s -o /dev/null -w "fig http %{http_code}\n" http://localhost:8092/figures/masskette-cadify.svg
