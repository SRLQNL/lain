#!/bin/bash
# check_updates.sh — проверка обновлений через xbps (Void Linux)
updates=$(xbps-install -Mun 2>/dev/null | wc -l)
if [ "$updates" -gt 0 ]; then
    echo "$updates"
else
    echo "0"
fi
