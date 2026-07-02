#!/bin/bash
# preToolUse — lazy git pull при первом касании IWE-репо за сессию (CLAUDE.md §2 п.5).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/iwe-env.sh
source "$HOOK_DIR/lib/iwe-env.sh"

INPUT=$(cat)
[ -z "$INPUT" ] && echo '{"permission":"allow"}' && exit 0

# Быстрый отсев: нет путей под IWE
echo "$INPUT" | grep -qE "IWE[/\"']" || { echo '{"permission":"allow"}'; exit 0; }

CONV_ID=$(printf '%s' "$INPUT" | conversation_id_from_input)
STATE_FILE="$STATE_DIR/repo-pulled-${CONV_ID}.txt"
PULL_MSG_FILE="$STATE_DIR/pull-msg-${CONV_ID}.txt"
touch "$STATE_FILE"

REPOS=$(INPUT="$INPUT" IWE_ROOT="$IWE_ROOT" python3 -c '
import sys, json, re, os
d = json.loads(os.environ["INPUT"])
ti = d.get("tool_input", {}) or {}
blob = ""
for k in ("file_path", "path", "command", "target_file"):
    v = ti.get(k)
    if v:
        blob += str(v) + "\n"
root = os.environ["IWE_ROOT"]
seen, out = set(), []
# Match IWE/repo or absolute .../IWE/repo
for m in re.finditer(r"(?:^|[\s\"'\''/])IWE/([A-Za-z0-9._-]+)", blob):
    name = m.group(1)
    if name in seen:
        continue
    seen.add(name)
    if os.path.isdir(os.path.join(root, name, ".git")):
        out.append(name)
for m in re.finditer(re.escape(root) + r"/([A-Za-z0-9._-]+)", blob):
    name = m.group(1)
    if name in seen:
        continue
    seen.add(name)
    if os.path.isdir(os.path.join(root, name, ".git")):
        out.append(name)
print("\n".join(out))
' 2>/dev/null)

if [ -z "$REPOS" ]; then
  echo '{"permission":"allow"}'
  exit 0
fi

TO=""
command -v timeout >/dev/null 2>&1 && TO="timeout 20"

warns=""
pulled=""
while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  grep -qxF "$repo" "$STATE_FILE" && continue
  echo "$repo" >> "$STATE_FILE"
  dir="$IWE_ROOT/$repo"
  stash_before=$(git -C "$dir" stash list 2>/dev/null | wc -l | tr -d " ")
  if out=$($TO git -C "$dir" pull --rebase --autostash --quiet 2>&1); then
    [ -n "$out" ] && pulled="${pulled}${repo} "
  else
    git -C "$dir" rebase --abort >/dev/null 2>&1 || true
    warns="${warns}${repo}: pull failed, potentially stale. "
  fi
  stash_after=$(git -C "$dir" stash list 2>/dev/null | wc -l | tr -d " ")
  if [ "${stash_after:-0}" -gt "${stash_before:-0}" ]; then
    warns="${warns}${repo}: stash pop вручную если нужно. "
  fi
done <<< "$REPOS"

msg=""
[ -n "$pulled" ] && msg="🔄 Подтянул: ${pulled}"
[ -n "$warns" ] && msg="${msg}⚠️ ${warns}"
[ -n "$msg" ] && printf '%s' "$msg" > "$PULL_MSG_FILE"

echo '{"permission":"allow"}'
exit 0
