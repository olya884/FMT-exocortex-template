#!/bin/bash
# postToolUse — инжект pending prompt context + pull-on-touch сообщений.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

INPUT=$(cat)
CONV_ID=$(printf '%s' "$INPUT" | conversation_id_from_input)

PARTS=""
PENDING="$STATE_DIR/pending-context-${CONV_ID}.txt"
PULL_MSG="$STATE_DIR/pull-msg-${CONV_ID}.txt"

if [ -s "$PENDING" ]; then
  PARTS="$(cat "$PENDING")"
  rm -f "$PENDING"
fi
if [ -s "$PULL_MSG" ]; then
  PULL="$(cat "$PULL_MSG")"
  rm -f "$PULL_MSG"
  PARTS="${PARTS:+$PARTS

}${PULL}"
fi

if [ -z "$PARTS" ]; then
  echo '{}'
  exit 0
fi

printf '%s' "$PARTS" | python3 -c 'import sys,json; print(json.dumps({"additional_context": sys.stdin.read()}))'
exit 0
