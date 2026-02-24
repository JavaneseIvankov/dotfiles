#!/usr/bin/env sh

todo_cache_file="$HOME/.cache/todo.cache"
todo_cache_tmp_file="$HOME/.cache/todo.tmp"

cache_contents="$(cat "$todo_cache_file")"
cache_lines="$(echo "$cache_contents" | wc -l)"

[ -s "$todo_cache_file" ] || cache_lines=0

selection="$(echo "$cache_contents" | fuzzel -a top --y-margin 40 --dmenu -p "TODO: " -l  "$cache_lines" 2>/dev/null)"

[ -z "$selection" ] && exit 1

if grep -q "^${selection}$" "$todo_cache_file"; then
    grep -v "^${selection}$" "$todo_cache_file" > "$todo_cache_tmp_file"
    mv "$todo_cache_tmp_file" "$todo_cache_file"
else
    echo "$selection" >> "$todo_cache_file"
fi
