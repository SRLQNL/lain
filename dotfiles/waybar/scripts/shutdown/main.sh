#!/bin/sh
# main.sh — анимация при выключении, затем shutdown
if [ -f "$HOME/Videos/ending.mp4" ]; then
    mpv --start=0 --no-input-default-bindings --cursor-autohide=always \
        --osc=no --fullscreen --on-all-workspaces "$HOME/Videos/ending.mp4" &
    sleep 7.5
fi
shutdown now
