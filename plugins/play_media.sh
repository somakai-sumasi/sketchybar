#!/bin/bash

# https://www.nerdfonts.com/cheat-sheet

# ============================
# 設定値
# ============================
readonly STATE_FILE="/tmp/sketchybar_media_state.json"
readonly SCROLL_TIME=1
readonly ARTWORK_IMAGE_SCALE=0.5

# アイコン定義
readonly ICON_PLAYING="󰝚 "
readonly ICON_PAUSED="󰝛 "

# ============================
# 状態読み込み
# ============================
load_state() {
    if [ ! -f "$STATE_FILE" ]; then
        STATE="{}"
    else
        STATE=$(cat "$STATE_FILE" 2>/dev/null)
        [ -z "$STATE" ] && STATE="{}"
    fi

    TITLE=$(printf '%s' "$STATE" | jq -r '.title // ""')
    ARTISTS=$(printf '%s' "$STATE" | jq -r '.artist // ""')
    IS_PLAYING=$(printf '%s' "$STATE" | jq -r '.playing // false')
    IMAGE_FILE=$(printf '%s' "$STATE" | jq -r '.artworkPath // ""')

    local elapsed duration timestamp playback_rate
    elapsed=$(printf '%s' "$STATE" | jq -r '.elapsedTime // 0')
    duration=$(printf '%s' "$STATE" | jq -r '.duration // 0')
    timestamp=$(printf '%s' "$STATE" | jq -r '.timestamp // ""')
    playback_rate=$(printf '%s' "$STATE" | jq -r '.playbackRate // 0')

    # 再生中のみ timestamp 経過分を加算
    if [ "$IS_PLAYING" = "true" ] && [ -n "$timestamp" ] && [ "$timestamp" != "null" ]; then
        local ts_epoch now_epoch elapsed_since
        ts_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s" 2>/dev/null || echo 0)
        now_epoch=$(date "+%s")
        elapsed_since=$(echo "$now_epoch $ts_epoch" | awk '{print $1 - $2}')
        CURRENT_ELAPSED=$(echo "$elapsed $elapsed_since $playback_rate" | awk '{print $1 + $2 * $3}')
    else
        CURRENT_ELAPSED="$elapsed"
    fi

    DURATION="$duration"
    CURRENT_TIME=$(format_seconds "$CURRENT_ELAPSED")
    TOTAL_TIME=$(format_seconds "$DURATION")

    if [ -n "$DURATION" ] && [ "$DURATION" != "null" ] && [ "$(echo "$DURATION > 0" | bc -l)" = "1" ]; then
        PROGRESS_PERCENT=$(echo "$CURRENT_ELAPSED $DURATION" | awk '{p = $1 / $2 * 100; if (p < 0) p = 0; if (p > 100) p = 100; printf "%d", p}')
    else
        PROGRESS_PERCENT=0
    fi
}

format_seconds() {
    local secs="${1:-0}"
    [ "$secs" = "null" ] && secs=0
    local total
    total=$(echo "$secs" | awk '{printf "%d", $1}')
    local m=$((total / 60))
    local s=$((total % 60))
    printf "%d:%02d" "$m" "$s"
}

# ============================
# 表示テキスト幅計算
# ============================
get_display_width() {
    local str=$1
    local width=0
    local i
    for (( i=0; i<${#str}; i++ )); do
        local char="${str:$i:1}"
        local bytes
        bytes=$(printf '%s' "$char" | wc -c | tr -d ' ')
        if [ "$bytes" -eq 3 ]; then
            width=$((width + 2))
        else
            width=$((width + 1))
        fi
    done
    echo $width
}

substr_by_display_width() {
    local str=$1
    local start_width=$2
    local max_width=$3
    local result=""
    local current_width=0
    local skip_width=0
    local i
    for (( i=0; i<${#str}; i++ )); do
        local char="${str:$i:1}"
        local bytes
        bytes=$(printf '%s' "$char" | wc -c | tr -d ' ')
        local char_width=1
        [ "$bytes" -eq 3 ] && char_width=2

        if [ $skip_width -lt $start_width ]; then
            skip_width=$((skip_width + char_width))
            continue
        fi
        if [ $current_width -ge $max_width ]; then
            break
        fi
        if [ $((current_width + char_width)) -le $max_width ]; then
            result="${result}${char}"
            current_width=$((current_width + char_width))
        else
            result="${result} "
            break
        fi
    done
    while [ $current_width -lt $max_width ]; do
        result="${result} "
        current_width=$((current_width + 1))
    done
    echo "$result"
}

generate_scrolling_text() {
    local text=$1
    local max_display_width=$2
    local force_scroll=${3:-false}
    local padding_width=${4:-4}

    local text_display_width
    text_display_width=$(get_display_width "$text")

    if [ "$force_scroll" != "true" ] && [ $text_display_width -le $max_display_width ]; then
        local pad_count=$((max_display_width - text_display_width))
        local pad=""
        local i
        for (( i=0; i<pad_count; i++ )); do
            pad="${pad} "
        done
        echo "${text}${pad}"
        return
    fi

    local padding=""
    local i
    for (( i=0; i<padding_width; i++ )); do
        padding="${padding} "
    done

    local padded_text="${text}${padding}"
    local loop_text="${padded_text}${padded_text}"
    local loop_width
    loop_width=$(get_display_width "$padded_text")

    local scroll_step=2
    local total_steps=$((loop_width / scroll_step))
    if [ $((loop_width % scroll_step)) -ne 0 ]; then
        total_steps=$((total_steps + 1))
    fi
    [ "$total_steps" -eq 0 ] && total_steps=1

    local current_step=$(( ($(date +%s) / SCROLL_TIME) % total_steps ))
    local start=$((current_step * scroll_step))

    substr_by_display_width "$loop_text" $start $max_display_width
}

# ============================
# UI状態決定
# ============================
determine_ui_state() {
    if [ "$IS_PLAYING" = "true" ]; then
        ICON=$ICON_PLAYING
    else
        ICON=$ICON_PAUSED
    fi

    if [ -z "$TITLE" ] || [ "$TITLE" = "null" ]; then
        IS_TITLE_DISPLAY=off
        IS_ICON_DISPLAY=off
    else
        IS_TITLE_DISPLAY=on
        IS_ICON_DISPLAY=on
    fi
}

# ============================
# ポップアップ更新
# ============================
update_popup() {
    if [ -n "$IMAGE_FILE" ] && [ -f "$IMAGE_FILE" ]; then
        sketchybar --set playa_media.artwork background.image="$IMAGE_FILE" \
                                              background.image.scale=$ARTWORK_IMAGE_SCALE
    else
        sketchybar --set playa_media.artwork background.image="" \
                                              background.image.scale=$ARTWORK_IMAGE_SCALE
    fi

    local title_max_width=30
    local artist_max_width=39
    local display_title display_artists
    display_title=$(generate_scrolling_text "$TITLE" $title_max_width)
    display_artists=$(generate_scrolling_text "$ARTISTS" $artist_max_width)

    sketchybar --set playa_media.title label="$display_title" \
               --set playa_media.artist label="$display_artists" \
               --set playa_media.time label="${CURRENT_TIME:-0:00}" \
               --set playa_media.duration label="${TOTAL_TIME:-0:00}" \
               --set playa_media.progress slider.percentage="${PROGRESS_PERCENT:-0}"
}

# ============================
# メインバー更新
# ============================
update_main_bar() {
    sketchybar --set "$NAME" \
        icon="${ICON}" \
        label="${DISPLAY_TEXT}" \
        icon.drawing="${IS_TITLE_DISPLAY}" \
        label.drawing="${IS_ICON_DISPLAY}" \
        label.font="Moralerspace Neon HW:Regular:14.0" \
        label.width=210 \
        label.align=left \
        background.drawing=on \
        background.image="" \
        background.padding_left=0
}

# ============================
# マウスイベント処理
# ============================
handle_mouse_event() {
    if [ "$SENDER" = "mouse.clicked" ]; then
        update_popup
    elif [ "$SENDER" = "mouse.exited.global" ]; then
        sketchybar --set playa_media popup.drawing=off
    fi
}

# ============================
# メイン
# ============================
main() {
    load_state
    determine_ui_state
    DISPLAY_TEXT=$(generate_scrolling_text " ${TITLE}  󰙃 ${ARTISTS}  " 30 true)

    if [ "$SENDER" = "mouse.clicked" ] || [ "$SENDER" = "mouse.exited.global" ]; then
        handle_mouse_event
    fi

    update_main_bar

    if [ -n "$IMAGE_FILE" ] || [ -n "$TITLE" ]; then
        update_popup
    fi
}

main
