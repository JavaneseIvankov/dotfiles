#!/usr/bin/env python3
"""Waybar custom/media: now-playing line for the first available MPRIS player.

Replaces the mediaplayer.py the old configs pointed at (which never existed, so
the media module was silently dropped). Emits one JSON object:

    {"text": ..., "alt": ..., "tooltip": ..., "class": ...}

The leading glyph encodes the *state* (play / pause), so the module reads the
same whatever player is running. With no player the text is empty and the
module disappears instead of leaving a stray icon behind.
"""

from __future__ import annotations

import json
import subprocess
from typing import List

FIELDS = "{{playerName}}\t{{status}}\t{{artist}}\t{{title}}\t{{album}}"
GLYPH = {"playing": "\uf04b", "paused": "\uf04c", "stopped": "\uf04b"}
CLASSES = {"Playing": "playing", "Paused": "paused", "Stopped": "stopped"}


def playerctl(*args: str) -> str:
    """Run playerctl and return its stdout, or "" on any failure."""
    try:
        proc = subprocess.run(
            ("playerctl", *args), capture_output=True, text=True, timeout=3
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return proc.stdout.strip() if proc.returncode == 0 else ""


def emit(text: str, alt: str, tooltip: str, klass: str) -> None:
    print(
        json.dumps(
            {"text": text, "alt": alt, "tooltip": tooltip, "class": klass},
            ensure_ascii=False,
        ),
        flush=True,
    )


def main() -> None:
    out = playerctl("metadata", "--format", FIELDS)
    if not out:
        emit("", "", "No media player", "stopped")
        return

    parts: List[str] = out.split("\t")
    parts += [""] * (5 - len(parts))
    player, status, artist, title, album = [p.strip() for p in parts[:5]]

    klass = CLASSES.get(status, "stopped")
    body = " — ".join(x for x in (artist, title) if x) or album or player or "unknown"
    tooltip = " · ".join(x for x in (title, artist, album) if x) or body
    emit(
        f"{GLYPH[klass]}  {body}",
        player.lower(),
        f"{tooltip}\n{player} · {status.lower()}",
        klass,
    )


if __name__ == "__main__":
    main()
