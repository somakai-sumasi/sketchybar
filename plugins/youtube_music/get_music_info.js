// YouTube Musicから曲情報を取得するJavaScript

(() => {
    try {
        // 曲名を取得
        const titleEl = document.querySelector('div.content-info-wrapper yt-formatted-string.title');
        const title = titleEl ? titleEl.textContent.trim() : '';
        
        // byline情報を取得（アーティスト • アルバム • 年）
        const bylineEl = document.querySelector('div.content-info-wrapper yt-formatted-string.byline');
        const bylineText = bylineEl ? bylineEl.textContent.trim() : '';
        
        // bylineを「•」で分割して解析
        let artists = [];
        let album = '';
        let year = '';
        
        if (bylineText) {
            const parts = bylineText.split('•').map(p => p.trim());
            
            if (parts.length >= 1) {
                // 最初の部分はアーティスト（カンマ区切りで複数の場合がある）
                const artistText = parts[0];
                // カンマと「、」の両方で分割（日本語と英語の両方に対応）
                artists = artistText.split(/[,、]/).map(a => a.trim()).filter(a => a);
            }
            
            if (parts.length >= 2) {
                // 2番目の部分は通常アルバム名
                album = parts[1];
            }
            
            if (parts.length >= 3) {
                // 3番目の部分は通常リリース年
                // 年の部分から数字のみを抽出（「2024年」→「2024」）
                const yearMatch = parts[2].match(/\d{4}/);
                year = yearMatch ? yearMatch[0] : parts[2];
            }
        }
        
        // アーティスト情報の文字列（後方互換性のため）
        const artist = artists.join(', ');
        
        // アルバムアートのURLを取得
        const imgEl = document.querySelector('ytmusic-player-bar img.image');
        let imageUrl = imgEl ? imgEl.src : '';
        
        // より高解像度の画像URLに変換
        if (imageUrl.includes('=w')) {
            imageUrl = imageUrl.replace(/=w\d+-h\d+/, '=w500-h500');
        }
        
        // 再生状態を取得（複数の方法を試す）
        let isPlaying = false;
        
        // 方法1: play-pause-buttonのtitle属性をチェック
        const playBtn = document.querySelector('tp-yt-paper-icon-button#play-pause-button');
        if (playBtn) {
            const btnTitle = playBtn.getAttribute('title');
            // 日本語と英語両方のパターンをチェック
            isPlaying = btnTitle === 'Pause' || btnTitle === '一時停止' || btnTitle === 'Pausar';
        }
        
        // 方法2: aria-label属性をチェック
        if (!isPlaying && playBtn) {
            const ariaLabel = playBtn.getAttribute('aria-label');
            if (ariaLabel) {
                isPlaying = ariaLabel.includes('Pause') || ariaLabel.includes('一時停止');
            }
        }
        
        // 方法3: アイコンのパスをチェック（pauseアイコンが表示されていれば再生中）
        if (!isPlaying && playBtn) {
            const iconPath = playBtn.querySelector('path');
            if (iconPath) {
                const d = iconPath.getAttribute('d');
                // pauseアイコンのパス（2本の縦線）をチェック
                if (d && (d.includes('M6 19h4V5H6v14zm8-14v14h4V5h-4z') || d.includes('M 6,19 10,19 10,5 6,5 6,19 z M 14,5 14,19 18,19 18,5 14,5 z'))) {
                    isPlaying = true;
                }
            }
        }
        
        // 方法4: ビデオ要素の状態を直接チェック
        if (!isPlaying) {
            const video = document.querySelector('video');
            if (video && !video.paused) {
                isPlaying = true;
            }
        }
        
        // 再生時間情報を取得
        const timeEl = document.querySelector('span.time-info');
        const timeInfo = timeEl ? timeEl.textContent.trim() : '';
        
        // 現在の再生位置と全体の時間を分離
        let currentTime = '';
        let duration = '';
        if (timeInfo) {
            const timeParts = timeInfo.split('/').map(t => t.trim());
            if (timeParts.length === 2) {
                currentTime = timeParts[0];
                duration = timeParts[1];
            }
        }
        
        // 時間を秒に変換するヘルパー関数
        const timeToSeconds = (timeStr) => {
            if (!timeStr) return 0;
            const parts = timeStr.split(':').map(p => parseInt(p, 10));
            if (parts.length === 2) {
                return parts[0] * 60 + parts[1];
            } else if (parts.length === 3) {
                return parts[0] * 3600 + parts[1] * 60 + parts[2];
            }
            return 0;
        };
        
        // 進捗バーの割合を取得
        let progressPercent = 0;
        if (currentTime && duration) {
            const currentSeconds = timeToSeconds(currentTime);
            const totalSeconds = timeToSeconds(duration);
            if (totalSeconds > 0) {
                progressPercent = Math.round((currentSeconds / totalSeconds) * 100);
            }
        }
    
        
        return JSON.stringify({
            title: title,
            artist: artist,  // 後方互換性のため（カンマ区切りの文字列）
            artists: artists,  // 配列形式のアーティストリスト
            album: album,
            year: year,
            imageUrl: imageUrl,
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration,
            progressPercent: progressPercent,
            timeInfo: timeInfo
        });
    } catch(e) {
        return JSON.stringify({
            error: e.toString(),
            message: 'Failed to extract YouTube Music information'
        });
    }
})()