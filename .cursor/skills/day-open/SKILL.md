---
name: day-open
description: Day Open protocol — утреннее планирование. Триггеры: открывай день, day open, /day-open.
---

# Day Open (Cursor)

Прочитай и выполни **пошагово** (TodoWrite обязателен):

1. `.claude/skills/day-open/SKILL.md` — основной алгоритм
2. `.claude/skills/day-open/day-open-details.md` — детали шагов
3. `.claude/skills/day-open/templates.md` — перед шагами 7a и 7d

**Роль:** R1 Стратег. **Первое действие:** `date` для реальной даты.

**Extensions (если есть):**
- `extensions/day-open.before.md` — до шага 1
- `extensions/day-open.after.md` — после шага 6b
- `extensions/day-open.checks.md` — перед commit

Не пропускать шаги. Шаг невозможен → `blocked`, не молча.
