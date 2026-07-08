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
docker-compose.yml # services: verify (on demand), web (status page :8091)
Dockerfile.verify  # alpine + Zoo CLI (pinned, checksum-verified)
web/               # status page: PASS/FAIL badge, chain, figures, log
docs/figures/      # Maßkette illustrations (Rev 1)
artifacts/         # verify-report.json, verify-last.log, exported STEP
```

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

**The demo move:** edit `stroke = 180` to `200` in `kcl/stackup-x.kcl`, re-run verify,
watch `pin-to-pin drifted from spec` fail the build. Update the spec value in the
closing assert, re-run, watch it pass. That failure *is* the design review.

## Current step status

- Step 1 (project stack, KCL chain, verify pipeline, status page): DONE
- Step 2 (extended-state configuration, second chain axis): TODO
- Step 3 (dim::distance integration when merged upstream): TODO — see companion spec
  "KCL Model Dimension Syntax Rev 1"
