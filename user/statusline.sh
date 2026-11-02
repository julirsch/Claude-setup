#!/usr/bin/env bash
# Claude Code statusline: model · effort · context % · 5-hour limit % · session cost · dir (branch)
# Reads the session JSON on stdin. Requires jq. Costs zero context tokens.
input=$(cat)
j() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

model=$(j '.model.display_name')
effort=$(j '.effort.level')
ctx=$(j '.context_window.used_percentage')
five=$(j '.rate_limits.five_hour.used_percentage')
cost=$(j '.cost.total_cost_usd')
dir=$(j '.workspace.current_dir'); dir=${dir:-$(j '.cwd')}

# Colour the context % so bloat is visible at a glance: green <50, yellow <80, red otherwise.
colour() { local p=${1%.*}; if (( p < 50 )); then printf '\033[32m'; elif (( p < 80 )); then printf '\033[33m'; else printf '\033[31m'; fi; }
reset=$'\033[0m'

parts=()
[[ -n $model ]] && parts+=("${model}${effort:+ ($effort)}")
[[ -n $ctx ]] && parts+=("$(colour "$ctx")ctx ${ctx%.*}%${reset}")
[[ -n $five ]] && parts+=("$(colour "$five")5h ${five%.*}%${reset}")
[[ -n $cost ]] && parts+=("$(printf '$%.2f' "$cost")")
if [[ -n $dir ]]; then
  branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)
  parts+=("${dir##*/}${branch:+ ($branch)}")
fi

out=""; for p in "${parts[@]}"; do out+="${out:+ · }$p"; done
printf '%s\n' "$out"
