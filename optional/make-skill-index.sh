#!/usr/bin/env bash
# Turn a big skill bundle into ONE index skill, so only its one-line description is in
# context every turn (~50 tokens) instead of every bundled skill's description.
# Progressive disclosure: index description (always) -> index table (when relevant) -> one guide.
#
# Usage:
#   make-skill-index.sh <owner/repo | local-dir> <skills-subdir> <index-name> "<description>" [--project] [--force]
# Example:
#   make-skill-index.sh arjun988/blender-skills .claude/skills blender \
#     "Index of 94 Blender guides (modeling, materials, rigging, VFX, export, art styles, Blender MCP). Use for any Blender or 3D asset task." --project
#
# Installs to ~/.claude/skills/<index-name> (or ./.claude/skills/<index-name> with --project).
# Nothing from the source is executed; review any scripts it lists before using the guides.
set -euo pipefail

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[[ $# -ge 4 ]] || usage
SRC=$1 SUB=$2 NAME=$3 DESC=$4; shift 4
PROJECT=0 FORCE=0
for a in "$@"; do case $a in --project) PROJECT=1;; --force) FORCE=1;; *) usage;; esac; done
[[ $NAME =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "index-name must be lowercase letters, digits, hyphens"; exit 1; }
(( ${#DESC} <= 300 )) || echo "warning: description is ${#DESC} chars; it's loaded every turn, so shorter is better"

if (( PROJECT )); then BASE=./.claude/skills; else BASE="${CLAUDE_HOME:-$HOME/.claude}/skills"; fi
DEST="$BASE/$NAME"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
if [[ -d $SRC ]]; then
  SKILLS="$SRC/$SUB"
else
  echo "fetching $SRC ($SUB) ..."
  git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$SRC" "$TMP/repo"
  git -C "$TMP/repo" sparse-checkout set "$SUB" >/dev/null
  SKILLS="$TMP/repo/$SUB"; REV=$(git -C "$TMP/repo" rev-parse --short HEAD)
fi
[[ -d $SKILLS ]] || { echo "no such directory: $SKILLS"; exit 1; }

# Copy the tree as-is (keeps per-skill and shared reference links valid), then rename
# SKILL.md -> GUIDE.md so Claude Code no longer registers each one as a skill.
mkdir -p "$TMP/out/guides"
cp -R "$SKILLS"/. "$TMP/out/guides/"
rm -rf "$TMP/out/guides/.git"

# Read one frontmatter field (handles single-line, quoted, and folded >/| values).
field() { awk -v k="$2" '
  NR==1 && /^---/ {fm=1; next}  fm && /^---/ {exit}
  fm && grab && /^[ \t]+/ {sub(/^[ \t]+/,""); v=v" "$0; next}
  fm && grab {exit}
  fm && $0 ~ "^"k":" {sub("^"k":[ \t]*",""); if ($0 ~ /^[>|][-+]?$/ || $0=="") {grab=1; v=""} else {v=$0; exit}}
  END {gsub(/^[ \t]+|[ \t]+$/,"",v); if (v ~ /^".*"$/ || v ~ /^\x27.*\x27$/) v=substr(v,2,length(v)-2); print v}' "$1"; }

rows=""; n=0
while IFS= read -r f; do
  dir=$(dirname "$f"); rel=${dir#"$TMP/out/"}
  nm=$(field "$f" name); nm=${nm:-$(basename "$dir")}
  d=$(field "$f" description); d=${d//|/\\|}; (( ${#d} > 200 )) && d="${d:0:197}..."
  mv "$f" "$dir/GUIDE.md"
  rows+="| \`$nm\` | $d | \`$rel/GUIDE.md\` |"$'\n'; n=$((n+1))
done < <(find "$TMP/out/guides" -name SKILL.md | sort)
(( n > 0 )) || { echo "no SKILL.md files found under $SKILLS"; exit 1; }

{
  printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$NAME" "$DESC"
  printf '# %s guide index\n\n' "$NAME"
  printf 'Generated from `%s`%s by make-skill-index.sh. %d guides.\n\n' "$SRC" "${REV:+ @ $REV}" "$n"
  cat <<'EOF'
How to use this index:
1. Pick the 1–3 guides below that best match the task. Don't read them all.
2. Read each chosen guide at the path shown, relative to this skill's directory.
3. Paths inside a guide are relative to that guide's own folder.
4. If a guide mentions another skill by name, look it up in this table and read that guide too.
5. If nothing fits, carry on without a guide.

| Guide | Use when | Path |
|---|---|---|
EOF
  printf '%s' "$rows"
} > "$TMP/out/SKILL.md"

if [[ -e $DEST ]]; then
  (( FORCE )) || { echo "$DEST exists; re-run with --force to replace it (the old copy is moved to skill-backups/, outside skills/)"; exit 1; }
  BK="$(dirname "$BASE")/skill-backups"; mkdir -p "$BK"
  mv "$DEST" "$BK/$NAME-$(date +%Y%m%d-%H%M%S)"; echo "previous copy moved to $BK/"
fi
mkdir -p "$BASE"; mv "$TMP/out" "$DEST"

scripts=$(find "$DEST/guides" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.ts' -o -perm -u+x \) | sed "s|$DEST/||")
echo "installed index skill '$NAME' with $n guides -> $DEST"
echo "always-on cost: description only (${#DESC} chars, ~$(( (${#DESC}+3)/4 )) tokens)"
echo "index body (loaded only when used): $(wc -c < "$DEST/SKILL.md") chars"
[[ -n $scripts ]] && { echo "note: these bundled files contain code; review before letting Claude run them:"; echo "$scripts" | sed 's/^/  /'; }
exit 0
