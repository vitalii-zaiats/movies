"""Put an IMDb id on every crawled title.

IMDb has no public API, and its pages are closed to scripts: a plain request
answers `202` with a "JavaScript is disabled" interstitial, so the `ld+json` on a
title page is a browser's to read and not ours. What IMDb does publish is the
datasets at https://datasets.imdbws.com — the sanctioned route, no key, refreshed
daily — and that is what this reads.

    crawl kinoukr --details  ->  jsonl  ->  match-imdb  ->  jsonl + imdb_id

Matching is by name and year, and then *checked* rather than trusted: the crawl
already recorded what the source claimed the IMDb rating and vote count were, so
a candidate whose rating agrees is a candidate that is almost certainly the same
film. Where the check can't be made and two candidates remain, the record is left
alone — a wrong id is worse than a missing one, because nothing downstream can
tell it apart from a right one.
"""

import argparse
import gzip
import json
import re
import sys
import unicodedata
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import Any

BASICS = "title.basics.tsv.gz"
RATINGS = "title.ratings.tsv.gz"
AKAS = "title.akas.tsv.gz"

# What a film or a series can be over there. Everything else — episodes, video
# games, adverts — would only add noise to a name that already matched.
KEPT_TYPES = frozenset({"movie", "tvMovie", "tvSeries", "tvMiniSeries", "short", "video"})

# Which of those a kinoukr `kind` should look like, when it says anything.
SHAPES = {
    "film": frozenset({"movie", "tvMovie", "video", "short"}),
    "cartoon": frozenset({"movie", "tvMovie", "video", "short"}),
    "series": frozenset({"tvSeries", "tvMiniSeries"}),
    "cartoon-series": frozenset({"tvSeries", "tvMiniSeries"}),
    "anime": frozenset({"movie", "tvMovie", "tvSeries", "tvMiniSeries", "video", "short"}),
}

# A title that arrives as "Забутий / Ніч спогадів" is two names for one film.
ALTERNATES = re.compile(r"\s+/\s+")


@dataclass(frozen=True, slots=True)
class Candidate:
    tconst: str
    kind: str
    year: int | None
    rating: float | None = None
    votes: int | None = None


def normalize(title: str) -> str:
    """A name reduced to what two sources can be expected to agree on.

    Case, accents and punctuation are where the same film is written down
    differently; letters and digits are where it isn't.
    """
    folded = unicodedata.normalize("NFKD", title.casefold())
    stripped = "".join(char for char in folded if not unicodedata.combining(char))
    return " ".join("".join(char if char.isalnum() else " " for char in stripped).split())


def names_of(record: dict[str, Any]) -> list[str]:
    """Every name this record could be found under, best first.

    The original title leads: it's the one IMDb indexes as its own, while the
    Ukrainian one only exists over there if somebody added it as an AKA.
    """
    raw = [record.get("original_title") or "", record.get("title") or ""]
    names = []
    for value in raw:
        for part in ALTERNATES.split(value):
            name = normalize(part)
            if name and name not in names:
                names.append(name)
    return names


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def rows(path: Path) -> Iterator[list[str]]:
    """IMDb's TSVs: no quoting, `\\N` for null, one header line."""
    with gzip.open(path, "rt", encoding="utf-8", newline="") as handle:
        next(handle, None)
        for line in handle:
            yield line.rstrip("\n").split("\t")


def year_of(value: str) -> int | None:
    return int(value) if value.isdigit() else None


def collect(datasets: Path, wanted: set[str]) -> dict[str, list[Candidate]]:
    """Candidates for the names we're actually looking for, and no others.

    The alternative is an index of eleven million titles, which is minutes of
    work and gigabytes of memory to answer eight thousand questions.
    """
    found: dict[str, list[Candidate]] = {}
    scanned = 0

    for row in rows(datasets / BASICS):
        scanned += 1
        if len(row) < 9 or row[1] not in KEPT_TYPES:
            continue

        for name in {normalize(row[2]), normalize(row[3])}:
            if name in wanted:
                found.setdefault(name, []).append(
                    Candidate(tconst=row[0], kind=row[1], year=year_of(row[5]))
                )

    print(f"read {scanned:,} titles, kept {sum(len(v) for v in found.values()):,}", file=sys.stderr)
    return found


def with_akas(datasets: Path, wanted: set[str], found: dict[str, list[Candidate]]) -> None:
    """The localized names, so a Ukrainian title can find its film too.

    Optional because the file is half a gigabyte and only pays off for the
    titles whose original name the crawl never recorded.
    """
    path = datasets / AKAS
    if not path.is_file():
        print(f"no {AKAS} — skipping localized names", file=sys.stderr)
        return

    known = {candidate.tconst for group in found.values() for candidate in group}
    added = 0

    for row in rows(path):
        if len(row) < 3:
            continue
        name = normalize(row[2])
        if name not in wanted:
            continue
        # The year lives in basics, not here; an aka only points at the title.
        if any(candidate.tconst == row[0] for candidate in found.get(name, ())):
            continue
        found.setdefault(name, []).append(Candidate(tconst=row[0], kind="", year=None))
        if row[0] not in known:
            added += 1

    print(f"localized names added {added:,} more candidates", file=sys.stderr)


def rate(datasets: Path, found: dict[str, list[Candidate]]) -> dict[str, tuple[float, int]]:
    wanted = {candidate.tconst for group in found.values() for candidate in group}
    ratings: dict[str, tuple[float, int]] = {}

    for row in rows(datasets / RATINGS):
        if len(row) >= 3 and row[0] in wanted:
            ratings[row[0]] = (float(row[1]), int(row[2]))

    return ratings


def score(record: dict[str, Any], candidate: Candidate, name_rank: int) -> int:
    """How much this candidate looks like this record. Higher wins."""
    points = 0

    year = record.get("year")
    if year and candidate.year:
        distance = abs(candidate.year - year)
        if distance == 0:
            points += 4
        elif distance == 1:
            points += 2  # release years disagree across countries all the time
        else:
            return -1  # not the same title, whatever the name says

    # The original title is the stronger evidence; a localized one is a hint.
    points += 2 if name_rank == 0 else 0

    shape = SHAPES.get(str(record.get("kind") or ""))
    if shape and candidate.kind:
        points += 2 if candidate.kind in shape else -2

    # The check that actually settles it: the crawl wrote down what the source
    # said IMDb thought, before we ever looked.
    ours = record.get("imdb")
    if ours is not None and candidate.rating is not None:
        if abs(candidate.rating - ours) <= 0.1:
            points += 5
        elif abs(candidate.rating - ours) <= 0.3:
            points += 1
        else:
            points -= 3

    return points


def match(
    record: dict[str, Any],
    found: dict[str, list[Candidate]],
    ratings: dict[str, tuple[float, int]],
) -> tuple[str | None, str]:
    """The one id this record deserves, and why — or nothing, and why not."""
    pool: list[tuple[int, Candidate]] = []

    for rank, name in enumerate(names_of(record)):
        for candidate in found.get(name, ()):
            rating = ratings.get(candidate.tconst)
            filled = (
                candidate
                if rating is None
                else Candidate(candidate.tconst, candidate.kind, candidate.year, *rating)
            )
            pool.append((rank, filled))

    if not pool:
        return None, "no candidate"

    scored = sorted(
        ((score(record, candidate, rank), candidate) for rank, candidate in pool),
        key=lambda pair: pair[0],
        reverse=True,
    )
    best, runner = scored[0], scored[1] if len(scored) > 1 else None

    if best[0] < 4:
        return None, "too weak"
    # Two candidates that fit equally well are two films we can't tell apart.
    if runner is not None and runner[0] == best[0] and runner[1].tconst != best[1].tconst:
        return None, "ambiguous"

    ours = record.get("imdb")
    confirmed = (
        ours is not None
        and best[1].rating is not None
        and abs(best[1].rating - ours) <= 0.1
    )
    return best[1].tconst, "rating" if confirmed else "name and year"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="match-imdb",
        description="Put an IMDb id on crawled titles, using IMDb's own datasets",
    )
    parser.add_argument("path", type=Path, help="output of `crawl <source> --details`")
    parser.add_argument(
        "--datasets",
        type=Path,
        default=Path("data/imdb"),
        help="where title.basics.tsv.gz and friends live (default: data/imdb)",
    )
    parser.add_argument(
        "--akas", action="store_true", help=f"also read {AKAS} — slower, finds localized names"
    )
    parser.add_argument(
        "--write", action="store_true", help="rewrite the file; without it, only report"
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not args.path.is_file():
        print(f"error: no such file: {args.path}", file=sys.stderr)
        return 2
    for name in (BASICS, RATINGS):
        if not (args.datasets / name).is_file():
            print(
                f"error: {args.datasets / name} is missing — download it from "
                f"https://datasets.imdbws.com/{name}",
                file=sys.stderr,
            )
            return 2

    records = read_jsonl(args.path)
    wanted = {name for record in records for name in names_of(record)}
    print(f"{len(records):,} records, {len(wanted):,} distinct names to look for", file=sys.stderr)

    found = collect(args.datasets, wanted)
    if args.akas:
        with_akas(args.datasets, wanted, found)
    ratings = rate(args.datasets, found)

    reasons: dict[str, int] = {}
    matched = 0

    for record in records:
        tconst, why = match(record, found, ratings)
        reasons[why] = reasons.get(why, 0) + 1
        if tconst:
            matched += 1
            record["imdb_id"] = tconst
            record["imdb_match"] = why

    if args.write:
        args.path.write_text(
            "\n".join(json.dumps(record, ensure_ascii=False) for record in records) + "\n",
            encoding="utf-8",
        )

    share = matched / len(records) * 100 if records else 0
    print(f"\nmatched {matched:,} of {len(records):,} ({share:.1f}%)")
    for why, count in sorted(reasons.items(), key=lambda pair: -pair[1]):
        print(f"  {why:<16} {count:>6,}")
    if not args.write:
        print("\n(dry run — pass --write to keep the ids)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
