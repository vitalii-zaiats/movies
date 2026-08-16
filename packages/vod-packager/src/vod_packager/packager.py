"""Cut a source file into HLS .ts segments plus an index.m3u8, on disk."""

import re
from dataclasses import dataclass
from pathlib import Path

from vod_packager.ffmpeg import FfmpegError, binary, run
from vod_packager.probe import MediaInfo, probe

PLAYLIST_NAME = "index.m3u8"
SEGMENT_PATTERN = "seg_%05d.ts"
EXTINF_RE = re.compile(r"^#EXTINF:(?P<duration>[\d.]+)", re.MULTILINE)

Mode = str  # "auto" | "copy" | "encode"


@dataclass(frozen=True, slots=True)
class Segment:
    path: Path
    duration: float
    size: int


@dataclass(slots=True)
class PackageResult:
    source: MediaInfo
    out_dir: Path
    playlist: Path
    segments: list[Segment]
    mode: Mode
    reason: str

    @property
    def total_size(self) -> int:
        return sum(s.size for s in self.segments)

    def to_dict(self) -> dict:
        return {
            "source": str(self.source.path),
            "duration": round(self.source.duration, 3),
            "resolution": self.source.resolution,
            "mode": self.mode,
            "reason": self.reason,
            "out_dir": str(self.out_dir),
            "playlist": str(self.playlist),
            "total_size": self.total_size,
            "segments": [
                {"name": s.path.name, "duration": s.duration, "size": s.size}
                for s in self.segments
            ],
        }


def package(
    source: Path,
    out_dir: Path,
    *,
    segment_time: float = 6.0,
    mode: Mode = "auto",
    overwrite: bool = False,
) -> PackageResult:
    """Write `out_dir/index.m3u8` and its .ts segments. Returns what was produced."""
    if not source.is_file():
        raise FileNotFoundError(f"no such file: {source}")

    # Only "auto" needs the keyframe scan, and that scan reads the whole stream.
    info = probe(source, keyframes=(mode == "auto"))
    effective, reason = _decide(info, mode, segment_time)

    _prepare(out_dir, overwrite=overwrite)
    playlist = out_dir / PLAYLIST_NAME

    run(_command(source, out_dir, playlist, segment_time, effective))

    segments = _collect(playlist)
    if not segments:
        raise FfmpegError(f"ffmpeg wrote no segments into {out_dir}")

    return PackageResult(info, out_dir, playlist, segments, effective, reason)


def _decide(info: MediaInfo, mode: Mode, segment_time: float) -> tuple[Mode, str]:
    """Pick copy vs encode, and say why — the 'why' is what makes surprises debuggable."""
    if mode == "copy":
        return "copy", "forced with --copy"
    if mode == "encode":
        return "encode", "forced with --encode"

    codecs = f"{info.video_codec}/{info.audio_codec or 'no audio'}"
    if not info.ts_compatible:
        return "encode", f"{codecs} can't go into MPEG-TS as-is"

    gap = info.max_keyframe_gap
    if gap is None:
        return "encode", "no keyframes found"
    if gap > segment_time + 0.5:
        # Copying can only cut on keyframes, so segments would overshoot the target.
        return "encode", f"keyframes up to {gap:.1f}s apart, target is {segment_time:g}s"

    return "copy", f"{codecs}, keyframes every ≤{gap:.1f}s"


def _prepare(out_dir: Path, overwrite: bool) -> None:
    existing = list(out_dir.glob("*.ts")) + list(out_dir.glob("*.m3u8")) if out_dir.exists() else []
    if existing and not overwrite:
        raise FileExistsError(
            f"{out_dir} already holds {len(existing)} segment/playlist files — pass --overwrite"
        )
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in existing:
        stale.unlink()


def _command(
    source: Path, out_dir: Path, playlist: Path, segment_time: float, mode: Mode
) -> list[str]:
    args = [
        binary("ffmpeg"),
        "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(source),
        "-map", "0:v:0", "-map", "0:a:0?",
    ]

    if mode == "copy":
        args += ["-c", "copy"]
    else:
        args += [
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "21",
            "-profile:v", "high", "-pix_fmt", "yuv420p",
            # Put a keyframe exactly on every segment boundary.
            "-force_key_frames", f"expr:gte(t,n_forced*{segment_time:g})",
            "-c:a", "aac", "-b:a", "128k", "-ac", "2",
        ]

    args += [
        "-f", "hls",
        "-hls_time", f"{segment_time:g}",
        "-hls_playlist_type", "vod",
        "-hls_flags", "independent_segments",
        "-hls_segment_type", "mpegts",
        "-hls_list_size", "0",
        "-hls_segment_filename", str(out_dir / SEGMENT_PATTERN),
        str(playlist),
    ]
    return args


def _collect(playlist: Path) -> list[Segment]:
    """Read back the playlist ffmpeg wrote — it is the source of truth on durations."""
    text = playlist.read_text(encoding="utf-8")
    durations = [float(m.group("duration")) for m in EXTINF_RE.finditer(text)]
    names = [line.strip() for line in text.splitlines() if line.strip().endswith(".ts")]

    segments = []
    for name, duration in zip(names, durations):
        path = playlist.parent / name
        segments.append(Segment(path=path, duration=duration, size=path.stat().st_size))
    return segments
