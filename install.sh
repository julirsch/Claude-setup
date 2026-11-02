#!/usr/bin/env bash
# Installs the lean user-level Claude Code setup into ~/.claude (or $CLAUDE_HOME).
#   ./install.sh            install
#   ./install.sh --dry-run  show what would change, touch nothing
# Safe to re-run: backs up what it changes, merges settings (your existing values win,
# lists are combined without duplicates), and never overwrites an existing CLAUDE.md.
set -euo pipefail

DRY=0; [[ ${1:-} == --dry-run ]] && DRY=1
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/user"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$DEST/backups/lean-setup-$STAMP"

command -v jq >/dev/null || { echo "jq is required (brew install jq / apt install jq)"; exit 1; }

run() { if (( DRY )); then echo "[dry-run] $*"; else "$@"; fi; }
backup() { [[ -e $1 ]] && { run mkdir -p "$BACKUP"; run cp -p "$1" "$BACKUP/"; echo "backed up $1 -> $BACKUP/"; } || true; }

run mkdir -p "$DEST/hooks"

# 1. Scripts (overwrite our own files only; back up if they differ).
for f in statusline.sh hooks/notify.sh; do
  if [[ -e $DEST/$f ]] && ! cmp -s "$SRC/$f" "$DEST/$f"; then backup "$DEST/$f"; fi
  run install -m 755 "$SRC/$f" "$DEST/$f"; echo "installed $DEST/$f"
done

# 2. CLAUDE.md: never overwrite.
if [[ -e $DEST/CLAUDE.md ]]; then
  run cp "$SRC/CLAUDE.md" "$DEST/CLAUDE.md.suggested"
  echo "kept your $DEST/CLAUDE.md; suggestion written to CLAUDE.md.suggested (merge by hand, keep it short)"
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

echo
echo "Done. Next: open Claude Code, run /context and /usage to see your baseline,"
echo "and read PLAYBOOK.md. Restart Claude Code to pick up the new statusline."
