#!/bin/bash
# rofi-run-on-current-workspace/main.sh
# Запускает rofi в режиме drun с привязкой к текущему воркспейсу.
# Используется из hyprland.conf: bind = $mainMod, X, exec, bash ~/Scripts/rofi-run-on-current-workspace/main.sh

rofi -show drun
