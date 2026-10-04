#!/bin/bash

# Configuration
FOLDER_ID="nogah-ctqny"

# Function to display usage
usage() {
    echo "Usage: $0 {pause|resume}"
    echo "  pause  - Pause Syncthing folder synchronization"
    echo "  resume - Resume Syncthing folder synchronization"
    exit 1
}

# Check if argument is provided
if [ $# -eq 0 ]; then
    usage
fi

# Main logic
case "$1" in
    pause)
        syncthing cli config folders "$FOLDER_ID" paused set true
        echo "$(date): Syncthing folder '$FOLDER_ID' paused"
        ;;
    resume)
        syncthing cli config folders "$FOLDER_ID" paused set false
        echo "$(date): Syncthing folder '$FOLDER_ID' resumed"
        ;;
    *)
        echo "Error: Invalid argument '$1'"
        usage
        ;;
esac
