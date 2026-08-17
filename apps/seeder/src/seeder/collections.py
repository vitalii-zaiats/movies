"""Editorial playlists, built out of what the crawler knows.

The catalogue stores a title, a poster and a stream. Genres, years and ratings
never reach it — they live in the crawl — so the rule that makes "Best comedies"
is applied here, over the jsonl, and the API is only told the result: a playlist,
in order, published.

    crawl kinoukr --details  ->  jsonl  ->  seed-collections  ->  api (HTTP)

Publishing is an admin act — a public playlist is the one the whole install sees
— so this signs in first and works as that account.
"""

import argparse
import asyncio
import os
import sys
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx

from seeder.crawled import CrawledItem, read

DEFAULT_API = os.environ.get("CATALOGUE_URL", "http://127.0.0.1:8020")
DEFAULT_SIZE = 30

# A 9.9 that four people voted on is not the best anything.
MIN_VOTES = 2_000


@dataclass(frozen=True, slots=True)
class Rule:
    """One playlist: what belongs in it, best first."""

    name: str
    year: int | None = None
    since: int | None = None
    genre: str | None = None
    kind: str | None = None
    votes: int = MIN_VOTES

    def matches(self, item: CrawledItem) -> bool:
        year = item.get("year")
        if self.year is not None and year != self.year:
            return False
        if self.since is not None and (year is None or year < self.since):
            return False
        if self.genre is not None and self.genre not in (item.get("genres") or []):
            return False
        if self.kind is not None and item.get("kind") != self.kind:
            return False
        return item.get("imdb") is not None and (item.get("imdb_votes") or 0) >= self.votes


# The house selection. Years first because they date, then the genres people
# actually browse by, then the two shapes the catalogue keeps apart.
RULES = (
    Rule("Best of 2026", year=2026, votes=500),
    Rule("Best of 2025", year=2025),
    Rule("Best of 2024", year=2024),
    Rule("Best comedies", genre="comedy"),
    Rule("Best thrillers", genre="thriller"),
    Rule("Best sci-fi", genre="sci-fi"),
    Rule("Best horror", genre="horror"),
    Rule("Best crime", genre="crime"),
    Rule("Best drama", genre="drama"),
    Rule("Best animation", genre="cartoon", votes=500),
    Rule("Best documentaries", genre="documentary", votes=500),
    Rule("Best series", kind="series"),
    Rule("Recent comedies", genre="comedy", since=2023, votes=500),
    Rule("Recent horror", genre="horror", since=2023, votes=500),
)


def ranked(items: Sequence[CrawledItem], rule: Rule, size: int) -> list[CrawledItem]:
    """The rule's matches, best first. Votes break a tie, because they say how
    much a rating is worth."""
    matched = [item for item in items if rule.matches(item)]
    matched.sort(key=lambda item: (item.get("imdb") or 0, item.get("imdb_votes") or 0), reverse=True)
    return matched[:size]


class Editor:
    """The API, as an admin sees it. Sessions ride in the cookie jar."""

    def __init__(self, base_url: str, timeout: float = 60.0) -> None:
        self._base = base_url.rstrip("/")
        self._client = httpx.AsyncClient(timeout=timeout)

    async def __aenter__(self) -> "Editor":
        return self

    async def __aexit__(self, *_: object) -> None:
        await self._client.aclose()

    async def _call(self, method: str, path: str, **kwargs: Any) -> Any:
        response = await self._client.request(method, f"{self._base}{path}", **kwargs)
        response.raise_for_status()
        return None if response.status_code == 204 else response.json()

    async def sign_in(self, email: str, password: str) -> str:
        body = await self._call(
            "POST", "/auth/login", json={"email": email, "password": password}
        )
        return str(body["user"]["email"])

    async def episode_ids(self, page_size: int = 200) -> dict[str, int]:
        """Every episode's id, by the URL it was crawled from.

        One pass over the catalogue instead of a lookup per item: the whole point
        of a collection is that it names a lot of them.
        """
        by_url: dict[str, int] = {}
        offset = 0
        while True:
            page = await self._call(
                "GET", "/episodes", params={"limit": page_size, "offset": offset}
            )
            for episode in page["items"]:
                by_url[episode["source_url"]] = episode["id"]
            offset += page_size
            if offset >= page["total"]:
                return by_url

    async def playlists(self) -> dict[str, int]:
        # An admin asking for what's visible is shown everything, which is what
        # makes "does this list already exist" answerable.
        rows = await self._call("GET", "/playlists", params={"scope": "visible"})
        return {row["name"]: row["id"] for row in rows}

    async def delete(self, playlist_id: int) -> None:
        await self._call("DELETE", f"/playlists/{playlist_id}")

    async def build(self, name: str, episode_ids: Iterable[int]) -> int:
        playlist = await self._call("POST", "/playlists", json={"name": name})
        for episode_id in episode_ids:
            await self._call(
                "POST", f"/playlists/{playlist['id']}/items", json={"episode_id": episode_id}
            )
        # Published last, so a half-built list is never the one on the home page.
        await self._call(
            "PATCH", f"/playlists/{playlist['id']}", json={"visibility": "public"}
        )
        return int(playlist["id"])


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="seed-collections",
        description="Build editorial playlists from a crawl and publish them",
    )
    parser.add_argument("path", type=Path, help="output of `crawl <source> --details`")
    parser.add_argument("--api", default=DEFAULT_API, help=f"default: {DEFAULT_API}")
    parser.add_argument("--email", required=True, help="an admin account")
    parser.add_argument(
        "--password",
        default=os.environ.get("CATALOGUE_PASSWORD"),
        help="default: $CATALOGUE_PASSWORD",
    )
    parser.add_argument(
        "--size", type=int, default=DEFAULT_SIZE, help=f"titles per list (default: {DEFAULT_SIZE})"
    )
    parser.add_argument(
        "--replace", action="store_true", help="rebuild lists that already exist by name"
    )
    return parser


async def seed(args: argparse.Namespace) -> int:
    items = list(read(args.path))

    async with Editor(args.api) as editor:
        who = await editor.sign_in(args.email, args.password)
        print(f"signed in as {who}", file=sys.stderr)

        by_url = await editor.episode_ids()
        existing = await editor.playlists()
        print(f"{len(items)} crawled titles, {len(by_url)} episodes in the catalogue\n")

        for rule in RULES:
            if rule.name in existing:
                if not args.replace:
                    print(f"{rule.name:22} exists — skipped (use --replace)")
                    continue
                await editor.delete(existing[rule.name])

            picked = ranked(items, rule, args.size)
            # A title the catalogue never got is not one we can queue.
            episode_ids = [by_url[item["url"]] for item in picked if item["url"] in by_url]
            if not episode_ids:
                print(f"{rule.name:22} nothing matched — skipped")
                continue

            await editor.build(rule.name, episode_ids)
            best = picked[0]
            print(
                f"{rule.name:22} {len(episode_ids):>3} titles"
                f"   top: {best.get('title')} ({best.get('year')}, imdb {best.get('imdb')})"
            )

    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not args.path.is_file():
        print(f"error: no such file: {args.path}", file=sys.stderr)
        return 2
    if not args.password:
        print("error: no password — pass --password or set $CATALOGUE_PASSWORD", file=sys.stderr)
        return 2

    try:
        return asyncio.run(seed(args))
    except httpx.HTTPStatusError as exc:
        detail = exc.response.json().get("detail", exc.response.text)
        print(f"error: {exc.request.url} said {exc.response.status_code}: {detail}", file=sys.stderr)
        return 2
    except httpx.HTTPError as exc:
        print(f"error: catalogue api unreachable ({exc}) — is it up?", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
