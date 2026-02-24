if [[ -z "$(pgrep waybar)" ]]; then
  waybar &
  disown
else 
  pkill waybar
fi
