#!/usr/bin/env python3
"""Normalize Cursor hook JSON → Claude hook contract."""
import json
import sys

d = json.load(sys.stdin)
out = dict(d)

cid = d.get("conversation_id") or d.get("session_id") or ""
out["session_id"] = cid
ev = d.get("hook_event_name") or "PostToolUse"
if ev == "stop":
    ev = "Stop"
out["hook_event_name"] = ev

ti = dict(d.get("tool_input") or {})
for src in ("path", "target_file", "filePath"):
    if src in ti and "file_path" not in ti:
        ti["file_path"] = ti[src]
        break
out["tool_input"] = ti

if "cwd" not in out and d.get("workspace_roots"):
    roots = d["workspace_roots"]
    if roots:
        out["cwd"] = roots[0]

json.dump(out, sys.stdout)
