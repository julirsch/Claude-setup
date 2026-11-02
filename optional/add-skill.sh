#!/usr/bin/env bash
# Cherry-pick ONE skill from a GitHub repo (or local dir) instead of installing a whole bundle.
#
# Usage:
#   add-skill.sh <owner/repo | local-dir> <path/to/skill-dir> [--project] [--force]
# Examples:
#   add-skill.sh obra/superpowers skills/systematic-debugging
#   add-skill.sh anthropics/skills skills/pdf --project
#
# Installs to ~/.claude/skills/<name> (or ./.claude/skills/<name> with --project).
# Nothing from the source is executed; files containing code are listed for review.
set -euo pipefail

usage() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[[ $# -ge 2 ]] || usage
SRC=$1 SUB=${2%/}; shift 2
PROJECT=0 FORCE=0
for a in "$@"; do case $a in --project) PROJECT=1;; --force) FORCE=1;; *) usage;; esac; done

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
if [[ -d $SRC ]]; then
  DIR="$SRC/$SUB"
else
  echo "fetching $SRC ($SUB) ..."
  git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$SRC" "$TMP/repo"
  git -C "$TMP/repo" sparse-checkout set "$SUB" >/dev/null
  DIR="$TMP/repo/$SUB"
fi
[[ -f $DIR/SKILL.md ]] || { echo "no SKILL.md in $DIR"; exit 1; }

NAME=$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f&&/^name:/{sub(/^name:[ \t]*/,""); gsub(/["\x27]/,""); print; exit}' "$DIR/SKILL.md")
NAME=${NAME:-$(basename "$DIR")}
if (( PROJECT )); then BASE=./.claude/skills; else BASE="${CLAUDE_HOME:-$HOME/.claude}/skills"; fi
DEST="$BASE/$NAME"
if [[ -e $DEST ]]; then
  (( FORCE )) || { echo "$DEST exists; re-run with --force to replace it (the old copy is moved to skill-backups/, outside skills/)"; exit 1; }
  BK="$(dirname "$BASE")/skill-backups"; mkdir -p "$BK"
  mv "$DEST" "$BK/$NAME-$(date +%Y%m%d-%H%M%S)"; echo "previous copy moved to $BK/"
fi
mkdir -p "$BASE"; cp -R "$DIR" "$DEST"; rm -rf "$DEST/.git"

desc=$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f&&/^description:/{sub(/^description:[ \t]*/,""); print; exit}' "$DEST/SKILL.md")
echo "installed skill '$NAME' -> $DEST"
echo "always-on cost: its description (~$(( (${#desc}+3)/4 )) tokens). Run /skill-doctor later to see if it earns that."
refs=$(grep -ohE '[a-z0-9-]+:[a-z0-9-]+' "$DEST/SKILL.md" | grep -E '^(superpowers|anthropic[a-z-]*):' | sort -u | tr '\n' ' ' || true)
[[ -n $refs ]] && echo "note: it mentions skills from its original bundle that you may not have: $refs(harmless; Claude skips them)"
scripts=$(find "$DEST" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.ts' -o -perm -u+x \) | sed "s|$DEST/||")
[[ -n $scripts ]] && { echo "note: these files contain code; review before letting Claude run them:"; echo "$scripts" | sed 's/^/  /'; }
exit 0
