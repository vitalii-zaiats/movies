"""CLI: give it a page URL, it prints the ashdi.vip iframes and their .m3u8 streams.

This is the only module in the package that knows an HTTP library exists, and it
imports it lazily — the library itself works with whatever requester you hand it.
"""

import argparse
import json
import sys
from pathlib import Path

from ashdi_finder.fetching import FetchError
from ashdi_finder.resolve import resolve
from ashdi_finder.results import ResolveResult


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ashdi-finder",
        description=(
            "Find https://ashdi.vip/ iframes in a page's DOM, follow them "
            "and print the .m3u8 streams they play."
        ),
    )
    parser.add_argument("url", help="page URL to scan (an ashdi.vip player URL also works)")
    parser.add_argument(
        "--html-file",
        type=Path,
        help="read HTML from this file instead of downloading (URL is still used as the base)",
    )
    parser.add_argument(
        "--no-follow",
        action="store_true",
        help="don't open the iframes — no requests beyond the page itself",
    )
    parser.add_argument(
        "--timeout", type=float, default=20.0, help="request timeout, seconds (default: 20)"
    )
    parser.add_argument(
        "--proxy",
        help="proxy URL, comma-separated list, or @file (default: $PROXY_URL)",
    )
    parser.add_argument("--json", action="store_true", help="print JSON instead of plain text")
    parser.add_argument(
        "--show-html", action="store_true", help="also print each matched <iframe> tag"
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    html = (
        args.html_file.read_text(encoding="utf-8", errors="replace") if args.html_file else None
    )

    try:
        fetcher = _fetcher(args)
    except ImportError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    try:
        with fetcher:
            result = resolve(
                args.url, fetcher=fetcher, follow=not args.no_follow, html=html
            )
    except FetchError as exc:
        print(f"fetch failed: {exc}", file=sys.stderr)
        return 2

    if not result.players:
        print("no ashdi.vip iframes found", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(result.to_dict(include_html=args.show_html), ensure_ascii=False, indent=2))
    else:
        _print_plain(result, show_html=args.show_html)

    if args.no_follow:
        return 0
    return 0 if result.streams else 1


def _fetcher(args: argparse.Namespace):
    """The default requester. Only the CLI needs one, so it's an optional extra."""
    try:
        from httpkit import build_fetcher, resolve_pool
    except ImportError as exc:  # pragma: no cover
        raise ImportError(
            "the CLI needs a requester: install ashdi-finder[cli], or use the "
            "library with a fetcher of your own"
        ) from exc

    return build_fetcher(proxy=resolve_pool(args.proxy), timeout=args.timeout)


def _print_plain(result: ResolveResult, show_html: bool) -> None:
    for player in result.players:
        print(player.url)
        if show_html and player.html:
            print(f"  [{player.attr}] {player.html}")
        if player.error:
            print(f"  fetch failed: {player.error}", file=sys.stderr)
            continue
        for stream in player.streams:
            print(f"  {stream.label + '  ' if stream.label else ''}{stream.url}")


if __name__ == "__main__":
    raise SystemExit(main())
