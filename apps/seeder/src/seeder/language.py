"""What language a stream is in, and how we come to know it.

Nothing in the stream says. These HLS playlists carry no `LANGUAGE` attribute
and no per-stream language tag — checked, on the real files — and a dub's name
is a studio ("Le Doyen"), a technique ("Багатоголосий закадровий") or both. None
of that is a language.

The site knows, though: a site like these publishes in one language, and its
crawler is where that is written down. So the answer comes from
`Source.language`, found by the source name the record was crawled from.

One exception, and it is a real one: a track called «Оригінал» is not in the
site's language — it is whatever the film was made in, which the crawl has no
way of knowing. Those are marked as original and left without a language rather
than being labelled Ukrainian, which would be a lie that filters would repeat.
"""

import re
from typing import Any, Mapping

from crawlers.source import UnknownSource, get

# «Оригінал», «Оригінальна доріжка», "Original" — the track that was never
# dubbed. Anchored to a word so "Оригінальна озвучка від студії X" doesn't
# escape it while "Original Six" (a title, hypothetically) can't sneak in.
ORIGINAL = re.compile(r"\b(оригінал\w*|original\w*)\b", re.IGNORECASE)


def of_source(name: str | None) -> str | None:
    """The language that source publishes in, or None if it never said.

    Through `get` rather than the registry dict: the registry fills itself the
    first time somebody asks for a source by name, and reading it directly finds
    it empty.
    """
    if not name:
        return None
    try:
        return getattr(get(name), "language", None)
    except UnknownSource:
        # A file crawled by something that has since been renamed or removed.
        # Not knowing is a fine answer; inventing a language is not.
        return None


def is_original(dub: str | None) -> bool:
    return bool(dub and ORIGINAL.search(dub))


def spoken(
    record: Mapping[str, Any],
    facts: Mapping[str, Any],
    dub: str | None,
    fallback: str | None = None,
) -> tuple[str | None, bool]:
    """`(language, original)` for one playable track.

    `fallback` is the seeder's `--language`, for files written before any of
    this existed and which name no source. It is a last resort on purpose: a
    guess made at the keyboard is worth less than a fact written in a crawler.
    """
    if is_original(dub):
        return None, True

    stated = record.get("audio_language") or facts.get("audio_language")
    if stated:
        return str(stated), False

    named = record.get("source") or facts.get("source")
    return of_source(named) or fallback, False
