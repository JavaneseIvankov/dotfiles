# SwayNC Appearance Config — Design (2026-10-26)

## Goal
Create `~/dotfiles/swaync/` (`config.json` + `style.css`) so SwayNotificationCenter matches the desktop's waybar theme: monochrome black background, white text, JetBrainsMono Nerd Font, sharp corners, thin gray `rgba(100,114,125,0.5)` borders.

## Decisions
- **Theme direction:** match waybar (option a) — cohesive with existing monochrome bar/launcher styling.
- **Placement:** popups top-right; control center top-right with `margin-top: 36` (waybar height 30 + 6px gap) and `margin-right: 6`. Popup windows have no margin keys in swaync 0.12.6, so popup placement is accepted as-is (layer `overlay`).
- **CSS strategy:** `cssPriority: "user"`; the shipped default CSS loads underneath, so user `style.css` only overrides the `:root` variables (`--cc-bg`, `--noti-bg*`, `--text-color`, `--bg-selected`, `--border-radius: 0`, fonts) plus monochrome styling for `.control-center`, `.notification`, `.widget-title`, `.widget-dnd`, `.widget-mpris`, close buttons, scrollbar.
- **Control center:** 420×640, widgets `title, dnd, mpris, notifications`; mpris autohide; stock example `scripts` / `notification-visibility` blocks dropped (inert examples keep config tidy).
- **Timeouts:** 10s normal / 5s low / critical sticky; `hide-on-action: true`; `keyboard-shortcuts: true`.

## Wiring
- `install.sh`: `link "$HOME/dotfiles/swaync" "$HOME/.config/swaync"`.
- SSOT: no keymap changes — toggle already lives at leader `[n]` → `$NOTIFICATION_CENTER` in `specs/keymaps.md`.

## Validation (performed)
1. `jq empty config.json` — valid JSON; all keys verified against `/etc/xdg/swaync/configSchema.json`.
2. `swaync-client -R` reload accepted; no daemon restart (client-only command).
3. Test notification sent (`notify-send`) and appeared (count incremented, DND off).
4. Panel screenshot pixel probe: right-side area renders dark (~`rgb(37,36,35)`) against light wallpaper; bar region remains pure black.
5. Visual artifact: `/tmp/swaync-verify.png` (ephemeral).

## Out of scope
- DND keybinding, widget buttons-grid quick toggles, per-app notification filtering rules.
