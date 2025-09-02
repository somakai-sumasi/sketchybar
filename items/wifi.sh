#!/bin/bash

# WiFi Item with Control Center Alias
# Uses native macOS WiFi icon from Control Center

# Add WiFi alias from Control Center
sketchybar --add alias "コントロールセンター,WiFi" right \
           --rename "コントロールセンター,WiFi" wifi_alias \
           --set wifi_alias \
                 alias.color=0xffffffff \
                 alias.scale=1.0 \
                 label.drawing=off \
                 icon.drawing=off \
                 padding_left=0 \
                 padding_right=0 \
                 