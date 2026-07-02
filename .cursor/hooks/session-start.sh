#!/bin/bash
# sessionStart — базовый контекст IWE на старт сессии Cursor.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

REAL_DATE="$(date "+%Y-%m-%d %A %H:%M %Z")"

python3 -c "
import json
ctx = '''⛔ IWE / Cursor Agent
Рабочая директория: ${IWE_ROOT}
Реальная дата: ${REAL_DATE} — используй её, не system currentDate.

WP Gate: любое новое задание → memory/protocol-open.md ДО работы.
Pull-on-Touch: git pull --rebase при первом касании репо за сессию.
Протоколы: .cursor/skills/ (day-open, day-close, run-protocol, archgate, wp-new).
Git staging: только git add <конкретный-файл>; запрещены git add -u / . / -A.
'''
print(json.dumps({'additional_context': ctx}))
"
exit 0
