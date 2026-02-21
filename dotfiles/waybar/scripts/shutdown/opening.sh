#!/bin/sh
# opening.sh — анимация при старте (опционально)
# Положи своё видео в ~/Videos/opening.mp4 чтобы это работало
if [ -f "$HOME/Videos/opening.mp4" ]; then
    sleep 5
    mpv --no-input-default-bindings --cursor-autohide=always --osc=no \
        --fullscreen --on-all-workspaces "$HOME/Videos/opening.mp4"
fi
