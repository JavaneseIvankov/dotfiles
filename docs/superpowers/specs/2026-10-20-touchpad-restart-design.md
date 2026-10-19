# Touchpad Electrical Noise Recalibration Script Design

## 1. Overview
On laptops with capacitive I2C touchpads (specifically ELAN `04F3:31B8` / ACPI `MSFT0001:01`), electrical noise and static charge buildup (often caused by AC power adapters, poor grounding, or humidity) cause capacitive baseline drift. This results in erratic cursor jumps, discarded touches (`Touch jump detected and discarded`), and unresponsive gestures.

This design specifies a utility script `restart-touchpad.sh` to trigger hardware baseline recalibration by cleanly power-cycling the touchpad controller via sysfs unbind/bind with a charge dissipation pause, providing a fallback kernel module reload, and integrating with desktop notifications and passwordless sudo for desktop keybindings (Niri).

## 2. Hardware & Environment Context
- **Touchpad Device**: `MSFT0001:01 04F3:31B8 Touchpad` (Bus 0018, I2C ACPI)
- **Driver Module**: `i2c_hid_acpi` (backed by `i2c_hid` and `hid_multitouch`)
- **Sysfs Paths**:
  - Unbind: `/sys/bus/i2c/drivers/i2c_hid_acpi/unbind`
  - Bind: `/sys/bus/i2c/drivers/i2c_hid_acpi/bind`
  - Device Node: `i2c-MSFT0001:01`
- **Compositor**: Niri (Wayland)
- **Notification Daemon**: Sway Notification Center (`swaync`) / `notify-send`

## 3. Reset Flow & Recalibration Strategy

### 3.1 Normal Mode (Sysfs Reset - Default)
1. **Pre-reset Warning**:
   - Issue desktop notification via `notify-send` and print to terminal:
     *"Recalibrating touchpad: please keep your hands off the touchpad for 2 seconds..."*
   - Critical: Touching the capacitive surface during the MCU power-on self-test (POST) contaminates the ambient baseline calibration.
2. **Controller Sleep & Unbind**:
   - Write `i2c-MSFT0001:01` to `/sys/bus/i2c/drivers/i2c_hid_acpi/unbind`.
   - Driver issues `I2C_HID_PWR_SLEEP` and detaches the input device.
3. **Charge Dissipation Window**:
   - Sleep 1.5 seconds to allow residual charge and parasitic capacitance to settle.
4. **Power-On & Hardware Reset**:
   - Write `i2c-MSFT0001:01` to `/sys/bus/i2c/drivers/i2c_hid_acpi/bind`.
   - Driver issues `I2C_HID_PWR_ON` followed by `I2C_HID_CMD_RESET`, commanding the ELAN firmware to execute its baseline calibration routine.
5. **Verification**:
   - Check if `/sys/bus/i2c/drivers/i2c_hid_acpi/i2c-MSFT0001:01` re-attached within 2 seconds.
   - If verification fails, automatically attempt the Deep Reset.

### 3.2 Deep Reset Mode (`--deep` or Auto-Fallback)
1. Detach/unload kernel modules:
   - `modprobe -r i2c_hid_acpi i2c_hid`
2. Sleep 1.5 seconds.
3. Reload driver:
   - `modprobe i2c_hid_acpi`
4. Verify device recreation in `/proc/bus/input/devices`.

### 3.3 Completion Feedback
- Post-reset desktop notification: *"Touchpad recalibration complete."*

## 4. CLI Interface & Helper Flags
- `restart-touchpad` (default: fast sysfs recalibration)
- `restart-touchpad --deep` (force full kernel module reload)
- `restart-touchpad --install-sudoers` (installs `/etc/sudoers.d/restart-touchpad` with visudo validation)
- `restart-touchpad --help` / `-h` (usage and explanation)

## 5. Security & Sudoers Integration
- Script uses `sudo` internally for privileged sysfs writes and modprobe commands.
- For seamless shortcut execution in Niri without an interactive terminal:
  - `--install-sudoers` creates `/etc/sudoers.d/restart-touchpad` containing:
    ```
    arundaya ALL=(ALL) NOPASSWD: /home/arundaya/dotfiles/scripts/restart-touchpad.sh
    ```
  - Validated with `visudo -cf` before activating to prevent syntax errors.

## 6. Implementation Files
- Script: `~/dotfiles/scripts/restart-touchpad.sh`
- Symlink: `~/.local/bin/restart-touchpad` -> `~/dotfiles/scripts/restart-touchpad.sh`
