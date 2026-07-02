#!/bin/bash
# beforeSubmitPrompt — wp-gate, close-gate, lazy-context → pending file для inject-context.sh
# Cursor не инжектит контекст из beforeSubmitPrompt; мост через postToolUse.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

INPUT=$(cat)
[ -z "$INPUT" ] && echo '{"continue":true}' && exit 0

CONV_ID=$(printf '%s' "$INPUT" | conversation_id_from_input)
PROMPT_LOWER=$(printf '%s' "$INPUT" | prompt_from_input | tr '[:upper:]' '[:lower:]')
PENDING="$STATE_DIR/pending-context-${CONV_ID}.txt"
: > "$PENDING"

MSG=""

# --- WP Gate / Day Open (из wp-gate-reminder.sh) ---
if echo "$PROMPT_LOWER" | grep -qE '(открывай день|открывай$|открой день)'; then
  REAL_DATE=$(date "+%Y-%m-%d %A %H:%M %Z")
  MSG="⛔ DAY OPEN: Реальная дата: ${REAL_DATE}. Используй её для дня недели и фильтров.
Прочитай и выполни .cursor/skills/day-open/SKILL.md пошагово (TodoWrite).
Extensions: extensions/day-open.before.md / .after.md / .checks.md если есть.
SchedulerReport: ~/logs/strategist/$(date +%Y-%m-%d).log"
else
  MSG="⛔ WP GATE: Новая задача → memory/protocol-open.md. Продолжение того же РП → работай. Вопрос → работа = эскалация."
fi

# --- Close Gate (из close-gate-reminder.sh, адаптировано под Cursor skills) ---
if echo "$PROMPT_LOWER" | grep -qE '(итоги дня|закрываю день|закрывай день)'; then
  MSG="⛔ БЛОКИРУЮЩЕЕ: Day Close ТОЛЬКО через скилл run-protocol (аргумент day-close).
ПЕРВОЕ действие: прочитай .cursor/skills/run-protocol/SKILL.md и выполни day-close пошагово.
НЕ читай protocol-close.md вручную без run-protocol."
elif echo "$PROMPT_LOWER" | grep -qE '(закрывай сессию|закрываю сессию)'; then
  MSG="⛔ Session Close через .cursor/skills/run-protocol/SKILL.md (аргумент close). Пошагово, с верификацией."
elif echo "$PROMPT_LOWER" | grep -qE '(заливай|запуши|закрывай$)'; then
  MSG="⛔ Push/Close: commit+push по всем репо с незафиксированным. Затем run-protocol close если закрытие сессии."
fi

# --- Lazy context loader (из lazy-context-loader.sh) ---
MEM_DIR="$IWE_ROOT/memory"
inject_file() {
  local file="$1" label="$2"
  [ -f "$file" ] && MSG="${MSG}

[Lazy-load: ${label}]
$(cat "$file")"
}

if echo "$PROMPT_LOWER" | grep -qE '(security audit|secaudit|b7\.|stride|аудит безопасн|audit cadence|security\.posture)'; then
  inject_file "${MEM_DIR}/security-audit-cadence.md" "security-audit-cadence"
elif echo "$PROMPT_LOWER" | grep -qE '(systemctl|iwe-.*timer|systemd user unit|iwe-strategist|iwe-extractor|iwe-exocortex)'; then
  inject_file "${MEM_DIR}/systemd-scheduler-reference.md" "systemd-scheduler-reference"
elif echo "$PROMPT_LOWER" | grep -qE '(система-в-роли|целевая система проект|fpf a\.[0-9]|скрипт.*агент)'; then
  inject_file "${MEM_DIR}/distinctions-warm.md" "distinctions-warm"
fi

if [ -n "$MSG" ]; then
  printf '%s' "$MSG" > "$PENDING"
fi

echo '{"continue":true}'
exit 0
