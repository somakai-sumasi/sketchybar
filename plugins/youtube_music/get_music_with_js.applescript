-- YouTube MusicからJavaScriptで詳細情報を取得するAppleScript
-- Chrome Canaryのタブから曲情報、アーティスト、アルバムアート、再生状態を取得

on run argv
    -- スクリプトのディレクトリパスを引数から取得（bashから渡される）
    if (count of argv) > 0 then
        set script_dir to item 1 of argv
    else
        -- デフォルトパス（相対パスから計算）
        set script_dir to (do shell script "cd \"$(dirname \"$0\")\" && pwd")
    end if
    
    -- JavaScriptファイルを読み込み
    set js_file_path to script_dir & "/get_music_info.js"
    try
        set js_code to do shell script "cat " & quoted form of js_file_path
    on error
        return "{\"error\": \"Failed to read JavaScript file\"}"
    end try
    
    try
        tell application "Google Chrome Canary"
            set music_info to ""
            
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "music.youtube.com" then
                        -- JavaScriptを実行
                        set music_info to execute t javascript js_code
                        return music_info
                    end if
                end repeat
            end repeat
            
            if music_info is "" then
                return "{\"error\": \"YouTube Music tab not found\"}"
            end if
        end tell
    on error err
        return "{\"error\": \"" & err & "\"}"
    end try
end run