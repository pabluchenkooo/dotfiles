import json, re, sys

data = json.load(sys.stdin)
cmd = data.get("tool_input", {}).get("command", "")
cwd = data.get("cwd", "")

if re.search(r"\bmix\s+gettext\.(extract|merge)\b", cmd):
    scoped = "/apps/" in cwd + "/" or re.search(r"\bcd\s+\S*apps/\w+", cmd) or re.search(r"--app\s+\w+", cmd)
    if not scoped:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
            "permissionDecisionReason": "Run gettext from the app dir (cd apps/<app>), never from the umbrella root: it invalidates _build."}}))
