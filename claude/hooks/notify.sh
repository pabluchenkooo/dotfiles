#!/bin/bash
input=$(cat)
msg=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("message","Claude is waiting"))' "$input" | tr -d '"\\')
dir=$(basename "$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("cwd",""))' "$input")")
where="$dir"
if [[ -n "$TMUX_PANE" ]]; then
  pane=$(tmux display-message -p -t "$TMUX_PANE" '#S:#I.#P #W' 2>/dev/null)
  where="$pane · $dir"
fi
osascript -e "display notification \"$msg\" with title \"Claude Code\" subtitle \"$where\" sound name \"Glass\""
