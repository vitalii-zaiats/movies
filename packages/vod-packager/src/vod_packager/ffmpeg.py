"""Thin wrapper around the ffmpeg / ffprobe binaries."""

import shutil
import subprocess


class FfmpegError(RuntimeError):
    """ffmpeg exited non-zero."""


class FfmpegMissing(FfmpegError):
    """The binary isn't installed."""


def binary(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise FfmpegMissing(f"{name} not found on PATH — install it (brew install ffmpeg)")
    return path


def run(args: list[str]) -> str:
    """Run a command, return stdout, raise `FfmpegError` with the tail of stderr."""
    process = subprocess.run(args, capture_output=True, text=True)
    if process.returncode != 0:
        tail = "\n".join(process.stderr.strip().splitlines()[-12:])
        raise FfmpegError(f"{args[0]} failed (exit {process.returncode}):\n{tail}")
    return process.stdout
