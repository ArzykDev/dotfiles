#!/bin/bash
# secondary-toggle.sh — toggle the secondary monitor on/off

MON_SECONDARY="HDMI-A-1"

if kscreen-doctor --outputs 2>/dev/null | grep -A1 " $MON_SECONDARY " | grep -q "enabled"; then
    kscreen-doctor output.$MON_SECONDARY.disable
    notify-send "Display Mode" "Secondary monitor off" -i video-display
else
    kscreen-doctor output.$MON_SECONDARY.enable
    notify-send "Display Mode" "Secondary monitor on" -i video-display
fi
