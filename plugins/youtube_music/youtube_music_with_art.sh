#!/bin/bash

# YouTube Musicの再生中の曲情報とアルバムアートを取得するCLIツール

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# JSONから特定のフィールドを抽出するヘルパー関数
extract_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | sed -n "s/.*\"$field\":\"\\([^\"]*\\)\".*/\\1/p"
}

# エラーチェック
check_json_error() {
    local json="$1"
    local error=$(extract_json_field "$json" "error")
    if [ ! -z "$error" ]; then
        return 1
    fi
    return 0
}

# YouTube Musicの情報をJSONで取得（JavaScript使用）
get_youtube_music_json() {
    # AppleScriptにディレクトリパスを渡す
    osascript "$SCRIPT_DIR/get_music_with_js.applescript" "$SCRIPT_DIR"
}

# JavaScript版を使用して詳細情報を取得
music_data=$(get_youtube_music_json)

# JSON形式で出力
echo "$music_data" | jq '.'