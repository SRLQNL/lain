#!/bin/sh
# lock.sh — экран блокировки (стандартный swaylock, без effects)
swaylock \
    --color 000000 \
    --font "JetBrains Mono" \
    --indicator-radius 100 \
    --indicator-thickness 7 \
    --ring-color cba6f7 \
    --ring-ver-color 89b4fa \
    --ring-wrong-color f38ba8 \
    --ring-clear-color a6e3a1 \
    --key-hl-color 1e1e2e \
    --bs-hl-color eba0ac \
    --text-color 11111b \
    --line-color 00000000 \
    --line-ver-color 00000000 \
    --line-wrong-color 00000000 \
    --line-clear-color 00000000 \
    --separator-color 00000000 \
    --inside-color cba6f7cc \
    --inside-ver-color 89b4facc \
    --inside-wrong-color f38ba8cc \
    --inside-clear-color a6e3a1cc \
    --grace 2
