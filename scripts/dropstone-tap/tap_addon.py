
"""mitmproxy addon: log Dropstone CLI HTTP traffic (headers, payloads, responses)."""

from __future__ import annotations

import json
import os
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from mitmproxy import http

MAX_BODY = int(os.environ.get("DROPSTONE_TAP_MAX_BODY", str(1 << 20)))
URL_FILTER = os.environ.get("DROPSTONE_TAP_FILTER", "").strip()
HOST_FILTER = [h.strip() for h in os.environ.get("DROPSTONE_TAP_HOSTS", "").split(",") if h.strip()]
REDACT = os.environ.get("DROPSTONE_TAP_REDACT", "") not in ("", "0", "false")
SECRET_HEADERS = {"authorization", "x-api-key", "api-key", "cookie", "set-cookie", "proxy-authorization"}

_seq = 0


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def _out() -> Path:
    return Path(os.environ["DROPSTONE_TAP_OUT"])


def _redact(value: str) -> str:
    v = value.strip()
    if len(v) <= 12:
        return "***"
    return v[:8] + "…" + v[-4:] + f" (len={len(v)})"


def _headers(h) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for k, v in h.items(multi=True):
        key = k.lower()
        if REDACT and key in SECRET_HEADERS:
            out.setdefault(key, []).append(_redact(v))
        else:
            out.setdefault(key, []).append(v)
    return out


def _decoded(msg) -> bytes:
    """Body with content-encoding (gzip/deflate/br/zstd) removed."""
    try:
        content = msg.content
        if content is not None:
            return bytes(content)
    except Exception:
        pass
    return bytes(getattr(msg, "raw_content", None) or b"")


def _body(resp_or_req, raw_attr: str = "", text_attr: str = "") -> tuple[Any, str | None, int, bool]:
    content = _decoded(resp_or_req)
    size = len(content)
    truncated = size > MAX_BODY
    blob = content[:MAX_BODY]
    ctype = (resp_or_req.headers.get("content-type") or "").lower()
    texty = (
        "json" in ctype
        or "text" in ctype
        or "xml" in ctype
        or "javascript" in ctype
        or "x-www-form-urlencoded" in ctype
    )
    if not ctype:
        texty = True
    text = None
    if texty:
        try:
            text = blob.decode("utf-8", errors="replace")
        except Exception:
            text = None
    return (text, ctype, size, truncated)


class Tap:
    def __init__(self) -> None:
        self.out = _out()
        (self.out / "bodies").mkdir(parents=True, exist_ok=True)
        self.log = open(self.out / "flows.jsonl", "a", buffering=1)
        self.streams: dict[str, bytearray] = {}
        self.count = 0

    # ---- helpers -------------------------------------------------
    def wanted(self, flow: http.HTTPFlow) -> bool:
        url = flow.request.pretty_url
        if HOST_FILTER and not any(f in flow.request.host for f in HOST_FILTER):
            return False
        if URL_FILTER and not re.search(URL_FILTER, url):
            return False
        return True

    def next_id(self) -> int:
        self.count += 1
        return self.count

    def write(self, rec: dict[str, Any]) -> None:
        self.log.write(json.dumps(rec, ensure_ascii=False) + "\n")

    def dump_body(self, idx: int, kind: str, data: bytes, ctype: str) -> str | None:
        if not data:
            return None
        name = f"{idx:04d}-{kind}"
        ext = ".txt"
        if "json" in ctype:
            ext = ".json"
        elif "octet-stream" in ctype or "image" in ctype:
            ext = ".bin"
        path = self.out / "bodies" / (name + ext)
        path.write_bytes(data[:MAX_BODY])
        return str(path)

    # ---- hooks ---------------------------------------------------
    def request(self, flow: http.HTTPFlow) -> None:
        if not self.wanted(flow):
            return
        idx = self.next_id()
        flow.metadata["tap_idx"] = idx
        req = flow.request
        text, ctype, size, truncated = _body(req)
        body_path = None
        if not text and size:
            body_path = self.dump_body(idx, "request", req.raw_content or b"", ctype)
        rec = {
            "event": "request",
            "id": idx,
            "ts": _now(),
            "method": req.method,
            "url": req.pretty_url,
            "http_version": req.http_version,
            "headers": _headers(req.headers),
            "body": text,
            "body_size": size,
            "body_truncated": truncated,
            "body_raw_file": body_path,
        }
        self.write(rec)

    def responseheaders(self, flow: http.HTTPFlow) -> None:
        idx = flow.metadata.get("tap_idx")
        if idx is None:
            return
        ctype = (flow.response.headers.get("content-type") or "").lower()
        if "text/event-stream" in ctype:
            buf = bytearray()
            self.streams[str(idx)] = buf

            def tee(chunk: bytes) -> bytes:
                if len(buf) < MAX_BODY:
                    buf.extend(chunk[: MAX_BODY - len(buf)])
                return chunk

            flow.response.stream = tee

    def response(self, flow: http.HTTPFlow) -> None:
        idx = flow.metadata.get("tap_idx")
        if idx is None:
            return
        resp = flow.response
        ctype = (resp.headers.get("content-type") or "").lower()
        streamed = self.streams.pop(str(idx), None)
        if streamed is not None:
            text = streamed.decode("utf-8", errors="replace")
            size = len(streamed)
            truncated = size >= MAX_BODY
            body_path = None
        else:
            text, ctype, size, truncated = _body(resp)
            body_path = None
            if not text and size:
                body_path = self.dump_body(idx, "response", resp.raw_content or b"", ctype)
        rec = {
            "event": "response",
            "id": idx,
            "ts": _now(),
            "url": flow.request.pretty_url,
            "status": resp.status_code,
            "headers": _headers(resp.headers),
            "body": text,
            "body_size": size,
            "body_truncated": truncated,
            "body_raw_file": body_path,
            "streamed": streamed is not None,
        }
        self.write(rec)

    def error(self, flow: http.HTTPFlow) -> None:
        idx = flow.metadata.get("tap_idx")
        if idx is None:
            return
        self.write(
            {
                "event": "error",
                "id": idx,
                "ts": _now(),
                "url": flow.request.pretty_url,
                "error": str(flow.error),
            }
        )

    def done(self) -> None:
        try:
            self.log.close()
        except Exception:
            pass


addons = [Tap()]
