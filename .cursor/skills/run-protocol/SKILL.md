---
name: run-protocol
description: Пошаговое выполнение протоколов ОРЗ. Аргументы: open, close, day-open, day-close, week-close, close session.
---

# Run Protocol (Cursor)

Прочитай и выполни: `.claude/skills/run-protocol/SKILL.md`

**Принцип:** каждый шаг → TodoWrite (pending → in_progress → completed). Пропуск шагов запрещён.

## Маршрутизация аргументов

| Аргумент пользователя | Скилл / файл |
|----------------------|--------------|
| `day-open`, `open day` | `.cursor/skills/day-open/SKILL.md` |
| `day-close`, `close day` | `.cursor/skills/day-close/SKILL.md` |
| `close`, `close session` | `memory/protocol-close.md` § Quick Close |
| `week-close` | `.claude/skills/week-close/SKILL.md` |
| `open session` | `memory/protocol-open.md` § Сессия |

**Extensions:** перед шагами проверь `extensions/{protocol}.before.md`, `.after.md`, `.checks.md`.
