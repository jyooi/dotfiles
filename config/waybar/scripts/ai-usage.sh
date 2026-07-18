#!/bin/bash
# Waybar module: Claude Code + Codex usage limits.
# Claude: queried live from Anthropic's OAuth usage endpoint.
# Codex: parsed from the newest rate-limit snapshot in ~/.codex/sessions.
set -u

CLAUDE_CRED="$HOME/.claude/.credentials.json"
CODEX_SESSIONS="$HOME/.codex/sessions"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-ai-usage.json"

claude_5h="" claude_7d="" claude_5h_reset="" claude_7d_reset=""
codex_pct="" codex_reset="" codex_window="" codex_age_note=""

if [[ -r "$CLAUDE_CRED" ]]; then
  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CLAUDE_CRED")
  if [[ -n "$token" ]]; then
    usage=$(curl -sf --max-time 8 https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20") || usage=""
    if [[ -n "$usage" ]]; then
      printf '%s' "$usage" > "$CACHE"
    elif [[ -r "$CACHE" ]]; then
      # Endpoint rate-limits bursts (429); fall back to the last good result.
      usage=$(cat "$CACHE")
    fi
    if [[ -n "$usage" ]]; then
      claude_5h=$(jq -r '.five_hour.utilization // empty | floor' <<<"$usage")
      claude_7d=$(jq -r '.seven_day.utilization // empty | floor' <<<"$usage")
      claude_5h_reset=$(jq -r '.five_hour.resets_at // empty' <<<"$usage")
      claude_7d_reset=$(jq -r '.seven_day.resets_at // empty' <<<"$usage")
    fi
  fi
fi

if [[ -d "$CODEX_SESSIONS" ]]; then
  # Only the newest few session files; older ones cannot hold a fresher snapshot.
  while IFS= read -r f; do
    line=$(grep -h '"rate_limits"' "$f" 2>/dev/null | tail -1)
    [[ -z "$line" ]] && continue
    rl=$(jq -c '.. | objects | select(has("primary")) | select(has("plan_type"))' <<<"$line" 2>/dev/null | tail -1)
    [[ -z "$rl" ]] && continue
    codex_pct=$(jq -r '.primary.used_percent // empty | floor' <<<"$rl")
    codex_window=$(jq -r '.primary.window_minutes // empty' <<<"$rl")
    reset_epoch=$(jq -r '.primary.resets_at // empty' <<<"$rl")
    [[ -n "$reset_epoch" ]] && codex_reset=$(date -d "@$reset_epoch" '+%a %d %b %H:%M' 2>/dev/null)
    age_days=$(( ($(date +%s) - $(stat -c %Y "$f")) / 86400 ))
    (( age_days >= 1 )) && codex_age_note=" (snapshot ${age_days}d old)"
    break
  done < <(ls -t "$CODEX_SESSIONS"/*/*/*/*.jsonl 2>/dev/null | head -5)
fi

fmt_reset() { date -d "$1" '+%a %d %b %H:%M' 2>/dev/null; }

# Bar shows the binding constraint for Claude: the higher of 5h and weekly.
claude_show="?"
if [[ -n "$claude_5h" || -n "$claude_7d" ]]; then
  claude_show=$(( ${claude_5h:-0} > ${claude_7d:-0} ? ${claude_5h:-0} : ${claude_7d:-0} ))
fi
codex_show="${codex_pct:-?}"

text="󰧑 ${claude_show}% 󰚩 ${codex_show}%"

tooltip="AI usage limits"
[[ -n "$claude_5h" ]] && tooltip+=$'\n'"Claude 5h:  ${claude_5h}%  resets $(fmt_reset "$claude_5h_reset")"
[[ -n "$claude_7d" ]] && tooltip+=$'\n'"Claude 7d:  ${claude_7d}%  resets $(fmt_reset "$claude_7d_reset")"
[[ -z "$claude_5h" && -z "$claude_7d" ]] && tooltip+=$'\n'"Claude: unavailable"
if [[ -n "$codex_pct" ]]; then
  window_label="$(( ${codex_window:-0} / 1440 ))d"
  tooltip+=$'\n'"Codex ${window_label}:  ${codex_pct}%  resets ${codex_reset}${codex_age_note}"
else
  tooltip+=$'\n'"Codex: no session data"
fi

worst=0
for p in "${claude_5h:-0}" "${claude_7d:-0}" "${codex_pct:-0}"; do
  (( p > worst )) && worst=$p
done
class="normal"
(( worst >= 70 )) && class="warning"
(( worst >= 90 )) && class="critical"

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
