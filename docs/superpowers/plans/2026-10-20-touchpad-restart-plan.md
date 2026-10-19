# Touchpad Recalibration Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a robust script `restart-touchpad.sh` that recalibrates the laptop touchpad to eliminate electrical noise and baseline drift, with sysfs unbind/bind, deep module reload fallback, desktop notification alerts, and passwordless sudo integration.

**Architecture:** A standalone shell script in `~/dotfiles/scripts/restart-touchpad.sh` with a symlink in `~/.local/bin/restart-touchpad`. It executes a pre-reset warning, performs a clean sysfs unbind/power-down, waits 1.5 seconds for charge dissipation, rebinds to trigger hardware baseline calibration, and provides `--deep` and `--install-sudoers` options.

**Tech Stack:** POSIX Shell (`sh`), Linux Sysfs (`/sys/bus/i2c/drivers/i2c_hid_acpi/`), `kmod` (`modprobe`), `libnotify` (`notify-send`), `sudo` / `visudo`.

---

### Task 1: Create the Touchpad Recalibration Script

**Files:**
- Create: `~/dotfiles/scripts/restart-touchpad.sh`

- [ ] **Step 1: Write the script implementation**

```bash
#!/usr/bin/env sh
#
# restart-touchpad.sh
# Recalibrates touchpad to clear electrical noise and capacitive drift.
#
set -eu

DEVICE_NAME="i2c-MSFT0001:01"
DRIVER_DIR="/sys/bus/i2c/drivers/i2c_hid_acpi"
SCRIPT_PATH="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/$(basename -- "$0")"
SUDOERS_FILE="/etc/sudoers.d/restart-touchpad"

notify() {
    title="$1"
    msg="$2"
    urgency="${3:-normal}"
    echo "[$title] $msg"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -a "Touchpad Recalibration" "$title" "$msg" 2>/dev/null || true
    fi
}

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Recalibrates the laptop touchpad by power-cycling the controller to clear
electrical noise, capacitive baseline drift, and erratic cursor jumps.

Options:
  -d, --deep             Perform a deep reset (reload kernel modules i2c_hid_acpi and i2c_hid)
  --install-sudoers      Install passwordless sudo rule in /etc/sudoers.d for this script
  -h, --help             Show this help message

IMPORTANT:
  Keep your hands OFF the touchpad during recalibration (~2 seconds)
  so the controller can calibrate a clean ambient baseline.
EOF
    exit 0
}

install_sudoers() {
    user="$(id -un)"
    tmp_file="$(mktemp /tmp/restart-touchpad-sudoers.XXXXXX)"
    echo "$user ALL=(ALL) NOPASSWD: $SCRIPT_PATH" > "$tmp_file"
    
    echo "Validating sudoers entry with visudo..."
    if ! visudo -cf "$tmp_file" >/dev/null; then
        echo "Error: Generated sudoers syntax is invalid." >&2
        rm -f "$tmp_file"
        exit 1
    fi

    echo "Installing sudoers rule to $SUDOERS_FILE..."
    run_privileged cp "$tmp_file" "$SUDOERS_FILE"
    run_privileged chmod 0440 "$SUDOERS_FILE"
    rm -f "$tmp_file"
    echo "Successfully installed $SUDOERS_FILE"
    echo "You can now run '$SCRIPT_PATH' without a password prompt (ideal for Niri keybindings)."
    exit 0
}

reset_sysfs() {
    notify "Touchpad Recalibration" "Hands off touchpad for 2s — recalibrating sensor baseline..." "critical"

    # Step 1: Unbind device (puts device into low-power sleep)
    if [ -e "$DRIVER_DIR/$DEVICE_NAME" ]; then
        echo "$DEVICE_NAME" | run_privileged tee "$DRIVER_DIR/unbind" >/dev/null
    fi

    # Step 2: Dissipation pause - allows charge & baseline capacitance to settle
    sleep 1.5

    # Step 3: Rebind device (triggers I2C_HID_PWR_ON and I2C_HID_CMD_RESET)
    if [ -w "$DRIVER_DIR/bind" ]; then
        echo "$DEVICE_NAME" | run_privileged tee "$DRIVER_DIR/bind" >/dev/null
    fi

    # Step 4: Verification
    sleep 0.5
    if [ -e "$DRIVER_DIR/$DEVICE_NAME" ]; then
        notify "Touchpad Ready" "Touchpad baseline recalibration complete." "normal"
        return 0
    else
        echo "Sysfs bind verification failed, falling back to deep reset..." >&2
        return 1
    fi
}

reset_deep() {
    notify "Touchpad Deep Reset" "Reloading kernel drivers (hands off for 2s)..." "critical"

    run_privileged modprobe -r i2c_hid_acpi i2c_hid || true
    sleep 1.5
    run_privileged modprobe i2c_hid_acpi

    sleep 0.5
    if grep -q "Touchpad" /proc/bus/input/devices 2>/dev/null; then
        notify "Touchpad Ready" "Touchpad kernel module reset complete." "normal"
        return 0
    else
        notify "Touchpad Error" "Failed to re-initialize touchpad device." "critical"
        return 1
    fi
}

main() {
    DEEP=0

    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--deep)
                DEEP=1
                shift
                ;;
            --install-sudoers)
                install_sudoers
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    if [ "$DEEP" -eq 1 ]; then
        reset_deep
    else
        if ! reset_sysfs; then
            reset_deep
        fi
    fi
}

main "$@"
```

- [ ] **Step 2: Make the script executable**

Run: `chmod +x /home/arundaya/dotfiles/scripts/restart-touchpad.sh`

- [ ] **Step 3: Syntax check the script with sh -n**

Run: `sh -n /home/arundaya/dotfiles/scripts/restart-touchpad.sh`
Expected: Return 0 with no syntax errors.

---

### Task 2: Set Up Symlink and CLI Integration

**Files:**
- Create symlink: `~/.local/bin/restart-touchpad` -> `~/dotfiles/scripts/restart-touchpad.sh`

- [ ] **Step 1: Create symlink in ~/.local/bin**

Run: `ln -sf /home/arundaya/dotfiles/scripts/restart-touchpad.sh /home/arundaya/.local/bin/restart-touchpad`

- [ ] **Step 2: Verify symlink target and help command**

Run: `restart-touchpad --help`
Expected: Output showing the usage and explanation without error.

---

### Task 3: Commit and Verification

**Files:**
- Commit: `~/dotfiles/scripts/restart-touchpad.sh`
- Commit: `~/dotfiles/docs/superpowers/plans/2026-10-20-touchpad-restart-plan.md`

- [ ] **Step 1: Commit files to git**

Run:
```bash
git -C /home/arundaya/dotfiles add scripts/restart-touchpad.sh docs/superpowers/plans/2026-10-20-touchpad-restart-plan.md
git -C /home/arundaya/dotfiles commit -m "feat: add touchpad electrical noise recalibration script"
```

- [ ] **Step 2: End-to-end verification**

Run: `restart-touchpad --help` and verify readiness.
