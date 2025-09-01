#!/bin/bash

# ────────────────────────────────────
# ▸ Configuration
# ────────────────────────────────────

# Colors
POPUP_BG_COLOR=0xff1e1e1e
POPUP_BORDER_COLOR=0xff414141
ACCENT_COLOR=0xff4a9eff
TITLE_COLOR=0xffffffff
ARTIST_COLOR=0xffaaaaaa
TIME_COLOR=0xff888888
PROGRESS_BAR_BG_COLOR=0xff333333

# Dimensions
POPUP_HEIGHT=90
POPUP_CORNER_RADIUS=8
POPUP_BORDER_WIDTH=1
ARTWORK_SIZE=70
ARTWORK_CORNER_RADIUS=6
ARTWORK_SCALE=0.01
ARTWORK_IMAGE_SCALE=0.14
PROGRESS_BAR_HEIGHT=3
PROGRESS_BAR_WIDTH=100

# Fonts
TITLE_FONT="SF Pro Display:Bold:11.0"
ARTIST_FONT="SF Pro Display:Regular:10.0"
TIME_FONT="SF Pro Display:Regular:8.0"

# Text limits
TITLE_MAX_CHARS=20
ARTIST_MAX_CHARS=20

# ────────────────────────────────────
# ▸ Item Definitions
# ────────────────────────────────────

playa_media=(
  update_freq=1
  script="ARTWORK_IMAGE_SCALE=$ARTWORK_IMAGE_SCALE $PLUGIN_DIR/play_media.sh"
  popup.align=center
  popup.horizontal=on
  popup.background.color=$POPUP_BG_COLOR
  popup.background.corner_radius=$POPUP_CORNER_RADIUS
  popup.background.border_color=$POPUP_BORDER_COLOR
  popup.background.border_width=$POPUP_BORDER_WIDTH
  popup.height=$POPUP_HEIGHT
)

playa_media_artwork=(
  icon.drawing=off
  label.drawing=off
  background.drawing=on
  background.image.scale=$ARTWORK_SCALE
  background.image.corner_radius=$ARTWORK_CORNER_RADIUS
  width=$ARTWORK_SIZE
  background.height=$ARTWORK_SIZE
  padding_left=8
  padding_right=8
)

playa_media_title=(
  icon.drawing=off
  label.font="$TITLE_FONT"
  label.color=$TITLE_COLOR
  label.max_chars=$TITLE_MAX_CHARS
  width=0
  padding_left=0
  padding_right=0
  y_offset=25
)

playa_media_artist=(
  icon.drawing=off
  label.font="$ARTIST_FONT"
  label.color=$ARTIST_COLOR
  label.max_chars=$ARTIST_MAX_CHARS
  width=0
  padding_left=0
  padding_right=0
  y_offset=8
)

playa_media_time=(
  icon.drawing=off
  label.font="$TIME_FONT"
  label.color=$TIME_COLOR
  label="0:00"
  width=35
  padding_left=0
  padding_right=5
  y_offset=-10
)

playa_media_progress=(
  slider.background.color=$PROGRESS_BAR_BG_COLOR
  slider.background.height=$PROGRESS_BAR_HEIGHT
  slider.background.corner_radius=1
  slider.highlight_color=$ACCENT_COLOR
  slider.percentage=0
  slider.width=$PROGRESS_BAR_WIDTH
  padding_left=0
  padding_right=0
  y_offset=-10
)

playa_media_duration=(
  icon.drawing=off
  label.font="$TIME_FONT"
  label.color=$TIME_COLOR
  label.align=right
  label="0:00"
  width=35
  padding_left=5
  padding_right=0
  y_offset=-10
)

# ────────────────────────────────────
# ▸ SketchyBar Setup
# ────────────────────────────────────

sketchybar --add item playa_media right                              \
           --set playa_media "${playa_media[@]}"                     \
           --subscribe playa_media system_woke media_change          \
                                  mouse.entered mouse.exited         \
                                                                     \
           --add item playa_media.artwork popup.playa_media         \
           --set playa_media.artwork "${playa_media_artwork[@]}"    \
                                                                     \
           --add item playa_media.title popup.playa_media           \
           --set playa_media.title "${playa_media_title[@]}"        \
                                                                     \
           --add item playa_media.artist popup.playa_media          \
           --set playa_media.artist "${playa_media_artist[@]}"      \
                                                                     \
           --add item playa_media.time popup.playa_media            \
           --set playa_media.time "${playa_media_time[@]}"          \
                                                                     \
           --add slider playa_media.progress popup.playa_media $PROGRESS_BAR_WIDTH \
           --set playa_media.progress "${playa_media_progress[@]}"  \
                                                                     \
           --add item playa_media.duration popup.playa_media        \
           --set playa_media.duration "${playa_media_duration[@]}"