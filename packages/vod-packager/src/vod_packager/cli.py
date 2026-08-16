"""CLI: `vod-pack video.mp4` -> a folder of .ts segments and an index.m3u8."""

import argparse
import json
import re
import sys
from pathlib import Path

from vod_packager.ffmpeg import FfmpegError
from vod_packager.packager import PackageResult, package

DEFAULT_ROOT = Path("vod")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="vod-pack",
        description="Cut a video into HLS .ts segments on disk.",
    )
    parser.add_argument("source", type=Path, help="video file to package")
    parser.add_argument(
        "-o",
        "--out",
        type=Path,
        help=f"output folder (default: {DEFAULT_ROOT}/<name>)",
    )
    parser.add_argument(
        "-t",
        "--segment-time",
        type=float,
        default=6.0,
        help="target segment length in seconds (default: 6)",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--copy", action="store_true", help="stream-copy, never re-encode (fast, lossless)"
    )
    mode.add_argument("--encode", action="store_true", help="always re-encode to h264/aac")
    parser.add_argument("--overwrite", action="store_true", help="replace an existing output")
    parser.add_argument("--json", action="store_true", help="print JSON instead of a summary")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    mode = "copy" if args.copy else "encode" if args.encode else "auto"
    out_dir = args.out or DEFAULT_ROOT / _slug(args.source.stem)

    try:
        result = package(
            args.source,
            out_dir,
            segment_time=args.segment_time,
            mode=mode,
            overwrite=args.overwrite,
        )
    except (FileNotFoundError, FileExistsError, FfmpegError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(result.to_dict(), ensure_ascii=False, indent=2))
    else:
        _print_summary(result)
    return 0


def _print_summary(result: PackageResult) -> None:
    info = result.source
    lengths = ", ".join(f"{s.duration:.1f}s" for s in result.segments)

    print(f"source    {info.path.name}  {info.duration:.1f}s  {info.resolution}")
    print(f"mode      {result.mode}  ({result.reason})")
    print(f"output    {result.playlist}")
    print(f"segments  {len(result.segments)}  [{lengths}]  {_size(result.total_size)}")


def _size(num: int) -> str:
    value = float(num)
    for unit in ("B", "KB", "MB", "GB"):
        if value < 1024 or unit == "GB":
            return f"{value:.1f} {unit}"
        value /= 1024
    return f"{value:.1f} GB"


def _slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-") or "video"


if __name__ == "__main__":
    raise SystemExit(main())
