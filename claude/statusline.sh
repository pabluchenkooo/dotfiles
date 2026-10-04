#!/usr/bin/env bash
# Claude Code status line — hacky: ◆◇ diamond gauges + Nerd Font icons.
# (JetBrainsMono Nerd Font via ghostty renders the glyphs.)
# Usage-focused: model · context · 5h + 7d rate limits · cost · diff · time · style.

input=$(cat)

# ---- pull every field (one value per line → one `read`, preserves blanks) --
{
  read -r model
  read -r ctx
  read -r r5
  read -r r7
  read -r cost
  read -r added
  read -r removed
  read -r dur_ms
  read -r style
} < <(echo "$input" | jq -r '[
  .model.display_name // "",
  .context_window.used_percentage // "",
  .rate_limits.five_hour.used_percentage // "",
  .rate_limits.seven_day.used_percentage // "",
  .cost.total_cost_usd // "",
  .cost.total_lines_added // 0,
  .cost.total_lines_removed // 0,
  .cost.total_duration_ms // "",
  .output_style.name // ""
] | map(tostring) | .[]')

# ---- palette --------------------------------------------------------------
C_SEP=238; C_LABEL=252; C_MODEL=45; C_COST=220; C_TIME=244; C_STYLE=141
C_ADD=76;  C_DEL=203

# ---- Nerd Font icons via exact UTF-8 bytes (bash 3.2 printf has no \u) ------
I_MODEL=$(printf '\357\203\247')   # U+F0E7  bolt
I_COST=$(printf  '\357\205\225')   # U+F155  dollar
I_TIME=$(printf  '\357\200\227')   # U+F017  clock
I_STYLE=$(printf '\357\207\274')   # U+F1FC  brush
# gauge color by fill: <60 green, 60–84 amber, ≥85 red
color_for() { local p=$1; if (( p >= 85 )); then echo 160; elif (( p >= 60 )); then echo 178; else echo 76; fi; }

# 10-cell ◆◇ diamond gauge + %, colored by level
gauge() {
  local p=$1 w=10 f i b="" c; c=$(color_for "$p")
  f=$(( (p*w + 50) / 100 )); (( f>w )) && f=w; (( f<0 )) && f=0
  for ((i=0; i<f;   i++)); do b+="◆"; done
  for ((i=0; i<w-f; i++)); do b+="◇"; done
  printf '\033[38;5;%sm%s\033[0m \033[38;5;%sm%s%%\033[0m' "$c" "$b" "$c" "$p"
}

# ---- assemble segments ----------------------------------------------------
segs=()
[[ -n $model ]] && segs+=("$(printf '\033[38;5;%sm%s \033[1m%s\033[0m' "$C_MODEL" "$I_MODEL" "$model")")

usage() { local p=${2%%.*}; [[ -z $p ]] && return
  segs+=("$(printf '\033[1;38;5;%sm%s\033[0m %s' "$C_LABEL" "$1" "$(gauge "$p")")"); }
usage "ctx" "$ctx"
usage "5h"  "$r5"
usage "7d"  "$r7"

[[ -n $cost ]] && segs+=("$(printf '\033[38;5;%sm%s %.2f\033[0m' "$C_COST" "$I_COST" "$cost")")

if [[ $added != 0 || $removed != 0 ]]; then
  segs+=("$(printf '\033[38;5;%sm+%s\033[0m \033[38;5;%sm-%s\033[0m' "$C_ADD" "$added" "$C_DEL" "$removed")")
fi

if [[ -n $dur_ms && $dur_ms != null ]]; then
  s=$(( ${dur_ms%.*} / 1000 )); h=$((s/3600)); m=$(((s%3600)/60)); sec=$((s%60))
  if   (( h > 0 )); then dur="${h}h${m}m"; elif (( m > 0 )); then dur="${m}m${sec}s"; else dur="${sec}s"; fi
  segs+=("$(printf '\033[38;5;%sm%s %s\033[0m' "$C_TIME" "$I_TIME" "$dur")")
fi

if [[ -n $style && $style != default && $style != null ]]; then
  segs+=("$(printf '\033[38;5;%sm%s %s\033[0m' "$C_STYLE" "$I_STYLE" "$style")")
fi

# ---- join with a dim separator --------------------------------------------
sep=$(printf '\033[38;5;%sm  \033[0m' "$C_SEP")   #  = thin divider
line=""
for i in "${!segs[@]}"; do
  (( i > 0 )) && line+="$sep"
  line+="${segs[$i]}"
done
printf '%b' "$line"
