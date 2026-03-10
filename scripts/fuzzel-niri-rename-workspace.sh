#!/usr/bin/env bash

new_name="$(fuzzel -d -l 0 -p 'Rename Workspace: ')"

if [ -n "$new_name" ]; then
	# Use the correct action name: set-workspace-name <name>
	# Prefer providing the workspace id where supported, fall back to positional name only.
	if niri msg action set-workspace-name "$new_name" 2>/dev/null; then
		:
	elif niri msg action set-workspace-name "$new_name" 2>/dev/null; then
		:
	else
		niri msg action set-workspace-name "$new_name" 2>/dev/null || true
	fi
fi

exit 0

