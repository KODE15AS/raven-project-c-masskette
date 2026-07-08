# raven-project-c-masskette

**The Maßkette demo: an executable stack-up (dimension chain) in KCL.**
Hydraulic cylinder, X-axis chain `51 + 12 + 75 + 0 + 180 + 50 + 23 + 51 = 442`, modeled
top-down in KCL for [Zoo Design Studio](https://zoo.dev), following
*"Best Practice: Executable Stack-Ups (Maßkette) in KCL"* (Cadify, Rev 0, 2026-07-08).

The chain is the master. Standard parts contribute catalog dimensions, custom parts
(tube = 305, rod = 253) absorb the drivers (stroke, extension, spacer), stations become
planes, sub-assemblies mount on stations — and the closing dimension is **asserted on
every compile**. Change the stroke and the audit fails until the spec is consciously updated.

## Architecture

Per the RAVEN Etappe 3 principle: RAVEN owns the platform, this project owns its runtime.
Isolated stack, own port (**8091**), own Docker labels (`raven.project: c-masskette`).

```
kcl/
  stackup-x.kcl    # the Maßkette: catalog inputs -> drivers -> stations -> asserts
  tube.kcl         # SUB-ASSY 1: bottom eye, endcap, tube (305, derived), head bush
  rod.kcl          # SUB-ASSY 2: piston, rod (253, derived), locknut, top eye
  main.kcl         # top-level assembly: imports both, closing assert
scripts/verify.sh  # the executable audit: zoo kcl export; asserts gate the build
docker-compose.yml # services: verify (on demand), web (:8091), live (:8092)
Dockerfile.verify  # alpine + Zoo CLI (pinned, checksum-verified)
Dockerfile.live    # python + Zoo CLI: FastAPI backend for the live demo
live/              # Cadify Maßkette Live: interactive figure, lamps, metrics
web/               # status page: PASS/FAIL badge, chain, figures, log
docs/figures/      # Maßkette illustrations (Rev 1 + Cadify-branded Rev 2)
artifacts/         # verify-report.json, live-report.json, metrics.jsonl, STEP
```

## Cadify Maßkette Live (interactive demo, :8092)

```bash
docker compose up -d --build live    # -> http://<raven>:8092/
```

Figure 1 rendered live in the browser; the yellow driver boxes (effective
stroke, extension, spacer) are editable, synced with sliders. Local arithmetic
updates instantly and is marked **UNVERIFIED** until *Commit → run audit*
writes the drivers into `kcl/stackup-x.kcl` and compiles the whole project via
the Zoo API. Pin-to-pin is a calculated output, never typed. Three status
lamps (FILE / ENGINE / AUDIT), engine latency + retry metrics, Zoo API call
ID, run history (`artifacts/metrics.jsonl`) and the raw verification log make
the round trip transparent. "Force overlap" sets the effective stroke to 0 so
the overlap assert fails on api.zoo.dev — the audit verdict is the demo.

## How to start / stop

```bash
cd ~/dev/raven-project-c-masskette

# one-time: token (same variable as project A)
cp .env.example .env   # then paste ZOO_API_TOKEN value

# run the stack-up audit (compiles KCL via Zoo API, exports STEP)
docker compose run --rm verify

# status page on Tailscale
docker compose up -d web        # -> http://<raven>:8091/
docker compose down             # stop
```

## Verification

`docker compose run --rm verify` — exit code 0 means the Maßkette closed: all
`assert`s in `kcl/stackup-x.kcl` passed and a STEP file was exported to `artifacts/export/`.
The report lands in `artifacts/verify-report.json` and is shown on the status page.

**The demo move:** the customer drivers are `effectiveStroke`, `extension`
(slagforkorter) and `spacer`; pin-to-pin is always a calculated output.
Force `effectiveStroke = 0` in `kcl/stackup-x.kcl`, re-run verify, and watch
the overlap assert (`segments overlap`) fail the build. Restore it and the
chain is consistent again. That failure *is* the design review.

## Current step status

- Step 1 (project stack, KCL chain, verify pipeline, status page): DONE
- Step 2 (extended-state configuration, second chain axis): TODO
- Step 3 (dim::distance integration when merged upstream): TODO — see companion spec
  "KCL Model Dimension Syntax Rev 1"
