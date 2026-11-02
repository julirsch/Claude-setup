#!/usr/bin/env bash
# Installs the lean user-level Claude Code setup into ~/.claude (or $CLAUDE_HOME).
#   ./install.sh              install (includes the default skills, fetched from GitHub)
#   ./install.sh --dry-run    show what would change, touch nothing
#   ./install.sh --no-skills  skip fetching the default skills
# Safe to re-run: backs up what it changes, merges settings (your existing values win,
# lists are combined without duplicates), and never replaces an existing CLAUDE.md
# (it only appends the short skills rule if that's missing).
set -euo pipefail

DRY=0 SKILLS=1
for a in "$@"; do case $a in --dry-run) DRY=1;; --no-skills) SKILLS=0;; *) sed -n '2,9p' "$0"; exit 1;; esac; done
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/user"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$DEST/backups/lean-setup-$STAMP"

# Default skills, each stored as a guide in the "toolkit" index (~1 line of context in total).
DEFAULT_SKILLS=(
  "obra/superpowers|skills/systematic-debugging|finding the root cause of bugs and test failures before fixing"
  "anthropics/skills|skills/pdf|reading, extracting from, filling or creating PDFs"
  "anthropics/skills|skills/xlsx|reading, editing or creating spreadsheets (.xlsx, .csv)"
  "anthropics/skills|skills/skill-creator|writing, testing or improving skills"
)

command -v jq >/dev/null || { echo "jq is required (brew install jq / apt install jq)"; exit 1; }

run() { if (( DRY )); then echo "[dry-run] $*"; else "$@"; fi; }
backup() { [[ -e $1 ]] && { run mkdir -p "$BACKUP"; run cp -p "$1" "$BACKUP/"; echo "backed up $1 -> $BACKUP/"; } || true; }

run mkdir -p "$DEST/hooks" "$DEST/bin"

# 1. Scripts (overwrite our own files only; back up if they differ).
for f in statusline.sh hooks/notify.sh hooks/guard-skills.sh bin/skill-index; do
  if [[ -e $DEST/$f ]] && ! cmp -s "$SRC/$f" "$DEST/$f"; then backup "$DEST/$f"; fi
  run install -m 755 "$SRC/$f" "$DEST/$f"; echo "installed $DEST/$f"
done

# 2. CLAUDE.md: never replace. If one exists, append only the skills rule when it's missing.
if [[ -e $DEST/CLAUDE.md ]]; then
  if grep -q 'skill-index' "$DEST/CLAUDE.md"; then
    echo "kept your $DEST/CLAUDE.md (skills rule already present)"
  else
    backup "$DEST/CLAUDE.md"
    block=$(awk '/^## Skills/{f=1} f' "$SRC/CLAUDE.md" | awk 'NR>1 && /^## /{exit} {print}')
    if (( DRY )); then echo "[dry-run] would append to $DEST/CLAUDE.md:"; echo "$block"
    else printf '\n%s\n' "$block" >> "$DEST/CLAUDE.md"; echo "appended the skills rule to your $DEST/CLAUDE.md"; fi
  fi
  run cp "$SRC/CLAUDE.md" "$DEST/CLAUDE.md.suggested"
  echo "full suggested CLAUDE.md written to CLAUDE.md.suggested (merge by hand if you like; keep it short)"
else
  run cp "$SRC/CLAUDE.md" "$DEST/CLAUDE.md"; echo "installed $DEST/CLAUDE.md"
fi

# 3. settings.json: merge.
MERGE='
def dedupe: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
def merge($a; $b):
  if ($a|type) == "object" and ($b|type) == "object" then
    reduce ($b|keys_unsorted[]) as $k ($a;
      .[$k] = (if has($k) then merge($a[$k]; $b[$k]) else $b[$k] end))
  elif ($a|type) == "array" and ($b|type) == "array" then ($a + $b) | dedupe
  else $a end;                                   # existing scalar wins
. as [$old, $new]
| ($new | if $old.statusLine then del(.statusLine) else . end) as $new  # keep your statusline
| merge($old; $new)'
target="$DEST/settings.json"
if [[ -e $target ]]; then
  jq empty "$target" 2>/dev/null || { echo "ERROR: $target is not valid JSON; fix it first"; exit 1; }
  merged=$(jq -s "$MERGE" "$target" "$SRC/settings.json")
  if [[ $merged == "$(jq . "$target")" ]]; then
    echo "settings.json already up to date"
  else
    backup "$target"
    if (( DRY )); then echo "[dry-run] merged settings.json would be:"; echo "$merged"
    else printf '%s\n' "$merged" > "$target"; echo "merged into $target"; fi
  fi
  jq -e '.statusLine' "$target" >/dev/null 2>&1 && ! grep -q statusline.sh "$target" && \
    echo "note: you already had a statusLine, kept yours (ours is at $DEST/statusline.sh)"
else
  run cp "$SRC/settings.json" "$target"; echo "installed $target"
fi

# 4. Default skills, all behind one "toolkit" index skill.
if (( SKILLS )); then
  for entry in "${DEFAULT_SKILLS[@]}"; do
    IFS='|' read -r repo path tag <<<"$entry"; name=${path##*/}
    if [[ -d $DEST/skills/toolkit/guides/$name ]]; then echo "skill '$name' already installed"; continue; fi
    if (( DRY )); then echo "[dry-run] skill-index add $repo $path --tag \"$tag\""; continue; fi
    CLAUDE_HOME="$DEST" "$DEST/bin/skill-index" add "$repo" "$path" --tag "$tag" | grep -E "^(added|index|fetching)" \
      || echo "warning: could not fetch '$name' (offline?). Re-run ./install.sh later to retry."
  done
fi

echo
echo "Done. Next: open Claude Code, run /context and /usage to see your baseline,"
echo "and read PLAYBOOK.md. Restart Claude Code to pick up the new statusline."
