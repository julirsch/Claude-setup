#!/usr/bin/env bash
# PreToolUse guard: new skills go through skill-index, so each one costs ~nothing until used.
# Blocks (exit 2, reason sent to Claude) creating a new standalone skill in a .claude/skills folder.
# Editing existing skills and guides is allowed. Silent otherwise (no context cost).
in=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$in" 2>/dev/null)

MSG='Blocked: skills are kept behind index skills here so they cost almost nothing until used. Do not create skills directly in .claude/skills. Instead, draft the skill folder (with its SKILL.md) in a temporary directory, then run:
  ~/.claude/bin/skill-index add <that-dir | owner/repo> [path/in/repo] --tag "<a few words on when to use it>"
Options: --project for this repo only, --group <name> to keep related skills together, or "skill-index bundle" for a whole collection. To change an existing guide, edit its GUIDE.md, then run ~/.claude/bin/skill-index rebuild. Run ~/.claude/bin/skill-index --help for more.'

block() { printf '%s\n' "$MSG" >&2; exit 2; }

case $tool in
  Write|Edit|MultiEdit|NotebookEdit)
    p=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$in")
    [[ $p == */.claude/skills/* ]] || exit 0
    skills=${p%%/.claude/skills/*}/.claude/skills
    rel=${p#*/.claude/skills/}; top=${rel%%/*}
    # A SKILL.md inside an index's guides/ would be inconsistent: guides are named GUIDE.md.
    [[ $rel == */guides/* && ${p##*/} == SKILL.md ]] && block
    # Allow anything inside an existing skill or index (editing is fine); block creating a new one.
    [[ $rel != */* && ! -d $skills/$rel ]] && block           # a loose file directly in skills/
    [[ -f $skills/$top/SKILL.md ]] && exit 0
    block;;
  Bash)
    c=$(jq -r '.tool_input.command // empty' <<<"$in")
    [[ $c == *.claude/skills* ]] || exit 0
    [[ $c == *skill-index* ]] && exit 0
    # Only block commands that write into a skills folder; reading (ls, cat, grep) is fine.
    if grep -qE '(^|[;&|(`[:space:]])(cp|mv|rsync|ln|install|tee|mkdir|touch|unzip|tar|curl|wget|git[[:space:]]+clone)[[:space:]]' <<<"$c" \
       || grep -qE '>>?[[:space:]]*[^[:space:]]*\.claude/skills' <<<"$c"; then
      block
    fi
    exit 0;;
esac
exit 0
