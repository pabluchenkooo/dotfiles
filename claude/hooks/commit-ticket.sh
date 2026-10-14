#!/bin/bash
input=$(cat)
cmd=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("tool_input",{}).get("command",""))' "$input")
cwd=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("cwd",""))' "$input")
[[ "$cmd" =~ git[[:space:]].*commit ]] || exit 0
[[ "$cmd" =~ (-m|--message|-F|--file) ]] || exit 0
branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null)
name=${branch##*/}
if [[ "$name" =~ ^([A-Za-z]+[0-9]*)-+([0-9]+) ]]; then
  ticket=$(echo "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}" | tr '[:lower:]' '[:upper:]')
  if ! echo "$cmd" | grep -qi -- "$ticket"; then
    echo "Commit message must start with the ticket id $ticket (branch $branch)." >&2
    exit 2
  fi
fi
exit 0
