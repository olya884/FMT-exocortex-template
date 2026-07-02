#!/bin/bash
# IWE env for Cursor hooks. Source from any .cursor/hooks/*.sh script.
[ -n "${_IWE_CURSOR_ENV_SOURCED:-}" ] && return 0
_IWE_CURSOR_ENV_SOURCED=1

set -u
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

# Resolve IWE root from workspace_roots in hook JSON or default.
resolve_iwe_root() {
  if [ -n "${IWE_ROOT:-}" ] && [ -d "$IWE_ROOT" ]; then
    echo "$IWE_ROOT"
    return
  fi
  if [ -n "${IWE_WORKSPACE:-}" ] && [ -d "$IWE_WORKSPACE" ]; then
    echo "$IWE_WORKSPACE"
    return
  fi
  if [ -f "$HOME/.iwe-paths" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.iwe-paths"
    if [ -n "${IWE_WORKSPACE:-}" ] && [ -d "$IWE_WORKSPACE" ]; then
      echo "$IWE_WORKSPACE"
      return
    fi
  fi
  if [ -d "$HOME/IWE/CLAUDE.md" ] || [ -f "$HOME/IWE/CLAUDE.md" ]; then
    echo "$HOME/IWE"
    return
  fi
  # Fallback: parent of .cursor/hooks/lib
  local hook_lib
  hook_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "$(cd "$hook_lib/../../.." && pwd)"
}

IWE_ROOT="$(resolve_iwe_root)"
export IWE_ROOT IWE_WORKSPACE="${IWE_WORKSPACE:-$IWE_ROOT}"
STATE_DIR="${HOME}/.cursor/state/iwe"
mkdir -p "$STATE_DIR"
export STATE_DIR

conversation_id_from_input() {
  python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("conversation_id") or d.get("session_id") or "default")' 2>/dev/null || echo "default"
}

prompt_from_input() {
  python3 -c '
import sys, json, re
d = json.load(sys.stdin)
p = d.get("prompt") or ""
p = re.sub(r"[\n\r\t]+", " ", p)
print(p)
' 2>/dev/null || true
}
