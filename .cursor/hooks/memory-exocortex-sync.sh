#!/bin/bash
# postToolUse — зеркало memory/* → DS-strategy/exocortex/ (адаптация .claude/hooks/memory-exocortex-sync.sh)
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
NORMALIZED=$(printf '%s' "$INPUT" | python3 "$HOOK_DIR/lib/normalize-input.py" 2>/dev/null || echo "$INPUT")
FILE_PATH=$(printf '%s' "$NORMALIZED" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.md|*.yaml|*.yml) ;;
  *) exit 0 ;;
esac

WORKSPACE_DIR="${WORKSPACE_DIR:-$IWE_ROOT}"
GOVERNANCE_REPO="${GOVERNANCE_REPO:-DS-strategy}"
HOME_SLUG=$(echo "$HOME" | tr '/_.' '-')
MEMORY_SRC="${IWE_MEMORY_SRC:-$HOME/.claude/projects/${HOME_SLUG}-IWE/memory}"
EXOCORTEX_DST="$WORKSPACE_DIR/$GOVERNANCE_REPO/exocortex"

if [ -z "${IWE_MEMORY_SRC:-}" ] && [ -d "$WORKSPACE_DIR/memory" ]; then
  MEMORY_REAL=$(cd "$WORKSPACE_DIR/memory" 2>/dev/null && pwd -P) || exit 0
else
  MEMORY_REAL=$(cd "$MEMORY_SRC" 2>/dev/null && pwd -P) || exit 0
fi

FILE_DIR=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd -P) || exit 0
[ "$FILE_DIR" = "$MEMORY_REAL" ] || exit 0

FNAME=$(basename "$FILE_PATH")
[ -f "$MEMORY_REAL/$FNAME" ] || exit 0

[ -d "$EXOCORTEX_DST" ] || mkdir -p "$EXOCORTEX_DST" 2>/dev/null || exit 0
cp "$MEMORY_REAL/$FNAME" "$EXOCORTEX_DST/$FNAME" 2>/dev/null || exit 0
exit 0
