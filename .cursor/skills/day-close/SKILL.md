---
name: day-close
description: Day Close — вечерний итог дня. Триггеры: закрывай день, day close, итоги дня.
---

# Day Close (Cursor)

**НЕ выполнять вручную по protocol-close.md.** Используй диспетчер:

1. Прочитай `.cursor/skills/run-protocol/SKILL.md`
2. Выполни протокол с аргументом **`day-close`**

Полный алгоритм: `.claude/skills/day-close/SKILL.md` (подключается через run-protocol).

Пошагово через TodoWrite. Верификация — subagent (fast-модель), если сессия >15 мин или были изменения файлов.
