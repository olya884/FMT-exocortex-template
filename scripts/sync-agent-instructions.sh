#!/usr/bin/env bash
# routing: utility  deterministic=true
# see WP-394 Ф4.2, DP.SC.159
# sync-agent-instructions.sh — генерация AGENTS.md, .cursorrules из единого ядра CLAUDE.md
#
# Сборка:
#   AGENTS.md     = [header] + [SYNC-CORE] + [AGENTS-agent-blocks.md]
#   .cursorrules  = [header] + [SYNC-CORE] + [CURSOR-agent-blocks.md]
#   .cursor/rules/iwe-sync-core.mdc = [frontmatter] + [SYNC-CORE]
#
# Использование:
#   ./scripts/sync-agent-instructions.sh            # dry-run (default)
#   ./scripts/sync-agent-instructions.sh --force    # записать все targets
#   ./scripts/sync-agent-instructions.sh --check    # exit 1 при drift
#   ./scripts/sync-agent-instructions.sh --cursor-only --force
#   ./scripts/sync-agent-instructions.sh --help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IWE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export IWE_ROOT

CLAUDE_MD="$IWE_ROOT/CLAUDE.md"
AGENTS_BLOCKS="$IWE_ROOT/AGENTS-agent-blocks.md"
CURSOR_BLOCKS="$IWE_ROOT/CURSOR-agent-blocks.md"
OUT_AGENTS="$IWE_ROOT/AGENTS.md"
OUT_CURSORRULES="$IWE_ROOT/.cursorrules"
OUT_MDC="$IWE_ROOT/.cursor/rules/iwe-sync-core.mdc"

MODE="dry-run"
TARGET="all"
for arg in "$@"; do
  case "$arg" in
    --force)       MODE="force" ;;
    --check)       MODE="check" ;;
    --cursor-only) TARGET="cursor" ;;
    --agents-only) TARGET="agents" ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -24
      exit 0 ;;
    *) echo "Неизвестный аргумент: $arg (см. --help)" >&2; exit 2 ;;
  esac
done

if ! grep -q '<!-- SYNC-CORE-START -->' "$CLAUDE_MD" || ! grep -q '<!-- SYNC-CORE-END -->' "$CLAUDE_MD"; then
  echo "[ABORT] В $CLAUDE_MD нет маркеров SYNC-CORE." >&2
  exit 3
fi

extract_core() {
  awk '
    /^[[:space:]]*<!-- SYNC-CORE-START -->[[:space:]]*$/ { grab=1; next }
    /^[[:space:]]*<!-- SYNC-CORE-END -->[[:space:]]*$/   { grab=0 }
    grab { print }
  ' "$CLAUDE_MD"
}

extract_agent_blocks() {
  local file="$1" start_marker="$2" end_marker="$3"
  awk -v s="$start_marker" -v e="$end_marker" '
    $0 ~ s { grab=1; next }
    $0 ~ e   { grab=0; next }
    grab {
      if ($0 ~ /^<!--/ && $0 !~ /-->/) { incomment=1 }
      if (incomment) { if ($0 ~ /-->/) { incomment=0 }; next }
      print
    }
  ' "$file"
}

build_agents() {
  if [ ! -f "$AGENTS_BLOCKS" ]; then
    echo "[WARN] $AGENTS_BLOCKS не найден — AGENTS.md пропущен" >&2
    return 1
  fi
  cat <<'HEADER'
# AGENTS.md

> **Сгенерировано `scripts/sync-agent-instructions.sh`. НЕ РЕДАКТИРОВАТЬ ВРУЧНУЮ.**
> Общее ядро → `CLAUDE.md` (SYNC-CORE). Агент-специфика → `AGENTS-agent-blocks.md`.

HEADER
  extract_core
  echo
  extract_agent_blocks "$AGENTS_BLOCKS" 'AGENT-SPECIFIC-START' 'AGENT-SPECIFIC-END'
}

build_cursorrules() {
  if [ ! -f "$CURSOR_BLOCKS" ]; then
    echo "[WARN] $CURSOR_BLOCKS не найден" >&2
    return 1
  fi
  cat <<HEADER
# IWE — инструкции для Cursor Agent

> **Сгенерировано \`scripts/sync-agent-instructions.sh\`. НЕ РЕДАКТИРОВАТЬ ВРУЧНУЮ.**
> Общее ядро → \`CLAUDE.md\` (SYNC-CORE). Cursor-специфика → \`CURSOR-agent-blocks.md\`.
> Детали L1: \`memory/protocol-*.md\`, \`.claude/rules/\`, \`.cursor/hooks.json\`.

HEADER
  extract_core
  echo
  extract_agent_blocks "$CURSOR_BLOCKS" 'CURSOR-SPECIFIC-START' 'CURSOR-SPECIFIC-END'
  echo
  echo "*Синхронизировано: $(date +%Y-%m-%d)*"
}

build_mdc() {
  cat <<'FM'
---
description: IWE SYNC-CORE — единое ядро агентов (автогенерация)
alwaysApply: true
---

FM
  extract_core
}

write_or_check() {
  local label="$1" out="$2" content="$3"
  case "$MODE" in
    check)
      if [ ! -f "$out" ]; then
        echo "[DRIFT] $label: $out не существует" >&2
        return 1
      fi
      if ! diff -q <(printf '%s\n' "$content") "$out" >/dev/null 2>&1; then
        echo "[DRIFT] $label: $out расходится с ядром" >&2
        return 1
      fi
      echo "OK: $label"
      ;;
    dry-run)
      echo "=== $label → $out ==="
      if [ -f "$out" ]; then
        if diff -q <(printf '%s\n' "$content") "$out" >/dev/null 2>&1; then
          echo "  актуален"
        else
          diff -u "$out" <(printf '%s\n' "$content") | head -40 || true
          echo "  --- для записи: --force ---"
        fi
      else
        echo "  будет создан (--force)"
        printf '%s\n' "$content" | head -15
      fi
      ;;
    force)
      if [ -f "$out" ]; then cp "$out" "$out.bak"; fi
      printf '%s\n' "$content" > "$out"
      echo "Записано: $out ($(wc -l < "$out" | tr -d ' ') строк)"
      ;;
  esac
}

ERR=0

if [ "$TARGET" = "all" ] || [ "$TARGET" = "agents" ]; then
  if AGENTS_CONTENT="$(build_agents 2>/dev/null)"; then
    write_or_check "AGENTS.md" "$OUT_AGENTS" "$AGENTS_CONTENT" || ERR=1
  fi
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "cursor" ]; then
  if CURSOR_CONTENT="$(build_cursorrules)"; then
    write_or_check ".cursorrules" "$OUT_CURSORRULES" "$CURSOR_CONTENT" || ERR=1
  else
    ERR=1
  fi
  MDC_CONTENT="$(build_mdc)"
  write_or_check "iwe-sync-core.mdc" "$OUT_MDC" "$MDC_CONTENT" || ERR=1
fi

exit "$ERR"
