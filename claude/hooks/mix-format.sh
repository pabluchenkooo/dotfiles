#!/bin/bash
file=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))')
case "$file" in *.ex|*.exs|*.heex) ;; *) exit 0 ;; esac
root=""
dir=$(dirname "$file")
while [[ "$dir" != "/" ]]; do
  [[ -f "$dir/mix.exs" && -f "$dir/.formatter.exs" ]] && root="$dir"
  dir=$(dirname "$dir")
done
[[ -z "$root" ]] && exit 0
cd "$root" && mix format "$file" >/dev/null 2>&1
exit 0
