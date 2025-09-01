#!/bin/sh

sketchybar \
    --add item slack right \
    --set slack update_freq=30 script="$PLUGIN_DIR/slack.sh" \
    --set slack click_script="open -a Slack" \
    --subscribe slack system_woke
