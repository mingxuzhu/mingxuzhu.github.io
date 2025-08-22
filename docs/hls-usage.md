# 在 GitHub Pages 上播放大视频的推荐做法（HLS）

本仓库通过 HLS 分片 + hls.js 在 GitHub Pages 上播放大视频。不要将 MP4 通过 Git LFS 提供给 Pages，Pages 不会直接服务 LFS 对象。

## 前置：安装 ffmpeg
- macOS: `brew install ffmpeg`
- Ubuntu/Debian: `sudo apt-get update && sudo apt-get install -y ffmpeg`
- Windows: 参考 https://ffmpeg.org/download.html （或用包管理器：scoop/choco）

## 生成 HLS 分片
在仓库根目录执行（将路径替换为你的本地视频文件）：

```bash
bash scripts/generate-hls.sh /path/to/video.mp4 assets/hls/myvideo 6
```

脚本会在 `assets/hls/myvideo/` 生成 `master.m3u8` 和若干 `seg_XXX.ts` 分片。

## 提交与推送（不要用 LFS）
确保没有用 LFS 跟踪 `.m3u8` 或 `.ts` 文件，然后提交：

```bash
git add assets/hls/myvideo video.html
git commit -m "feat: add HLS assets for video playback"
git push origin main
```

提交后访问：

- 页面：`/video.html`
- 播放列表：`/assets/hls/myvideo/master.m3u8`

## 可选：自适应多码率（1080p/720p/480p）
以下命令会生成多套清晰度并自动创建 `master.m3u8` 汇总。根据你的机器性能调整码率与 preset。

```bash
ffmpeg -y -i /path/to/video.mp4 \
-filter_complex "[0:v]split=3[v1][v2][v3]; \
 [v1]scale=w=1920:h=1080:force_original_aspect_ratio=decrease[va]; \
 [v2]scale=w=1280:h=720:force_original_aspect_ratio=decrease[vb]; \
 [v3]scale=w=854:h=480:force_original_aspect_ratio=decrease[vc]" \
-map [va] -map 0:a? -c:v:0 libx264 -preset veryfast -b:v:0 5000k -maxrate:v:0 5350k -bufsize:v:0 7500k -c:a:0 aac -b:a:0 192k \
-map [vb] -map 0:a? -c:v:1 libx264 -preset veryfast -b:v:1 3000k -maxrate:v:1 3210k -bufsize:v:1 4500k -c:a:1 aac -b:a:1 160k \
-map [vc] -map 0:a? -c:v:2 libx264 -preset veryfast -b:v:2 1200k -maxrate:v:2 1284k -bufsize:v:2 1800k -c:a:2 aac -b:a:2 128k \
-g 48 -keyint_min 48 -sc_threshold 0 -hls_time 6 -hls_playlist_type vod -hls_flags independent_segments \
-var_stream_map "v:0,a:0,name:1080p v:1,a:1,name:720p v:2,a:2,name:480p" \
-hls_segment_filename "assets/hls/myvideo/%v/seg_%03d.ts" \
-master_pl_name "master.m3u8" \
-f hls "assets/hls/myvideo/%v/index.m3u8"
```

## 常见问题
- 404：检查 `video.html` 与 `assets/hls/myvideo/master.m3u8` 路径是否一致。
- 不能播放：打开浏览器控制台查看网络请求，确认分片 `.ts` 可被正常加载。
- 带宽：Pages 适合中小流量。如访问量较大，建议迁移到对象存储 + CDN。