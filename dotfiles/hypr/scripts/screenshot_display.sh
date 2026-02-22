#!/bin/bash
# screenshot_display.sh — скриншот текущего монитора (Shift+Print)

output_id=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
grim -o "$output_id" - | swappy -f -
