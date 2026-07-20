#!/usr/bin/env python3
"""Parse Cursor/Claude agent transcript for protocol-stop-gate."""
import json
import re
import sys

path = sys.argv[1]
protocol_skills = {"day-open", "day-close", "run-protocol", "wp-new"}
protocol_skill = None
todo_max = 0

skill_path_re = re.compile(
    r"\.(?:cursor|claude)/skills/(day-open|day-close|run-protocol|wp-new)/"
)


def count_todos(name, inp):
    """Return todo list length if this tool_use is a TodoWrite call, else 0."""
    if not isinstance(inp, dict):
        return 0
    # Native TodoWrite (Claude / older Cursor)
    if name == "TodoWrite":
        todos = inp.get("todos") or []
        return len(todos) if isinstance(todos, list) else 0
    # Cursor dynamic tools: CallDynamicTool(namespace=cursor, toolName=TodoWrite)
    if name == "CallDynamicTool" and inp.get("toolName") == "TodoWrite":
        args = inp.get("arguments") or {}
        if isinstance(args, dict):
            todos = args.get("todos") or []
            return len(todos) if isinstance(todos, list) else 0
    return 0


with open(path, encoding="utf-8", errors="replace") as f:
    raw = f.read()

# Cursor jsonl: one JSON object per line
for line in raw.splitlines():
    line = line.strip()
    if not line:
        continue
    try:
        d = json.loads(line)
    except json.JSONDecodeError:
        continue

    # Claude flat tool_use line
    if d.get("type") == "tool_use":
        name = d.get("name", "")
        inp = d.get("input") or {}
        n = count_todos(name, inp)
        if n:
            todo_max = max(todo_max, n)
        if name == "Skill" and inp.get("skill") in protocol_skills:
            protocol_skill = inp["skill"]

    # Cursor nested assistant message
    if d.get("role") == "assistant":
        for item in d.get("message", {}).get("content") or []:
            if not isinstance(item, dict) or item.get("type") != "tool_use":
                continue
            name = item.get("name", "")
            inp = item.get("input") or {}
            n = count_todos(name, inp)
            if n:
                todo_max = max(todo_max, n)
            if name == "Skill" and inp.get("skill") in protocol_skills:
                protocol_skill = inp["skill"]

# Fallback: path mentions in full transcript text
if not protocol_skill:
    m = skill_path_re.search(raw)
    if m:
        protocol_skill = m.group(1)

print(json.dumps({"protocol_skill": protocol_skill or "", "todo_max": todo_max}))
