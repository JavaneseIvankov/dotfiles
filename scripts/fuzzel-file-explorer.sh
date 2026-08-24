#!/usr/bin/env bash

data_path="$HOME/.cache/fuzzel-file-exp.cache"

canonical_dir() {
  local path="$1"

  [[ -d "$path" ]] && realpath -- "$path"
}

# Get last used path from cache
get_path_cache() {
  local path

  [[ -f "$data_path" ]] || return
  path="$(cat "$data_path")"
  canonical_dir "$path"
}

# Save path to cache
save_path_cache() {
  local path

  path="$(canonical_dir "$1")" || return
  printf '%s\n' "$path" > "$data_path"
}

# List files/directories in provided path
get_files() {
  local path="$1"

  (
    cd "$path" || exit 1
    shopt -s nullglob

    printf '../\n'
    for f in *; do
      [[ -d "$f" ]] && printf '%s/\n' "$f" || printf '%s\n' "$f"
    done
  )
}

# Show menu and return selected item as full path
display() {
  local path="$1"
  local content sel sel_path count lines

  content="$(get_files "$path")"
  count=$(printf "%s" "$content" | wc -l)

  lines="$((count + 1))"
  [[ "$count" -gt 20 ]] && lines=20

  sel="$(printf "%s" "$content" | fuzzel -a top --y-margin 40 --dmenu -l "$lines" -p 'OPEN:'  2>/dev/null)"
#   sel="$(printf "%s" "$content" | walker --dmenu 2>/dev/null)"
  sel="${sel%/}"  # Trim trailing slash from directories

  [[ -z "$sel" ]] && echo "" && return

  sel_path="$(realpath -- "$path/$sel")" || return
  echo "$sel_path"
}

# Main loop
main() {
  # Start from cached path or current
  local path sel
  path="$(get_path_cache)"
  [[ -z "$path" ]] && path="$(pwd)"
  path="$(canonical_dir "$path")" || path="$HOME"
  save_path_cache "$path"

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
