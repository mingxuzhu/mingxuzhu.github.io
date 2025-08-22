#!/usr/bin/env bash
# 用法: scripts/generate-hls.sh /path/to/video.mp4 [outdir] [segment_seconds]
# 示例: scripts/generate-hls.sh ~/Videos/video.mp4 assets/hls/myvideo 6
set -euo pipefail

INPUT="${1:-}"
OUTDIR="${2:-assets/hls/myvideo}"
SEG_DUR="${3:-6}"

if [[ -z "${INPUT}" ]]; then
  echo "Usage: $0 /path/to/video.mp4 [outdir] [segment_seconds]" >&2
  exit 1
fi

mkdir -p "${OUTDIR}"

# 单码率 HLS，通用稳定。需要已安装 ffmpeg。
ffmpeg -y -i "${INPUT}" \
  -c:v libx264 -preset veryfast -crf 22 \
  -c:a aac -b:a 128k -ac 2 \
  -hls_time "${SEG_DUR}" \
  -hls_playlist_type vod \
  -hls_segment_type mpegts \
  -hls_flags independent_segments \
  -hls_segment_filename "${OUTDIR}/seg_%03d.ts" \
  "${OUTDIR}/master.m3u8"

echo "Done. HLS output at: ${OUTDIR}/master.m3u8"