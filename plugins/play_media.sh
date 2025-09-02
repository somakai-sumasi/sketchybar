#!/bin/bash

# https://www.nerdfonts.com/cheat-sheet

# ============================
# 設定値
# ============================
readonly CACHE_MAX_FILES=100
readonly CACHE_DELETE_COUNT=50
readonly CACHE_MAX_DAYS=7
readonly PROGRESS_BAR_MAX_WIDTH=200
readonly DISPLAY_TEXT_LENGTH=20
readonly SCROLL_TIME=1

# アイコン定義
readonly ICON_PLAYING=""
readonly ICON_PAUSED=""

# ============================
# 初期設定
# ============================
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$PLUGIN_DIR/../cache"

# ============================
# 音楽情報取得関数
# ============================
fetch_music_info() {
    local music_json=$1
    
    TITLE=$(echo "$music_json" | jq -r '.title // ""')
    
    # artists配列をカンマ区切りの文字列に変換
    ARTISTS=$(echo "$music_json" | jq -r '.artists // [] | join(",")')
    # artistsが空の場合は旧形式のartistフィールドを使用
    if [ -z "$ARTISTS" ]; then
        ARTISTS=$(echo "$music_json" | jq -r '.artist // ""')
    fi
    
    ALBUM=$(echo "$music_json" | jq -r '.album // ""')
    YEAR=$(echo "$music_json" | jq -r '.year // ""')
    IS_PLAYING=$(echo "$music_json" | jq -r '.isPlaying // false')
    IMAGE_URL=$(echo "$music_json" | jq -r '.imageUrl // ""')
    ERROR=$(echo "$music_json" | jq -r '.error // ""')
    
    # 時間情報
    CURRENT_TIME=$(echo "$music_json" | jq -r '.currentTime // "0:00"')
    TOTAL_TIME=$(echo "$music_json" | jq -r '.duration // "0:00"')
    PROGRESS_PERCENT=$(echo "$music_json" | jq -r '.progressPercent // 0')
    
    # フォールバック処理
    [ "$CURRENT_TIME" == "" ] || [ "$CURRENT_TIME" == "null" ] && CURRENT_TIME="0:00"
    [ "$TOTAL_TIME" == "" ] || [ "$TOTAL_TIME" == "null" ] && TOTAL_TIME="0:00"
}

# ============================
# キャッシュ管理関数
# ============================
manage_cache() {
    mkdir -p "$CACHE_DIR"
    
    # 古いキャッシュを削除（7日以上前のファイル）
    find "$CACHE_DIR" -type f -name "*.jpg" -mtime +$CACHE_MAX_DAYS -delete 2>/dev/null
    
    # キャッシュファイル数が上限を超えたら古いものから削除
    local cache_count=$(ls -1 "$CACHE_DIR"/*.jpg 2>/dev/null | wc -l)
    if [ "$cache_count" -gt $CACHE_MAX_FILES ]; then
        ls -t "$CACHE_DIR"/*.jpg 2>/dev/null | tail -$CACHE_DELETE_COUNT | xargs rm -f 2>/dev/null
    fi
}

# ============================
# アルバムアート処理関数
# ============================
process_album_art() {
    local image_url=$1
    
    IMAGE_FILE=""
    if [ ! -z "$image_url" ]; then
        # URLからファイル名を生成（MD5ハッシュ）
        local image_hash=$(echo "$image_url" | md5)
        IMAGE_FILE="$CACHE_DIR/${image_hash}.jpg"
        
        # 画像がキャッシュにない場合はダウンロード
        if [ ! -f "$IMAGE_FILE" ]; then
            curl -s -o "$IMAGE_FILE" "$image_url" 2>/dev/null
        fi
    fi
}

# ============================
# 表示テキスト生成関数
# ============================
generate_display_text() {
    local title=$1
    local artists=$2
    
    local text=" ${title}  󰙃 ${artists}  "
    local text_length=${#text}
    
    # スクロール位置計算
    local start=$(( $(date +%s) % (text_length * SCROLL_TIME) ))
    
    # 表示テキストの切り出し
    DISPLAY_TEXT=${text:$start:$DISPLAY_TEXT_LENGTH}
    local display_length=${#DISPLAY_TEXT}
    
    # 短い場合は先頭から追加
    if [ $display_length -lt $DISPLAY_TEXT_LENGTH ]; then
        DISPLAY_TEXT="$DISPLAY_TEXT${text:0:$(( DISPLAY_TEXT_LENGTH - display_length ))}"
    fi
}

# ============================
# プログレスバー計算関数
# ============================
calculate_progress_width() {
    local percent=$1
    
    if [ ! -z "$percent" ] && [ "$percent" != "null" ]; then
        PROGRESS_WIDTH=$((percent * PROGRESS_BAR_MAX_WIDTH / 100))
    else
        PROGRESS_WIDTH=0
    fi
}

# ============================
# UI状態決定関数
# ============================
determine_ui_state() {
    local error=$1
    local title=$2
    local is_playing=$3
    
    # アイコン設定
    if [ "$is_playing" == "false" ]; then
        ICON=$ICON_PAUSED
    else
        ICON=$ICON_PLAYING
    fi
    
    # 表示状態設定
    if [ ! -z "$error" ] || [ "$title" == "" ]; then
        IS_TITLE_DISPLAY=off
        IS_ICON_DISPLAY=off
    else
        IS_TITLE_DISPLAY=on
        IS_ICON_DISPLAY=on
    fi
}

# ============================
# ポップアップ更新関数
# ============================
update_popup() {
    local image_file=$1
    local title=$2
    local artists=$3
    local current_time=$4
    local total_time=$5
    local progress_percent=$6

    # 環境変数から画像スケールを取得（デフォルト値: 0.1）
    local image_scale="${ARTWORK_IMAGE_SCALE:-0.1}"
    
    if [ ! -z "$image_file" ] && [ -f "$image_file" ]; then
        sketchybar --set playa_media.artwork background.image="$image_file" \
                                              background.image.scale=$image_scale
    else
        sketchybar --set playa_media.artwork background.image="" \
                                              background.image.scale=$image_scale
    fi
    
    # プログレスバーをpercentageで更新
    progress_percent="${progress_percent:-0}"
    
    sketchybar --set playa_media.title label="$title" \
               --set playa_media.artist label="$artists" \
               --set playa_media.time label="${current_time:-0:00}" \
               --set playa_media.duration label="${total_time:-0:00}" \
               --set playa_media.progress slider.percentage="${progress_percent}"
}

# ============================
# メインバー更新関数
# ============================
update_main_bar() {
    local name=$1
    local icon=$2
    local display_text=$3
    local is_title_display=$4
    local is_icon_display=$5
    local image_file=$6
    

    sketchybar --set "$name" \
        icon="${icon}" \
        label="${display_text}" \
        icon.drawing="${is_title_display}" \
        label.drawing="${is_icon_display}" \
        label.width=210 \
        label.align=left \
        background.drawing=on \
        background.image="" \
        background.padding_left=0

}

# ============================
# マウスイベント処理関数
# ============================
handle_mouse_event() {
    local sender=$1
    
    if [ "$sender" = "mouse.clicked" ]; then
        # クリック時にポップアップの表示をトグル
        update_popup "$IMAGE_FILE" "$TITLE" "$ARTISTS" "$CURRENT_TIME" "$TOTAL_TIME" "$PROGRESS_PERCENT"
        
    elif [ "$sender" = "mouse.exited.global" ]; then
        # グローバルでマウスが離れたらポップアップを非表示
        sketchybar --set playa_media popup.drawing=off
    fi
}

# ============================
# メイン処理
# ============================
main() {
    # YouTube Music情報を取得
    MUSIC_JSON=$("$PLUGIN_DIR/youtube_music/youtube_music_with_art.sh")
    
    # 音楽情報を解析
    fetch_music_info "$MUSIC_JSON"
    
    # キャッシュ管理
    manage_cache
    
    # アルバムアート処理
    process_album_art "$IMAGE_URL"
    
    # UI状態決定
    determine_ui_state "$ERROR" "$TITLE" "$IS_PLAYING"
    
    # 表示テキスト生成
    generate_display_text "$TITLE" "$ARTISTS"
    
    # プログレスバー幅計算
    calculate_progress_width "$PROGRESS_PERCENT"
    
    # マウスイベント処理（クリックイベントのみ処理）
    if [ "$SENDER" = "mouse.clicked" ] || [ "$SENDER" = "mouse.exited.global" ]; then
        handle_mouse_event "$SENDER"
    fi
    
    # メインバー更新
    update_main_bar "$NAME" "$ICON" "$DISPLAY_TEXT" "$IS_TITLE_DISPLAY" "$IS_ICON_DISPLAY" "$IMAGE_FILE"
    
    # 通常の更新時にもポップアップ要素を更新（ポップアップが表示されている場合のため）
    if [ ! -z "$PROGRESS_PERCENT" ] && [ ! -z "$IMAGE_FILE" ]; then
        update_popup "$IMAGE_FILE" "$TITLE" "$ARTISTS" "$CURRENT_TIME" "$TOTAL_TIME" "$PROGRESS_PERCENT"
    fi
}

# ============================
# スクリプト実行
# ============================
main