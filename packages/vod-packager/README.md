# vod-packager

Takes a video file, cuts it into HLS `.ts` segments and writes them to disk next
to an `index.m3u8` — the same shape ashdi serves, so
[`ashdi-finder`](../ashdi-finder) output and this output are interchangeable.

Needs `ffmpeg` and `ffprobe` on PATH (`brew install ffmpeg`). No Python deps.

```bash
uv run vod-pack ~/Downloads/cute_cat_video.mp4
uv run vod-pack video.mp4 -o out/cat -t 4 --overwrite
uv run vod-pack video.mp4 --encode --json
```

```
vod/cute-cat-video/
├── index.m3u8
├── seg_00000.ts
└── seg_00001.ts
```

## copy vs encode

Default is `auto`, and it prints which it picked and why:

- **copy** — remuxes, no quality loss, near-instant. Needs TS-friendly codecs
  (h264/hevc + aac/mp3/ac3) *and* keyframes at least as dense as the target
  segment length, because a copied stream can only be cut on a keyframe.
- **encode** — h264 `crf 21` + aac 128k, with `-force_key_frames` putting a
  keyframe exactly on every boundary, so segments land on the target length.

`--copy` / `--encode` force it. `auto` runs a keyframe scan to decide, which
reads through the video stream once; the forced modes skip that scan.
