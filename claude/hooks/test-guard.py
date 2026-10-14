import json, re, shlex, sys

cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")

def ask(reason):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": reason}}))
    sys.exit(0)

if re.search(r"test\.e2e|setup\.e2e|\w+_e2e|MIX_ENV=e2e", cmd):
    ask("Runs the e2e suite")

if re.search(r"\bmix\s+precommit\b", cmd):
    ask("precommit runs the full test suite")

for part in re.split(r"&&|\|\||;|\|", cmd):
    m = re.search(r"\bmix\s+test\b(.*)", part)
    if not m:
        continue
    try:
        args = shlex.split(m.group(1))
    except ValueError:
        args = m.group(1).split()
    targeted = any(a.endswith(".exs") or ".exs:" in a or "test/" in a or a in ("--failed", "--stale") for a in args)
    if not targeted:
        ask("Runs the full test suite")
