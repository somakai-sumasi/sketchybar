# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a SketchyBar configuration repository. SketchyBar is a macOS status bar customization tool (version 2.20.1 installed at `/opt/homebrew/bin/sketchybar`).

## Repository Structure

- `sketchybarrc`: Main configuration file that initializes the bar and loads all items
- `colors.sh`: Color palette definitions
- `icons.sh`: Icon definitions using SF Symbols and Nerd Fonts
- `items/`: Directory containing bar item configurations
- `plugins/`: Directory containing scripts that update item properties

## Key Commands

```bash
# Reload SketchyBar configuration
sketchybar --reload

# Update all items (force refresh)
sketchybar --update

# Query current configuration
sketchybar --query
```

## Architecture

### Configuration Flow
1. `sketchybarrc` is the entry point that:
   - Sets up the bar appearance and defaults
   - Creates mission control space indicators
   - Sources individual item configurations from `items/` directory
   - Loads plugins for dynamic updates

2. Items are added using:
   - `--add item [name] [position]`: Creates a new item
   - `--set [name] [properties]`: Configures item properties
   - `--subscribe [name] [events]`: Subscribes to system events

3. Plugins are shell scripts that:
   - Receive the item name as `$NAME`
   - Update item properties using `sketchybar --set $NAME`
   - Are triggered by update frequency or subscribed events

### Event System
- Items can subscribe to system events (e.g., `volume_change`, `system_woke`, `front_app_switched`)
- Update frequencies are specified in seconds with `update_freq`
- Click scripts enable interactivity with `click_script`

### Current Active Items
- **Spaces**: Mission control space indicators with yabai integration
- **Front App**: Shows current active application
- **Clock**: Updates every 10 seconds, links to Google Calendar
- **Volume**: Updates on volume changes
- **Battery**: Updates every 120 seconds and on power events
- **Slack**: Shows notification status, updates every 30 seconds
- **Media Player**: Shows currently playing media using `nowplaying-cli`

## Dependencies
- `nowplaying-cli`: Required for media player functionality
- `lsappinfo`: Used for Slack status detection
- `yabai`: Optional, for space management