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
    if [ -w "$DRIVER_DIR/bind" ] || [ "$(id -u)" -eq 0 ] || sudo -n true 2>/dev/null || true; then
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
