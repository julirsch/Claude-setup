#!/usr/bin/env bash
# Notification hook: desktop alert when Claude needs input, which helps when running parallel sessions.
# Prints nothing to stdout, so it adds no context tokens. Silently does nothing if no notifier exists.
input=$(cat)
msg=$(jq -r '.message // "Claude Code needs your input"' <<<"$input" 2>/dev/null)
msg=${msg:-Claude Code needs your input}
dir=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
title="Claude Code${dir:+ — ${dir##*/}}"

if command -v osascript >/dev/null 2>&1; then
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv)' -e 'end run' "$msg" "$title" >/dev/null 2>&1
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$title" "$msg" >/dev/null 2>&1
else
  { printf '\a' >/dev/tty; } 2>/dev/null   # terminal bell fallback
fi
exit 0
