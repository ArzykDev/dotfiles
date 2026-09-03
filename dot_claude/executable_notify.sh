#!/usr/bin/env bash
# Claude Code sound cue: one distinct sound per Notification event so each is
# recognizable by ear. The desktop banner comes from Claude Code's native
# notifications (preferredNotifChannel=auto); this only adds audio. Wired as a
# single async Notification hook; the event arrives as notification_type on stdin.
# On Linux, canberra resolves the desktop's XDG sound theme; paplay is the
# fallback pinned to the ocean theme.
set -eu

ev=$(jq -r '.notification_type // empty')

case "$(uname)" in
  Darwin)
    case "$ev" in
      permission_prompt)  s=Tink ;;
      idle_prompt)        s=Glass ;;
      agent_completed)    s=Hero ;;
      agent_needs_input)  s=Morse ;;
      *) exit 0 ;;
    esac
    afplay "/System/Library/Sounds/$s.aiff"
    ;;
  *)
    case "$ev" in
      permission_prompt)  s=message-new-instant ;;
      idle_prompt)        s=completion-success ;;
      agent_completed)    s=dialog-information ;;
      agent_needs_input)  s=message-attention ;;
      *) exit 0 ;;
    esac
    canberra-gtk-play -i "$s" 2>/dev/null \
      || paplay "/usr/share/sounds/ocean/stereo/$s.oga"
    ;;
esac
