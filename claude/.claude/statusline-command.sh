#!/bin/sh
# Claude Code status line
#
# [context bar] | 📊 5h: X%  7d: X% | 🤖 model

input=$(cat)

# ── Colors ──────────────────────────────────────────────────────────────────
bold='\033[1m'
cyan='\033[96m'
magenta='\033[95m'
green='\033[92m'
grey='\033[90m'
red='\033[91m'
yellow='\033[93m'
white='\033[97m'
blue='\033[94m'
reset='\033[0m'

# ── Context progress bar ───────────────────────────────────────────────────
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.tokens_total // 0')
bar_seg=""
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}

  # Offset so 83% (auto-compact threshold) shows as 100% for non-1M windows
  if [ "$ctx_size" -lt 900000 ] 2>/dev/null; then
    used_int=$(( used_int * 100 / 83 ))
    if [ "$used_int" -gt 100 ]; then used_int=100; fi
  fi

  if [ "$used_int" -ge 80 ] 2>/dev/null; then
    bar_color="$red"
    bar_emoji="🔥"
  elif [ "$used_int" -ge 55 ] 2>/dev/null; then
    bar_color="$yellow"
    bar_emoji="⚡"
  else
    bar_color="$green"
    bar_emoji="✨"
  fi

  filled=$(( used_int * 20 / 100 ))
  empty=$(( 20 - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ];  do bar="${bar}░"; i=$(( i + 1 )); done

  bar_seg=$(printf "${bar_emoji} ${bar_color}${bar}${reset} ${white}${used_int}%%${reset}")
fi

# ── API usage (5h + 7d) ────────────────────────────────────────────────────
usage_seg=""
stats_file="$HOME/.claude/stats-usage.json"
CACHE_MAX_AGE=150

needs_refresh=true
if [ -f "$stats_file" ]; then
  cache_age=$(( $(date +%s) - $(stat -f %m "$stats_file") ))
  if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
    needs_refresh=false
  fi
fi

if $needs_refresh; then
  creds=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null)
  token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  if [ -n "$token" ]; then
    usage_json=$(curl -s --max-time 5 https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)
    if echo "$usage_json" | jq -e '.five_hour' >/dev/null 2>&1; then
      echo "$usage_json" > "$stats_file"
    fi
  fi
fi

if [ -f "$stats_file" ]; then
  pct_5h=$(jq -r '.five_hour.utilization | floor' "$stats_file" 2>/dev/null)
  pct_7d=$(jq -r '.seven_day.utilization | floor' "$stats_file" 2>/dev/null)
  if [ -n "$pct_5h" ] && [ -n "$pct_7d" ]; then
    usage_seg=$(printf "📊 ${yellow}5h:${reset} ${white}${pct_5h}%%${reset}  ${yellow}7d:${reset} ${white}${pct_7d}%%${reset}")
  fi
fi

model_seg=""
model=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model" ]; then
  model_seg=$(printf "🤖 ${cyan}${model}${reset}")
fi

# ── Line 2: context bar | usage | model ───────────────────────────────────
line2=""
if [ -n "$bar_seg" ]; then
  line2="${bar_seg}"
fi
if [ -n "$usage_seg" ]; then
  if [ -n "$line2" ]; then
    line2="${line2} ${grey}|${reset} ${usage_seg}"
  else
    line2="${usage_seg}"
  fi
fi
if [ -n "$model_seg" ]; then
  if [ -n "$line2" ]; then
    line2="${line2} ${grey}|${reset} ${model_seg}"
  else
    line2="${model_seg}"
  fi
fi

# ── Output ─────────────────────────────────────────────────────────────────
if [ -n "$line2" ]; then
  printf '%b\n' "${line2}"
fi
