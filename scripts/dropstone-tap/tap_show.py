#!/usr/bin/env python3
"""Pretty-print a dropstone-tap run directory.

Usage:
    tap_show.py [RUN_DIR] [options]

RUN_DIR defaults to the newest dir under ~/.dropstone-tap/runs.

Options:
    -i, --id N        only show flow id N
    --url RE          only flows whose URL matches RE
    -H, --headers     headers only, skip bodies
    -b, --body-limit N  max chars of body printed (default 4000)
    --raw             do not try to pretty-print JSON bodies
"""
import json
import re
import sys
from pathlib import Path

RUNS = Path.home() / ".dropstone-tap" / "runs"


def latest_run() -> Path:
    if not RUNS.exists():
        sys.exit(f"no runs in {RUNS}")
    dirs = sorted((d for d in RUNS.iterdir() if d.is_dir()), key=lambda d: d.stat().st_mtime)
    if not dirs:
        sys.exit(f"no runs in {RUNS}")
    return dirs[-1]


def load(run: Path) -> list[dict]:
    flows = run / "flows.jsonl"
    if not flows.exists():
        sys.exit(f"missing {flows}")
    out = []
    for line in flows.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except Exception:
            pass
    return out


def pretty(body: str, raw: bool) -> str:
    if raw or not body:
        return body or ""
    s = body.strip()
    if s[:1] in "[{" and s[-1:] in "]}":
        try:
            return json.dumps(json.loads(s), indent=2, ensure_ascii=False)
        except Exception:
            return body
    return body


def main() -> int:
    args = sys.argv[1:]
    run = None
    only_id = None
    url_re = None
    headers_only = False
    body_limit = 4000
    raw = False
    i = 0
    while i < len(args):
        a = args[i]
        if a in ("-h", "--help"):
            print(__doc__)
            return 0
        elif a in ("-i", "--id"):
            only_id = int(args[i + 1]); i += 2
        elif a == "--url":
            url_re = re.compile(args[i + 1]); i += 2
        elif a in ("-H", "--headers"):
            headers_only = True; i += 1
        elif a in ("-b", "--body-limit"):
            body_limit = int(args[i + 1]); i += 2
        elif a == "--raw":
            raw = True; i += 1
        elif a.startswith("-"):
            sys.exit(f"unknown option {a}")
        else:
            run = Path(a); i += 1

    run = run or latest_run()
    recs = load(run)
    reqs: dict[int, dict] = {}
    for r in recs:
        if r.get("event") == "request":
            reqs[r["id"]] = {"req": r}
        elif r.get("event") in ("response", "error") and r["id"] in reqs:
            reqs[r["id"]][r["event"]] = r

    print(f"# run {run}")
    for idx in sorted(reqs):
        entry = reqs[idx]
        req = entry["req"]
        if only_id is not None and idx != only_id:
            continue
        if url_re and not url_re.search(req.get("url", "")):
            continue
        resp = entry.get("response")
        err = entry.get("error")
        status = resp.get("status") if resp else ("ERR" if err else "-")
        print("\n" + "=" * 78)
        print(f"[{idx}] {req['method']} {req['url']}  ->  {status}   ({req.get('ts','')})")
        print("-- request headers " + "-" * 58)
        for k, v in req.get("headers", {}).items():
            for one in v:
                print(f"  {k}: {one}")
        if not headers_only and (req.get("body") or req.get("body_raw_file")):
            body = pretty(req.get("body") or "", raw)
            print("-- request body " + "-" * 61)
            print(body[:body_limit] + ("\n… [truncated]" if len(body) > body_limit else ""))
            if req.get("body_raw_file"):
                print(f"  raw file: {req['body_raw_file']}")
        if resp:
            print("-- response headers " + "-" * 57)
            for k, v in resp.get("headers", {}).items():
                for one in v:
                    print(f"  {k}: {one}")
            if not headers_only and (resp.get("body") or resp.get("body_raw_file")):
                body = pretty(resp.get("body") or "", raw)
                print("-- response body " + "-" * 60)
                print(body[:body_limit] + ("\n… [truncated]" if len(body) > body_limit else ""))
                if resp.get("body_raw_file"):
                    print(f"  raw file: {resp['body_raw_file']}")
        if err:
            print(f"-- error: {err.get('error')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
