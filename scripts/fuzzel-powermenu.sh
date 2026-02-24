#!/usr/bin/env bash

SELECTION="$(printf "1 - Lock\n2 - Suspend\n3 - Log out\n4 - Reboot\n5 - Shutdown" | fuzzel --dmenu -l 7 --placeholder "Power Menu: " -a top --y-margin 40)"

case $SELECTION in
	*"Lock")
		swaylock;;
	*"Suspend")
		systemctl suspend;;
	*"Log out")
		hyprctl dispatch exit;;
	*"Reboot")
		systemctl reboot;;
	*"Shutdown")
		systemctl poweroff;;
esac
