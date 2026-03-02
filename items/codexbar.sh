#!/bin/bash

# CodexBar - AI provider usage stats
# Alias doesn't work (SwiftUI custom view), so use icon + native click

sketchybar --add item codexbar right \
           --set codexbar \
                 icon=󰚩 \
                 icon.font="Moralerspace Neon HW:Bold:17.0" \
                 label.drawing=off \
                 padding_left=0 \
                 padding_right=0 \
                 click_script="osascript -e 'tell application \"System Events\" to tell process \"CodexBar\" to click menu bar item 1 of menu bar 2'"
