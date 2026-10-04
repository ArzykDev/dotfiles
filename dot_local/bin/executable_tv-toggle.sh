#!/bin/bash
# tv-toggle.sh — switch between desktop mode and TV-only mode

TV="HDMI-A-2"
MON_PRIMARY="DP-1"
MON_SECONDARY="HDMI-A-1"

SINK_DESKTOP="analog-stereo"
SINK_TV="hdmi-stereo"

switch_audio() {
    local pattern="$1"
    local sink
    sink=$(pactl list short sinks | grep "$pattern" | head -1 | awk '{print $2}')
    if [ -z "$sink" ]; then
        notify-send "Display Mode" "Audio sink not found: $pattern" -i dialog-warning
        return 1
    fi
    pactl set-default-sink "$sink"
    pactl list short sink-inputs | awk '{print $1}' | while read input; do
        pactl move-sink-input "$input" "$sink"
    done
}

# Check if primary monitor is currently enabled
MON1_STATUS=$(kscreen-doctor --outputs 2>/dev/null | grep -A3 "DP-1" | grep -c "enabled")

if [ "$MON1_STATUS" -eq 0 ]; then
    # TV mode → back to desktop
    kscreen-doctor \
        output.$MON_PRIMARY.enable \
        output.$MON_PRIMARY.priority.1 \
        output.$MON_SECONDARY.enable \
        output.$MON_SECONDARY.priority.2 \
        output.$TV.disable
    sleep 2
    switch_audio "$SINK_DESKTOP"
    notify-send "Display Mode" "Switched to Desktop" -i video-display
else
    # Desktop → TV mode
    kscreen-doctor \
        output.$MON_PRIMARY.disable \
        output.$MON_SECONDARY.disable \
        output.$TV.enable \
        output.$TV.priority.1
    sleep 2
    switch_audio "$SINK_TV"
    notify-send "Display Mode" "Switched to TV" -i video-television
fi
