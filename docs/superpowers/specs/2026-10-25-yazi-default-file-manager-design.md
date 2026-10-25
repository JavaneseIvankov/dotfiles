# Yazi as Default File Manager Design

## Goal
Set `yazi` as the primary and default file manager across the desktop environment, replacing `thunar`, while keeping `thunar` available as an alternative via Leader Menu `f -> M`.

## Architecture & Integration Points
1. **Desktop Entry (`desktop-entry/yazi.desktop`):**
   - Provide a `.desktop` file using `Exec=kitty --class yazi yazi %f` and `Terminal=false`.
   - Sets Wayland `app-id=yazi` and launches inside canonical `$TERMINAL` (`kitty`).
   - Declares `MimeType=inode/directory;`.
   - Symlinked via `install.sh` to `~/.local/share/applications/yazi.desktop`.

2. **System-wide Default Handler (XDG MIME):**
   - Set `yazi.desktop` as default for `inode/directory` via `xdg-mime default yazi.desktop inode/directory`.
   - Ensures `xdg-open`, browser downloads, and external file managers route directory opens to Yazi.

3. **SSOT (`specs/keymaps.md`):**
   - Update `$FILE_MANAGER` to `yazi` (`kitty --class yazi yazi`).
   - Update Leader Menu documentation under `[f] ➜ Files & Search` to reflect:
     - `[m] ➜ File Manager (Yazi): launch($FILE_MANAGER)`
     - `[M] ➜ File Manager GUI (Thunar): launch(thunar)`
     - `[p] ➜ File Picker Fuzzy: launch($FILE_PICKER)`

4. **Leader Menu (`wlr-which-key/config.yaml`):**
   - Update `f -> m` to `File Manager (Yazi)` executing `kitty --class yazi yazi`.
   - Add `f -> M` for `File Manager (Thunar)` executing `thunar`.

5. **Window Manager Rules:**
   - **Niri (`niri/config.kdl`):** Add window rule for `app-id=r#"^yazi$"#` with floating mode enabled (`proportion 0.6` width, `0.7` height).
   - **Hyprland (`hypr/hyprland.conf`):** Add `yazi` class to floating/centering rules, update `$mainMod, backslash` to `kitty --class yazi yazi`.

6. **Validation:**
   - Validate desktop entry with `desktop-file-validate`.
   - Validate Niri config with `niri validate -c niri/config.kdl`.
   - Validate XDG mime query: `xdg-mime query default inode/directory`.
