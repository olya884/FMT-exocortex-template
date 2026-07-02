#!/bin/bash
# stop — проверка TodoWrite после протокольных скиллов (адаптация protocol-stop-gate.sh)
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

[ "${STOP_HOOK_ACTIVE:-}" = "1" ] && echo '{}' && exit 0
export STOP_HOOK_ACTIVE=1

INPUT=$(cat)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
CONV_ID=$(printf '%s' "$INPUT" | conversation_id_from_input)

if [ -n "$CONV_ID" ]; then
  rm -f "/tmp/iwe-dry-run-${CONV_ID}.flag" 2>/dev/null || true
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo '{}'
  exit 0
fi

GATE_LOG="$IWE_ROOT/.claude/logs/gate_log.jsonl"
mkdir -p "$(dirname "$GATE_LOG")" 2>/dev/null || true

# Протокольные скиллы + TodoWrite (Cursor jsonl и Claude flat transcript)
PARSED=$(python3 "$HOOK_DIR/lib/parse-transcript.py" "$TRANSCRIPT_PATH" 2>/dev/null || echo '{}')
PROTOCOL_SKILL=$(printf '%s' "$PARSED" | jq -r '.protocol_skill // empty')
TODO_MAX=$(printf '%s' "$PARSED" | jq -r '.todo_max // 0')

if [ -z "$PROTOCOL_SKILL" ]; then
  echo '{}'
  exit 0
fi

THRESHOLD=3

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FIRED=0
[ "$TODO_MAX" -lt "$THRESHOLD" ] && FIRED=1

LOG_ENTRY=$(jq -nc \
  --arg ts "$TIMESTAMP" \
  --arg sid "$CONV_ID" \
  --arg skill "$PROTOCOL_SKILL" \
  --arg todo_max "$TODO_MAX" \
  --argjson fired "$FIRED" \
  '{ts: $ts, gate: "protocol-stop-gate", session_id: $sid, skill: $skill,
    todo_max: ($todo_max|tonumber), threshold: 3, fired: $fired, action: "warn", agent: "cursor"}' 2>/dev/null || true)
[ -n "$LOG_ENTRY" ] && echo "$LOG_ENTRY" >> "$GATE_LOG" 2>/dev/null || true

if [ "$FIRED" = "1" ]; then
  MSG="⚠️ PROTOCOL-STOP-GATE: скилл '${PROTOCOL_SKILL}' без TodoWrite ≥${THRESHOLD} (найдено: ${TODO_MAX}). Создай TodoWrite со шагами скилла и пройди протокол заново."
  python3 -c "import json,sys; print(json.dumps({'followup_message': sys.argv[1]}))" "$MSG"
else
  echo '{}'
fi
exit 0
