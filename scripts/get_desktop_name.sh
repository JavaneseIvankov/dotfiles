#!/usr/bin/env bash

set -euo pipefail

# get_desktop_name.sh
# Usage: get_desktop_name.sh <class>
# Prints a normalized icon name for a given window class/name.

if [ "$#" -lt 1 ]; then
    echo ""
    exit 0
fi

case "$1" in
    code|Code) echo "vscode" ;;
    Chromium-browser|chromium|Chromium) echo "chromium" ;;
    *) echo "$1" ;;
esac
