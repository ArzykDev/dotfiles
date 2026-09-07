#!/usr/bin/env bash
# Keep 5-hour-window headroom for claude.ai. Hooks never get rate_limits on
# stdin, so statusline.sh caches them next to the profile (CLAUDE_CONFIG_DIR)
# and this reads the cache.
#   >= WARN   PreToolUse injects a wrap-up note: subagents finish their step and
#             return, the main agent lands the work, schedules its own resume
#             at the reset time (CronCreate) and stops. Re-sent every +3%.
#   >= LIMIT  PreToolUse denies every tool except CronCreate, so the only move
#             left is to schedule the resume and stop. UserPromptSubmit refuses
#             new prompts, except subagent task-notifications (their result must
#             reach the parent); the cron-fired one passes because the window
#             has reset by then. Override: touch ${cache%/*}/usage-guard.off
set -eu
WARN=80
LIMIT=90
cache="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rate_limits.json"
marks="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/claude-usage-guard"

[ -e "${cache%/*}/usage-guard.off" ] && exit 0
[ -r "$cache" ] || exit 0
# Unit separator, not tab: bash collapses runs of tab and would swallow an empty agent_id.
# Task notifications may arrive with a notice prepended, hence contains, not startswith.
IFS=$'\x1f' read -r event session agent tool notif < <(jq -r '[.hook_event_name, .session_id, .agent_id // "", .tool_name // "", (.prompt // "" | contains("<task-notification>"))] | join("\u001f")' 2>/dev/null) || exit 0
IFS=$'\t' read -r pct reset < <(jq -r '[(.five_hour.used_percentage // 0 | round), (.five_hour.resets_at // 0 | floor)] | @tsv' "$cache" 2>/dev/null) || exit 0
# A stale cache from a past window has resets_at in the past: nothing to guard.
{ [ "$pct" -ge "$WARN" ] && [ "$reset" -gt "$(date +%s)" ]; } || exit 0

# One-shot cron jobs on :00/:30 may fire up to 90s early, i.e. before the reset; skip those minutes.
IFS=$'\t' read -r at cron < <(jq -rn --argjson r "$reset" '($r + 60) | if (strflocaltime("%M") | tonumber) % 30 == 0 then . + 60 else . end | [strflocaltime("%H:%M"), (strflocaltime("%M %H %d %m") | split(" ") | map(tonumber) | join(" ")) + " *"] | @tsv')
status="Usage guard: 5h window at ${pct}% (hard stop at ${LIMIT}%, resets at $at)."
if [ -n "$agent" ]; then
  wrap="$status Finish the current step and return your result to the parent now; do not start new work."
else
  wrap="$status Bring the work to a clean stopping point: land or note the current edit, start no new subagents or tasks. Then schedule the resume with CronCreate (cron \"$cron\", recurring false) using a handoff prompt that says where to pick up, tell the user what is unfinished, and stop."
fi

case $event in
  UserPromptSubmit)
    if [ "$pct" -ge "$LIMIT" ] && [ "$notif" != true ]; then
      jq -n --arg r "$status Resume after the reset, or touch ${cache%/*}/usage-guard.off to override." '{decision:"block",reason:$r}'
    elif [ "$pct" -ge "$LIMIT" ]; then
      echo "$status Hard stop: record this result for the user, schedule the resume with CronCreate (cron \"$cron\", recurring false) if not done yet, and stop."
    else
      echo "$status Keep this turn short."
    fi ;;
  PreToolUse)
    if [ "$pct" -ge "$LIMIT" ]; then
      case $tool in CronCreate|CronList|CronDelete) exit 0 ;; esac
      [ -n "$agent" ] || wrap="$status Hard stop: every tool but CronCreate is denied now. Schedule the resume with CronCreate (cron \"$cron\", recurring false) using a handoff prompt that says where to pick up, tell the user what is unfinished, and stop."
      jq -n --arg r "$wrap" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    else
      # Keyed by window so a long-lived session warns again after each reset.
      key="$reset-$session${agent:+-$agent}"
      mark="$marks/${key//[^A-Za-z0-9_-]/_}"
      mkdir -p "$marks"
      last=$(cat "$mark" 2>/dev/null || echo 0)
      case $last in ''|*[!0-9]*) last=0 ;; esac
      [ $((pct - last)) -ge 3 ] || exit 0
      echo "$pct" > "$mark"
      jq -n --arg c "$wrap" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
    fi ;;
esac
