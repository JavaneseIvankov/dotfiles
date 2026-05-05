#!/usr/bin/env sh

# Path to the conservation mode file
CONSERVATION_MODE_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

# Check if the file exists
if [ ! -f "$CONSERVATION_MODE_PATH" ]; then
    echo "Error: Conservation mode interface not found at $CONSERVATION_MODE_PATH"
    exit 1
fi

# Function to show usage
usage() {
    echo "Usage: $0 {enable|disable|on|off|status}"
    exit 1
}

# Check for argument
if [ $# -eq 0 ]; then
    usage
fi

# Perform action based on argument
case $1 in
    enable|on)
        echo 1 | sudo tee "$CONSERVATION_MODE_PATH" > /dev/null
        echo "Battery conservation mode enabled."
        ;;
    disable|off)
        echo 0 | sudo tee "$CONSERVATION_MODE_PATH" > /dev/null
        echo "Battery conservation mode disabled."
        ;;
    status)
        status=$(cat "$CONSERVATION_MODE_PATH")
        if [ "$status" -eq 1 ]; then
            echo "Conservation mode: ENABLED (charging limited to ~60%)"
        else
            echo "Conservation mode: DISABLED (charging up to 100%)"
        fi
        ;;
    *)
        usage
        ;;
esac   
