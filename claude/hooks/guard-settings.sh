#!/bin/bash
cmd=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))')
if [[ "$cmd" == *"settings.json"* || "$cmd" == *"settings.local.json"* || "$cmd" == *"CLAUDE.md"* || "$cmd" == *"AGENTS.md"* ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Command touches a Claude settings or CLAUDE.md file"}}'
fi
exit 0
