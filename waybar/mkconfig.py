#!/usr/bin/env python3
"""Generate waybar/config-a.jsonc and config-b.jsonc from the existing
config.niri.jsonc, so icons/glyphs are never re-typed by hand.

  A = Flexoki module set, full-bleed        (style-a.css)
  B = A + 6px top margin, floating island   (style-b.css)
"""
import json
import re
import sys

SRC = "/home/arundaya/dotfiles/waybar/config.niri.jsonc"
DST = "/home/arundaya/dotfiles/waybar/config-%s.jsonc"
MUTED = "<span foreground='#87857F'>{}</span>"
RED = "#D14D41"


def strip_jsonc(s: str) -> str:
    out, i, n, instr, esc = [], 0, len(s), False, False
    while i < n:
        c = s[i]
        if instr:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\\\":
                esc = True
            elif c == '"':
                instr = False
            i += 1
            continue
        if c == '"':
            instr = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and s[i + 1] == "/":
            while i < n and s[i] != "\n":
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def nonascii(s: str):
    return [c for c in s if ord(c) > 0x2000]


raw = open(SRC, encoding="utf-8").read()
orig = json.loads(re.sub(r",(\s*[}\]])", r"\1", strip_jsonc(raw)))

cpu_i = nonascii(orig["cpu"]["format"])[0]
mem_i = nonascii(orig["memory"]["format"])[0]
tmp_i = orig["temperature"]["format-icons"][0]
tmp_all = orig["temperature"]["format-icons"]
bat_i = orig["battery"]["format-icons"]
plug_i = nonascii(orig["battery"]["format-plugged"])[0]
chg_i = nonascii(orig["battery"]["format-charging"])[0]
bl_i = orig["backlight"]["format-icons"]
pa = orig["pulseaudio"]
vol_i = pa["format-icons"]["default"]
mute_i = nonascii(pa["format-muted"])[0]
bt_i = nonascii(pa["format-bluetooth-muted"])[0]
src_i = nonascii(pa["format-source"])[0]
srcm_i = nonascii(pa["format-source-muted"])[0]
net = orig["network"]
wifi_i = nonascii(net["format-wifi"])[0]
ppd_i = orig["power-profiles-daemon"]["format-icons"]
idle_i = orig["idle_inhibitor"]["format-icons"]
media_i = orig["custom/media"]["format-icons"]

MODULES_RIGHT = [
    "custom/media",
    "idle_inhibitor",
    "pulseaudio",
    "network",
    "cpu",
    "memory",
    "temperature",
    "backlight",
    "power-profiles-daemon",
    "battery",
    "clock",
    "tray",
]


def build(margins=None):
    c = {
        "layer": "top",
        "position": "top",
        "height": 30,
        "spacing": 0,
    }
    # Only margin-top: niri drops a right-hand margin on a surface anchored to
    # both left and right, so B draws its left/right inset in style-b.css.
    c.update(margins or {})
    c["modules-left"] = ["niri/workspaces", "niri/window"]
    c["modules-right"] = list(MODULES_RIGHT)

    # {value} = workspace name, or the index when the workspace is unnamed
    # (waybar-niri-workspaces(5)); {index} would hide the names, {name} renders
    # empty buttons for unnamed workspaces.
    c["niri/workspaces"] = {"format": "{value}"}
    c["niri/window"] = {"format": "{title}", "max-length": 50}

    c["custom/media"] = {
        "format": "{text}",
        "return-type": "json",
        "interval": 2,
        "max-length": 30,
        "escape": True,
        "tooltip": True,
        "on-click": "playerctl play-pause",
        "on-click-right": "playerctl next",
        "exec": "$HOME/.config/waybar/mediaplayer.py 2>/dev/null",
    }
    c["idle_inhibitor"] = {"format": "{icon}", "format-icons": idle_i}
    c["pulseaudio"] = {
        "scroll-step": 2,
        "format": MUTED.format(vol_i[2]) + " {volume:2}%",
        "format-bluetooth": MUTED.format(bt_i) + " {volume:2}%",
        "format-muted": MUTED.format(mute_i) + " muted",
        "format-source": MUTED.format(src_i) + " {source_volume:2}%",
        "format-source-muted": MUTED.format(srcm_i) + " muted",
        "format-icons": {
            "headphone": pa["format-icons"]["headphone"],
            "hands-free": pa["format-icons"]["hands-free"],
            "headset": pa["format-icons"]["headset"],
            "phone": pa["format-icons"]["phone"],
            "portable": pa["format-icons"]["portable"],
            "car": pa["format-icons"]["car"],
            "default": vol_i,
        },
        "tooltip-format": "{desc} · {volume}%",
        "on-click": "pavucontrol",
    }
    c["network"] = {
        "format-wifi": MUTED.format(wifi_i) + " {signalStrength:2}%",
        "format-ethernet": MUTED.format(wifi_i) + " {ipaddr}",
        "format-linked": MUTED.format(wifi_i) + " {ifname} (no ip)",
        "format-disconnected": MUTED.format(wifi_i) + " offline",
        "format-alt": "{essid}  {ipaddr}",
        "tooltip-format": "{essid} · {signalStrength}%\n{ifname} · {ipaddr}/{cidr}\nvia {gwaddr}",
        "tooltip-format-disconnected": "No network connection",
    }
    c["cpu"] = {
        "interval": 3,
        "format": MUTED.format(cpu_i) + " {usage:2}%",
        "tooltip-format": "load {load1:.2f} · {load5:.2f} · {load15:.2f}\n{usage}% used",
    }
    c["memory"] = {
        "interval": 5,
        "format": MUTED.format(mem_i) + " {percentage:2}%",
        "tooltip-format": "{used} used · {avail} free\n{percentage}% of {total}",
    }
    c["temperature"] = {
        "interval": 5,
        "critical-threshold": 80,
        "format": MUTED.format(tmp_i) + " {temperatureC:2}°",
        "format-critical": MUTED.format(tmp_i) + " <span foreground='" + RED + "'>{temperatureC:2}°</span>",
        "format-icons": tmp_all,
        "tooltip-format": "{temperatureC}°C",
    }
    c["backlight"] = {
        "format": MUTED.format("{icon}") + " {percent:2}%",
        "format-icons": bl_i,
        "tooltip-format": "{percent}%",
    }
    c["power-profiles-daemon"] = {
        "format": "{icon}",
        "tooltip-format": "{profile} profile · {driver}",
        "tooltip": True,
        "format-icons": ppd_i,
    }
    c["battery"] = {
        "interval": 30,
        "states": {"warning": 30, "critical": 15},
        "format": MUTED.format("{icon}") + " {capacity:2}%",
        "format-charging": MUTED.format(chg_i) + " {capacity:2}%",
        "format-plugged": MUTED.format(plug_i) + " {capacity:2}%",
        "format-alt": MUTED.format("{icon}") + " {time}",
        "format-icons": bat_i,
        "tooltip-format": "{capacity}% · {time}",
    }
    c["clock"] = {
        "format": "{:%H:%M}",
        "format-alt": "{:%a %d %b}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
    }
    c["tray"] = {"spacing": 8}
    return c


HEADERS = {
    "a": """// -*- mode: jsonc -*-
// Waybar · Niri · Variant A — "refined flat strip" (full-bleed + 1px hairline).
// Swiss-army entry point: ~/scripts/waybar-variant.sh a|b|old
//   waybar -c ~/.config/waybar/config-a.jsonc -s ~/.config/waybar/style-a.css
// Palette and module rules live in flexoki.css / modules.css (shared with B).
// Generated from config.niri.jsonc by waybar/mkconfig.py — edit that, not this.
""",
    "b": """// -*- mode: jsonc -*-
// Waybar · Niri · Variant B — "floating Flexoki island" (A + 6px margins + outline).
// Swiss-army entry point: ~/scripts/waybar-variant.sh a|b|old
//   waybar -c ~/.config/waybar/config-b.jsonc -s ~/.config/waybar/style-b.css
// The only difference from config-a.jsonc is margin-top; the left/right inset
// of the island is drawn in style-b.css (see the comment there).
// Generated from config.niri.jsonc by waybar/mkconfig.py — edit that, not this.
""",
}

for key, margins in (("a", None), ("b", {"margin-top": 6})):
    text = HEADERS[key] + json.dumps(build(margins), indent=4, ensure_ascii=False) + "\n"
    open(DST % key, "w", encoding="utf-8").write(text)
    print("wrote", DST % key, len(text), "bytes")
print("icons:", repr(cpu_i), repr(mem_i), repr(tmp_i), repr(wifi_i), repr(mute_i))
