#!/bin/bash
# Делегирует Cursor hook → .claude/hooks/<name>.sh с нормализацией JSON.
set -uo pipefail
HOOK_NAME="$1"
[ -z "$HOOK_NAME" ] && exit 0

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

CLAUDE_HOOK="$IWE_ROOT/.claude/hooks/${HOOK_NAME}.sh"
[ -x "$CLAUDE_HOOK" ] || exit 0

export CLAUDE_PROJECT_DIR="$IWE_ROOT"
export WORKSPACE_DIR="${WORKSPACE_DIR:-$IWE_ROOT}"

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

NORMALIZED=$(printf '%s' "$INPUT" | python3 "$HOOK_DIR/lib/normalize-input.py" 2>/dev/null || echo "$INPUT")
printf '%s' "$NORMALIZED" | "$CLAUDE_HOOK"
exit 0
