<!-- CURSOR-SPECIFIC-START -->
<!--
  Агент-специфичные блоки для Cursor (WP-394 Ф4.2).
  Врезается scripts/sync-agent-instructions.sh после SYNC-CORE.
-->

## Cursor Agent — скиллы и хуки

- **Скиллы:** `.cursor/skills/` — индекс `.cursor/skills/SKILL-INDEX.md`
- **P0:** day-open, day-close, run-protocol, archgate, wp-new
- **P1+:** week-close, month-close, verify, strategy-session, integration-gate, apply-captures, fpf, think, decompose, bottleneck-pick, iwe-bug-report, author-mode
- **Полные алгоритмы:** `.claude/skills/<name>/SKILL.md` (source-of-truth)
- **Хуки P0:** sessionStart, beforeSubmitPrompt, pull-on-touch, destructive-guard, inject-context
- **Хуки P1:** memory-exocortex-sync, capture-bus, protocol-stop-gate (см. `.cursor/hooks.json`)

## MCP Aisystant

При подключённом `iwe-knowledge` (`https://mcp.aisystant.com/mcp`):

```
get_instructions(level="experienced")
```

Координация с другими агентами (если доступно):
- `update_peer_status` — working/idle
- `acquire_file_lock` / `release_file_lock` — перед правкой shared-файлов

## Subagents

- Верификация Day/Quick Close → subagent (fast-модель)
- LegacyPortGate → 15-мин subagent «как сейчас?»

## Коммиты Cursor

Co-Authored-By только при реальном участии агента. Не коммитить без запроса пилота, кроме триггера Push.

## Response Style

Правила A1-A11: `memory/feedback_response_clarity_for_pilot.md`. Технический канал — commit/PR; «на пальцах» — обычный чат.

<!-- CURSOR-SPECIFIC-END -->
