"""What ffprobe can tell us about a source file before we cut it up."""

import json
from dataclasses import dataclass
from pathlib import Path

from vod_packager.ffmpeg import binary, run

# Codecs MPEG-TS can carry as-is, so the segments can be stream-copied.
TS_SAFE_VIDEO = {"h264", "hevc", "mpeg2video"}
TS_SAFE_AUDIO = {"aac", "mp3", "ac3", "eac3"}


@dataclass(frozen=True, slots=True)
class MediaInfo:
    path: Path
    duration: float
    video_codec: str | None
    audio_codec: str | None
    width: int | None
    height: int | None
    fps: float | None
    keyframes: tuple[float, ...] | None = None

    @property
    def ts_compatible(self) -> bool:
        """True if both streams can go into MPEG-TS without re-encoding."""
        if self.video_codec not in TS_SAFE_VIDEO:
            return False
        return self.audio_codec is None or self.audio_codec in TS_SAFE_AUDIO

    @property
    def max_keyframe_gap(self) -> float | None:
        """Longest stretch without a keyframe — the floor on copied segment length."""
        if not self.keyframes:
            return None
        marks = [*self.keyframes, self.duration]
        return max(b - a for a, b in zip(marks, marks[1:]))

    @property
    def resolution(self) -> str:
        if self.width and self.height:
            return f"{self.width}x{self.height}"
        return "?"


def probe(path: Path, keyframes: bool = False) -> MediaInfo:
    """Read stream info. `keyframes=True` adds a full pass over the video stream."""
    raw = run(
        [
            binary("ffprobe"),
            "-v", "error",
            "-show_entries", "format=duration",
            "-show_entries", "stream=codec_type,codec_name,width,height,r_frame_rate",
            "-of", "json",
            str(path),
        ]
    )
    data = json.loads(raw)
    streams = data.get("streams", [])
    video = next((s for s in streams if s.get("codec_type") == "video"), {})
    audio = next((s for s in streams if s.get("codec_type") == "audio"), {})

    return MediaInfo(
        path=path,
        duration=float(data.get("format", {}).get("duration") or 0.0),
        video_codec=video.get("codec_name"),
        audio_codec=audio.get("codec_name"),
        width=video.get("width"),
        height=video.get("height"),
        fps=_ratio(video.get("r_frame_rate")),
        keyframes=_keyframes(path) if keyframes else None,
    )


def _keyframes(path: Path) -> tuple[float, ...]:
    """Timestamps of every keyframe. Walks the whole video stream, so it isn't free."""
    raw = run(
        [
            binary("ffprobe"),
            "-v", "error",
            "-select_streams", "v:0",
            "-skip_frame", "nokey",
            "-show_entries", "frame=pts_time",
            "-of", "csv=p=0",
            str(path),
        ]
    )
    times = []
    for line in raw.splitlines():
        value = line.strip().rstrip(",")
        if value and value != "N/A":
            times.append(float(value))
    return tuple(sorted(times))


def _ratio(value: str | None) -> float | None:
    """`30000/1001` -> 29.97."""
    if not value or "/" not in value:
        return None
    num, _, den = value.partition("/")
    try:
        return float(num) / float(den)
    except (ValueError, ZeroDivisionError):
        return None
