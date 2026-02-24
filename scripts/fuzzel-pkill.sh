#!/usr/bin/env bash

# _fuzzel(){ 
#   fuzzel -a top --y-margin 40 "$@" 
# }
# selected="$(ps -au "$USER" | _fuzzel -d -i --placeholder "Type to search and kill" | awk '{print $1" " $4}')"
# if [[ ! -z $selected ]]; then
#     answer="$(echo -e "Yes\nNo" | \
#             _fuzzel -l 2 -d -i -p '$selected will be killed, are you sure?')"
#     if [[ $answer == "Yes" ]]; then
#         selpid="$(awk '{print $1}' <<< $selected)"; 
#         kill -9 $selpid
#     fi
# fi
# exit 0

!/usr/bin/env bash

# Function that wraps fuzzel with custom appearance
_fuzzel() {
    fuzzel -a top --y-margin 40 "$@"
}

selected="$(ps -u "$USER" --no-headers | _fuzzel -d -i --placeholder "Type to search and kill" | awk '{print $1" "$NF}')"

if [[ -n "$selected" ]]; then
    answer="$(echo -e "Yes\nNo" | _fuzzel -l 2 -d -i -p "$selected will be killed, are you sure?")"

    if [[ "$answer" == "Yes" ]]; then
        selpid="$(awk '{print $1}' <<< "$selected")"
        kill -9 "$selpid"
    fi
fi

exit 0
