#!/usr/bin/env bash

slurp_result="$(slurp)"

if [[ $? -eq 1 ]]; then
  exit 1
fi

(grim -g "$slurp_result" - | wl-copy) && notify-send "Screenshot captured";
