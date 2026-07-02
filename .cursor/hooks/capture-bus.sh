#!/bin/bash
# postToolUse / stop — capture-bus через делегирование в .claude/hooks/capture-bus.sh
exec "$(dirname "$0")/delegate-claude-hook.sh" capture-bus
