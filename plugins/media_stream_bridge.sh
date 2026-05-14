#!/bin/bash

set -u

readonly STATE_FILE="/tmp/sketchybar_media_state.json"
readonly CACHE_DIR="$HOME/.config/sketchybar/cache"
readonly CACHE_MAX_FILES=100
readonly CACHE_DELETE_COUNT=50
readonly CACHE_MAX_DAYS=7
readonly MEDIA_CONTROL="/opt/homebrew/bin/media-control"
readonly SKETCHYBAR="/opt/homebrew/bin/sketchybar"
readonly JQ="/opt/homebrew/bin/jq"
readonly MD5="/sbin/md5"
readonly SIPS="/usr/bin/sips"
readonly ARTWORK_RESIZE_MAX=140

mkdir -p "$CACHE_DIR"
echo '{}' > "$STATE_FILE"

cleanup_cache() {
  find "$CACHE_DIR" -type f -name "*.jpg" -mtime +$CACHE_MAX_DAYS -delete 2>/dev/null
  local count
  count=$(/bin/ls -1 "$CACHE_DIR"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt $CACHE_MAX_FILES ]; then
    /bin/ls -t "$CACHE_DIR"/*.jpg 2>/dev/null | tail -$CACHE_DELETE_COUNT | xargs rm -f 2>/dev/null
  fi
}

cleanup_cache

"$MEDIA_CONTROL" stream | while IFS= read -r line; do
  [ -z "$line" ] && continue

  type=$(printf '%s' "$line" | "$JQ" -r '.type // ""' 2>/dev/null)
  [ "$type" != "data" ] && continue

  diff=$(printf '%s' "$line" | "$JQ" -r '.diff')
  payload=$(printf '%s' "$line" | "$JQ" -c '.payload')

  if [ "$diff" = "false" ]; then
    new_state="$payload"
  else
    new_state=$("$JQ" -c --argjson p "$payload" '. + $p' "$STATE_FILE")
  fi

  artwork_data=$(printf '%s' "$new_state" | "$JQ" -r '.artworkData // empty')
  if [ -n "$artwork_data" ]; then
    content_id=$(printf '%s' "$new_state" | "$JQ" -r '.contentItemIdentifier // empty')
    title=$(printf '%s' "$new_state" | "$JQ" -r '.title // empty')
    artist=$(printf '%s' "$new_state" | "$JQ" -r '.artist // empty')
    hash_input="${content_id}|${title}|${artist}"
    cache_hash=$(printf '%s' "$hash_input" | "$MD5" -q)
    artwork_path="$CACHE_DIR/${cache_hash}.jpg"
    if [ ! -f "$artwork_path" ]; then
      printf '%s' "$artwork_data" | base64 -d > "$artwork_path" 2>/dev/null
      "$SIPS" -Z "$ARTWORK_RESIZE_MAX" "$artwork_path" >/dev/null 2>&1
    fi
    new_state=$(printf '%s' "$new_state" | "$JQ" -c --arg p "$artwork_path" 'del(.artworkData) | .artworkPath = $p')
  fi

  tmp=$(mktemp "${STATE_FILE}.XXXXXX")
  printf '%s\n' "$new_state" > "$tmp"
  mv -f "$tmp" "$STATE_FILE"
  "$SKETCHYBAR" --trigger media_change 2>/dev/null
done
