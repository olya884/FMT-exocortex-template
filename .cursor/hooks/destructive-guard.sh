#!/bin/bash
# beforeShellExecution — блокировка необратимых git-операций (из .claude/hooks/destructive-guard.sh).
set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("command",""))' 2>/dev/null || true)
[ -z "$CMD" ] && echo '{"permission":"allow"}' && exit 0

block() {
  jq -n --arg m "$1" '{permission:"deny",user_message:$m,agent_message:$m}'
  exit 0
}

is_git_subcmd() {
  echo "$CMD" | grep -qE "(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+$1"
}

if is_git_subcmd push; then
  if echo "$CMD" | grep -qE -- '(--force([[:space:]]|=|$)|(^|[[:space:]])-[a-zA-Z]*f([[:space:]]|$))' \
     && ! echo "$CMD" | grep -qE -- '--force-with-lease'; then
    block "git push --force запрещён. Используй --force-with-lease или согласуй с пилотом."
  fi
fi

if is_git_subcmd reset && echo "$CMD" | grep -qE -- '--hard'; then
  block "git reset --hard запрещён. Используй git stash."
fi

if is_git_subcmd clean && echo "$CMD" | grep -qE -- '(^|[[:space:]])-[a-zA-Z]*[dfx]'; then
  block "git clean -fdx запрещён. Согласуй с пилотом."
fi

echo '{"permission":"allow"}'
exit 0
