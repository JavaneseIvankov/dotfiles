#!/usr/bin/env bash

data_path="$HOME/.cache/fuzzel-file-exp.cache"

# Get last used path from cache
get_path_cache() {
  [[ -f "$data_path" ]] && cat "$data_path"
}

# Save path to cache
save_path_cache() {
  echo "$1" > "$data_path"
}

# List files/directories in provided path
get_files() {
  local path="$1"
  cd "$path" || exit 1

  local res="../"$'\n'
  for f in *; do
    [[ "$f" == "." ]] && continue
    [[ -d "$f" ]] && res+="$f/"$'\n' || res+="$f"$'\n'
  done

  echo "$res"
}

# Show menu and return selected item as full path
display() {
  local path="$1"
  local content sel sel_path count

  content="$(get_files "$path")"
  count=$(printf "%s" "$content" | wc -l)

  lines="$((count + 1))"
  [[ "$count" -gt 20 ]] && lines=20

  sel="$(printf "%s" "$content" | fuzzel -a top --y-margin 40 --dmenu -l "$lines" -p 'OPEN:'  2>/dev/null)"
#   sel="$(printf "%s" "$content" | walker --dmenu 2>/dev/null)"
  sel="${sel%/}"  # Trim trailing slash from directories

  [[ -z "$sel" ]] && echo "" && return

  sel_path="$path/$sel"
  echo "$sel_path"
}

# Main loop
main() {
  # Start from cached path or current
  local path sel
  path="$(get_path_cache)"
  [[ -z "$path" ]] && path="$(pwd)"

  sel="$(display "$path")"

  while [[ -d "$sel" ]]; do
    path="$sel"
    sel="$(display "$path")"
    [[ -z "$sel" ]] && break
  done

  # Save final directory to cache
  if [[ -f "$sel" ]]; then
    save_path_cache "$(dirname "$sel")"
    xdg-open "$sel" &
  elif [[ -d "$path" ]]; then
    save_path_cache "$path"
  fi
}

main
