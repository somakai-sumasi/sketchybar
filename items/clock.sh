#!/bin/sh

sketchybar --add item clock right \
    --set clock update_freq=10 icon=  script="$PLUGIN_DIR/clock.sh" \
    --set clock click_script="open https://calendar.google.com/calendar/u/0/r?pli=1"