"""Cadify Masskette Live - FastAPI backend.

Serves the interactive Masskette UI and runs the executable stack-up
audit: driver values are written into kcl/stackup-x.kcl, the whole KCL
project is compiled via the Zoo API (zoo CLI), and the asserts are the
judge. Every run is timed and appended to artifacts/metrics.jsonl.
"""

import json
import os
import re
import subprocess
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

KCL_DIR = Path(os.environ.get("KCL_DIR", "/work/kcl"))
ART_DIR = Path(os.environ.get("ART_DIR", "/work/artifacts"))
STACKUP = KCL_DIR / "stackup-x.kcl"
EXPORT_DIR = ART_DIR / "export"
METRICS = ART_DIR / "metrics.jsonl"
REPORT = ART_DIR / "live-report.json"
STATIC_DIR = Path(__file__).parent / "static"

CATALOG = {
    "rodEyeFront": 51,
    "headCap": 12,
    "pistonZone": 75,
    "glandLength": 50,
    "rodEyeRear": 51,
}
LIMITS = {
    "stroke": (50, 400),
    "extension": (0, 400),
    "spacer": (0, 80),
    "spec": (300, 1000),
}
DRIVER_RE = {
    "stroke": re.compile(r"(^export stroke = )(\d+)", re.M),
    "extension": re.compile(r"(^export extension = )(\d+)", re.M),
    "spacer": re.compile(r"(^export spacer = )(\d+)", re.M),
}
SPEC_RE = re.compile(r"(assert\(pinToPin, isEqualTo = )(\d+)")
FAIL_PATTERNS = [
    re.compile(r"[A-Za-z-]+ drifted[^\n│╰]*"),
    re.compile(r"must (?:be|end|stay)[^\n│╰]*"),
    re.compile(r"assert failed[^\n│╰]*"),
    re.compile(r"semantic:[^\n│╰]*"),
    re.compile(r"engine hangup[^\n│╰]*"),
]
CALL_ID_RE = re.compile(r"API call ID: ([0-9a-f-]+)")

app = FastAPI(title="Cadify Masskette Live")
run_lock = threading.Lock()


class CommitRequest(BaseModel):
    stroke: int
    extension: int
    spacer: int
    spec: int


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_state() -> dict:
    text = STACKUP.read_text()
    drivers = {}
    for key, rx in DRIVER_RE.items():
        m = rx.search(text)
        if not m:
            raise HTTPException(500, f"driver '{key}' not found in stackup-x.kcl")
        drivers[key] = int(m.group(2))
    spec_m = SPEC_RE.search(text)
    if not spec_m:
        raise HTTPException(500, "closing assert not found in stackup-x.kcl")
    return {"drivers": drivers, "spec": int(spec_m.group(2))}


def write_drivers(req: CommitRequest) -> None:
    text = STACKUP.read_text()
    text = DRIVER_RE["stroke"].sub(rf"\g<1>{req.stroke}", text)
    text = DRIVER_RE["extension"].sub(rf"\g<1>{req.extension}", text)
    text = DRIVER_RE["spacer"].sub(rf"\g<1>{req.spacer}", text)
    text = SPEC_RE.sub(rf"\g<1>{req.spec}", text)
    STACKUP.write_text(text)


def extract_fail_message(log: str) -> str:
    for rx in FAIL_PATTERNS:
        m = rx.search(log)
        if m:
            return m.group(0).strip()
    return "KCL compile failed - see log"


def run_zoo() -> dict:
    """Compile the project via Zoo API with retry on transient hangups."""
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    attempts = []
    full_log = ""
    for attempt in range(1, 4):
        t0 = time.monotonic()
        proc = subprocess.run(
            [
                "zoo", "kcl", "export", "--deterministic",
                "--output-format=step", str(KCL_DIR), str(EXPORT_DIR),
            ],
            capture_output=True, text=True, timeout=300,
        )
        latency_ms = int((time.monotonic() - t0) * 1000)
        log = (proc.stdout or "") + (proc.stderr or "")
        full_log += f"-- attempt {attempt} ({latency_ms} ms) --\n{log}\n"
        attempts.append(latency_ms)
        if proc.returncode == 0:
            return {
                "ok": True, "latency_ms": latency_ms, "attempts": attempts,
                "log": full_log, "call_id": _call_id(log),
            }
        if "engine hangup" not in log:
            return {
                "ok": False, "latency_ms": latency_ms, "attempts": attempts,
                "log": full_log, "message": extract_fail_message(log),
                "call_id": _call_id(log),
            }
        time.sleep(2)
    return {
        "ok": False, "latency_ms": attempts[-1], "attempts": attempts,
        "log": full_log, "message": "engine hangup after 3 attempts",
        "call_id": _call_id(full_log),
    }


def _call_id(log: str) -> str | None:
    m = CALL_ID_RE.search(log)
    return m.group(1) if m else None


def append_metrics(entry: dict) -> None:
    METRICS.parent.mkdir(parents=True, exist_ok=True)
    with METRICS.open("a") as fh:
        fh.write(json.dumps(entry) + "\n")


def read_metrics(limit: int = 30) -> list[dict]:
    if not METRICS.exists():
        return []
    lines = METRICS.read_text().strip().splitlines()
    return [json.loads(ln) for ln in lines[-limit:]]


@app.get("/api/state")
def api_state():
    state = read_state()
    last = json.loads(REPORT.read_text()) if REPORT.exists() else None
    return {
        "catalog": CATALOG,
        "limits": LIMITS,
        "drivers": state["drivers"],
        "spec": state["spec"],
        "last": last,
        "history": read_metrics(),
    }


@app.post("/api/commit")
def api_commit(req: CommitRequest):
    for key in ("stroke", "extension", "spacer", "spec"):
        lo, hi = LIMITS[key]
        val = getattr(req, key)
        if not lo <= val <= hi:
            raise HTTPException(422, f"{key}={val} outside allowed range {lo}-{hi}")
    if req.extension > req.stroke:
        raise HTTPException(422, "extension cannot exceed stroke")

    if not run_lock.acquire(blocking=False):
        raise HTTPException(409, "verification already running")
    try:
        stamp = now_iso()
        write_drivers(req)
        result = run_zoo()
        # Classify: audit failure (assert) vs engine/compile failure
        message = result.get("message", "")
        if result["ok"]:
            verdict, engine, audit = "PASS", "ok", "ok"
            message = "Masskette closed: all asserts passed, STEP exported."
        elif "drifted" in message or "must " in message:
            verdict, engine, audit = "FAIL", "ok", "fail"
        else:
            verdict, engine, audit = "ERROR", "fail", "unknown"

        report = {
            "time": stamp,
            "result": verdict,
            "engine": engine,
            "audit": audit,
            "message": message,
            "latency_ms": result["latency_ms"],
            "attempts": result["attempts"],
            "call_id": result.get("call_id"),
            "drivers": req.model_dump(),
            "log": result["log"][-4000:],
        }
        REPORT.write_text(json.dumps(report))
        append_metrics({k: report[k] for k in
                        ("time", "result", "message", "latency_ms", "attempts", "drivers")})
        return report
    finally:
        run_lock.release()


@app.get("/")
def index():
    return FileResponse(STATIC_DIR / "index.html")


app.mount("/figures", StaticFiles(directory="/work/figures"), name="figures")
app.mount("/", StaticFiles(directory=STATIC_DIR), name="static")
