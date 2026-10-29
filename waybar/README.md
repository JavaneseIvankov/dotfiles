# Waybar

Two colour/geometry variants of the same bar, sharing one palette.

| File | Role |
|---|---|
| `flexoki.css` | Flexoki dark tokens — byte-identical to `../swaync/style.css` |
| `modules.css` | shared module styling (dividers, workspaces, states, tooltips) |
| `config-a.jsonc` + `style-a.css` | **Variant A** — full-bleed strip, 1px hairline under the bar |
| `config-b.jsonc` + `style-b.css` | **Variant B** — floating island (A + 6px margins, 1px outline) |
| `config.jsonc` + `style.css` | original look, kept untouched |
| `config.niri.jsonc` | original Niri module set (source for the generator) |
| `mkconfig.py` | regenerates `config-a.jsonc` / `config-b.jsonc` from `config.niri.jsonc` |
| `mediaplayer.py` | `custom/media` backend (playerctl); the old config pointed at a file that did not exist |

## Dock vs float

Two modes, same palette and same module set — only the geometry differs:

| Mode | Variant | Geometry (measured on the live bar) |
|---|---|---|
| `dock` | a | surface flush with the screen: left/top inset 0px, 30px tall, 1px hairline under the bar |
| `float` | b | detached island: left/right inset 6px, top inset 6px, 1px `#343332` ring, `swaync`-card geometry |

```sh
~/scripts/waybar-variant.sh dock      # full-bleed dock (variant a)
~/scripts/waybar-variant.sh float     # floating island (variant b)
~/scripts/waybar-variant.sh toggle    # flip whichever is not active
~/scripts/waybar-variant.sh status    # remembered mode + the running bar
~/scripts/waybar-variant.sh old       # the previous look
```

`toggle` is also on the leader menu: `$LEADER` → `t` → `m` (`$BAR_MODE`).

To change the float inset, edit **`style-b.css`** (`window#waybar > box { margin }`)
and `margin-top` in `config-b.jsonc` — the horizontal inset has to live in the
stylesheet, because niri drops a right-hand margin on a layer surface anchored to
both edges (that is what previously let the island run off the screen).

`a`/`b` still work as raw keys; the state file always stores `a`/`b`/`old`.

The choice is remembered in `~/.local/state/waybar/variant`, and
`niri/config.kdl` spawns the script with no argument at login
(`spawn-sh-at-startup "~/scripts/waybar-variant.sh"`), so the remembered variant
comes back after a reboot.

The script starts the bar **detached** (`setsid` + `disown`, log in
`~/.local/state/waybar/waybar.log`) and exits in ~50ms — it must never `exec`
waybar, or closing the terminal that ran it would kill the bar. Re-running it
for the variant that is already up is a no-op: the script compares
`/proc/<pid>/cmdline` and only restarts when the config/stylesheet actually
differs.

Launching one by hand:

```sh
waybar -c ~/.config/waybar/config-a.jsonc -s ~/.config/waybar/style-a.css
waybar -c ~/.config/waybar/config-b.jsonc -s ~/.config/waybar/style-b.css
```

`-s` is required for both: Waybar always resolves the default stylesheet to
`~/.config/waybar/style.css`, it does **not** look next to `-c`.

## Notes

- Geometry lives in the config (`height`, `spacing`, `margin-*`); the hairline
  dividers are `border-left` on the modules that open a group — an empty
  `custom/separator` collapses to zero width and paints nothing.
- **Spacing hierarchy.** Each module is one visual unit: icon and value are
  joined by exactly **one** space in the format string, and the 8px `.module`
  padding on either side supplies the gap between units. Measured on the live
  bar this is ~8px icon→value vs ~16px module→module, so the pair reads as a
  component instead of two modules.
  Two things break that rule and must not come back:
  1. a second space after the icon span (`"  {value}"`) — doubles the inner gap
     to ~19px, which is *wider* than the gap between modules;
  2. a width spec one digit wider than the value (`{capacity:3}` with `42`),
     because the padding space is invisible and stacks onto the separator —
     another ~19px inner gap. All these values are 0-100, so `{:2}` both
     right-aligns and stays single-digit-safe; 100 just widens once.
- Numbers are padded (`{usage:2}`, `{capacity:2}`, `{temperatureC:2}`,
  `{volume:2}`, `{percent:2}`, `{signalStrength:2}`) so the right cluster does
  not jitter as values change.
- **Workspaces show names.** `niri/workspaces` uses `{value}`, which
  `waybar-niri-workspaces(5)` defines as *"name of the workspace, or index for
  unnamed workspaces"* — so `(1)main` renders as itself while an unnamed
  workspace still shows its number. The two obvious alternatives both lose
  information: `{index}` never shows a name, and `{name}` renders an empty
  button for unnamed workspaces. Names make the cluster ~64px wide each
  (vs ~16px for a bare index), and `niri/window` has `max-length: 50` to stop
  a long title from being pushed off.
- Icons are dimmed via `<span foreground='#87857F'>` (Pango markup cannot read
  `@define-color`), so keep that hex in sync with `tx-2` in `flexoki.css`.
- **Microphone is its own widget.** `wireplumber#mic` — not
  `pulseaudio#mic` — is bound to the `Audio/Source` node, so it reports the
  mic's own volume and mute; the pulseaudio module always tracks the sink and
  would just duplicate the speaker. Left click toggles the source
  (`wpctl set-mute @DEFAULT_AUDIO_SOURCE@`), right click opens pavucontrol's
  Input Devices tab. In CSS the widget is `#wireplumber.mic`: waybar splits
  `module#instance` into a widget name plus a style class, so
  `#wireplumber#mic` matches nothing.
- Never put `format-source`/`format-source-muted` on `pulseaudio`.
  `waybar-pulseaudio(5)` only substitutes `{format_source}`; a
  `{source_volume}` placeholder throws `pulseaudio: argument not found` and
  leaves the label **empty** — the module still reserves space, so it looks
  like a 17px stub (padding only) instead of an icon and a number.
- Edit `mkconfig.py`, then re-run it, to change the module set; both variants
  stay in sync automatically.
