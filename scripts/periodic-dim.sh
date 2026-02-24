#!/usr/bin/env sh

dim() {
  brightnessctl -s;
  brightnessctl s 5%;
  sleep 0.25s;
  brightnessctl -r;
}



notify(){
  dunstify -t 1000 'blink!' 
}

while [[ true ]]; do
  sleep $1;
  dim &>/dev/null;
  notify &>/dev/null;
done


