# Yazi Default File Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure `yazi` as the default system-wide file manager in place of `thunar`, while retaining `thunar` under Leader Menu `f -> M`.

**Architecture:** Create `desktop-entry/yazi.desktop` running `kitty --class yazi yazi %f`, configure XDG MIME default for `inode/directory`, update SSOT keymaps specification, update `wlr-which-key`, and configure compositor window rules for Niri and Hyprland.

**Tech Stack:** FreeDesktop Desktop Entry specification, XDG MIME (`xdg-mime`), Niri KDL, Hyprland conf, YAML (`wlr-which-key`).

---

### Task 1: Create Desktop Entry and Link via install.sh

**Files:**
- Create: `desktop-entry/yazi.desktop`
- Modify: `install.sh` (verify linking behavior)

- [ ] **Step 1: Create `desktop-entry/yazi.desktop`**
- [ ] **Step 2: Validate desktop entry syntax using `desktop-file-validate`**
- [ ] **Step 3: Run `install.sh` to generate the symlink in `~/.local/share/applications/`**
- [ ] **Step 4: Update desktop database and configure default MIME type via `xdg-mime`**
- [ ] **Step 5: Verify `xdg-mime query default inode/directory` returns `yazi.desktop`**

---

### Task 2: Update SSOT Keymaps Specification

**Files:**
- Modify: `specs/keymaps.md`

- [ ] **Step 1: Update `$FILE_MANAGER` entry in Section 2 (Role Tokens)**
- [ ] **Step 2: Update Leader Menu tree in Section 5 under `[f] ➜ Files & Search` to include `m` (Yazi) and `M` (Thunar)**

---

### Task 3: Update Leader Menu (wlr-which-key)

**Files:**
- Modify: `wlr-which-key/config.yaml`

- [ ] **Step 1: Update submenu `f` to map `m` to `kitty --class yazi yazi` and `M` to `thunar`**
- [ ] **Step 2: Verify YAML syntax of `wlr-which-key/config.yaml`**

---

### Task 4: Update Compositor Window Rules (Niri & Hyprland)

**Files:**
- Modify: `niri/config.kdl`
- Modify: `hypr/hyprland.conf`

- [ ] **Step 1: Add window rule for `app-id=r#"^yazi$"#` in `niri/config.kdl`**
- [ ] **Step 2: Validate Niri config using `niri validate -c niri/config.kdl`**
- [ ] **Step 3: Update `hypr/hyprland.conf` window rules and backslash binding**

---

### Task 5: End-to-End Verification and Git Commit

- [ ] **Step 1: Verify all modified and created files**
- [ ] **Step 2: Commit changes adhering to Conventional Commits**
