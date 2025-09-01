# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a SketchyBar configuration repository. SketchyBar is a macOS status bar customization tool (version 2.20.1 installed at `/opt/homebrew/bin/sketchybar`).

## Repository Structure

- `sketchybarrc`: Main configuration file that initializes the bar and loads all items
- `colors.sh`: Color palette definitions using Catppuccin Mocha colors
- `icons.sh`: Icon definitions using SF Symbols and Nerd Fonts
- `items/`: Directory containing bar item configurations
  - `clock.sh`: Time display with Google Calendar link
  - `slack.sh`: Slack notification status
  - `play_media.sh`: Media player with popup (artwork, title, artist, progress)
  - `network.sh`: Network status (currently disabled)
- `plugins/`: Directory containing scripts that update item properties
  - `space.sh`: Updates space indicators
  - `front_app.sh`: Updates current application name
  - `volume.sh`: Updates volume icon and level
  - `battery.sh`: Updates battery status and percentage
  - `slack.sh`: Checks Slack notification badge using `lsappinfo`
  - `play_media.sh`: Media player logic with YouTube Music support
  - `youtube_music/`: YouTube Music integration scripts
- `cache/`: Directory for caching album artwork images

## Key Commands

```bash
# Reload SketchyBar configuration
sketchybar --reload

# Update all items (force refresh)
sketchybar --update

# Query current configuration
sketchybar --query

# Query specific item properties
sketchybar --query [item_name]
```

## Architecture

### Configuration Flow
1. `sketchybarrc` is the entry point that:
   - Sets bar properties (position, height, blur, background color)
   - Defines default item properties (fonts, colors, padding)
   - Creates 10 mission control space indicators
   - Sources icon definitions from `icons.sh`
   - Sources item configurations from `items/` directory
   - Triggers initial update with `sketchybar --update`

2. Items are configured with three main commands:
   - `--add item [name] [position]`: Creates new item (left/center/right)
   - `--set [name] [properties]`: Sets item properties
   - `--subscribe [name] [events]`: Subscribes to system/custom events

3. Plugins are shell scripts that:
   - Receive `$NAME` (item name) and `$SENDER` (event type) as environment variables
   - Update item properties using `sketchybar --set $NAME`
   - Are triggered by `update_freq` or subscribed events

### Event System
- **System Events**: `volume_change`, `system_woke`, `power_source_change`, `front_app_switched`, `media_change`
- **Mouse Events**: `mouse.entered`, `mouse.exited` (used for popup interactions)
- **Update Frequencies**: Specified in seconds (e.g., clock updates every 10s, battery every 120s)
- **Click Scripts**: Enable item interactivity (e.g., opening apps or URLs)

### Media Player Implementation
The media player (`play_media.sh`) features:
- Main bar display with scrolling text for long titles
- Popup on hover showing:
  - Album artwork (cached locally)
  - Title and artist information
  - Current time and duration
  - Progress bar with percentage
- YouTube Music integration via AppleScript/JavaScript
- Automatic cache management (max 100 files, 7-day retention)

### Current Active Items
- **Spaces (1-10)**: Mission control indicators with yabai integration for workspace switching
- **Front App**: Displays current application name (left side)
- **Clock**: Time display, updates every 10s, opens Google Calendar on click
- **Volume**: Icon changes based on volume level, updates on volume_change events
- **Battery**: Shows percentage and charging status, updates every 120s
- **Slack**: Notification badge status, updates every 30s, opens Slack on click
- **Media Player (playa_media)**: YouTube Music integration with detailed popup

## Dependencies
- **Required**:
  - `jq`: JSON processing for media player data
  - `lsappinfo`: Slack notification status detection
  - `curl`: Downloading album artwork
- **Optional**:
  - `yabai`: Window manager for space management
  - `nowplaying-cli`: Alternative media source (currently unused but referenced)