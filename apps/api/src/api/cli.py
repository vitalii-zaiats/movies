"""`api-admin` — the shell side of the admin role, and of the home screen.

There's a chicken-and-egg problem in any system where only an admin can make an
admin. This is the egg: it talks to the database directly, so the first one can
exist before anyone has logged in.

    uv run --directory apps/api api-admin create me@example.com
    uv run --directory apps/api api-admin grant me@example.com
    uv run --directory apps/api api-admin list

    uv run --directory apps/api api-admin sync-vods
    uv run --directory apps/api api-admin poster family-guy https://.../poster.jpg
    uv run --directory apps/api api-admin sections list
    uv run --directory apps/api api-admin sections add "Best of 2026" --playlist "Best of 2026"
    uv run --directory apps/api api-admin sections move 7 0

This file decides nothing: every command below is one call into the service graph
that `api.core.services` wires, the same one the HTTP routes use. Editing the
home screen from a terminal and editing it over the API are the same operation
with different presentation on top.
"""

import argparse
import asyncio
import getpass

from sqlalchemy import select

from api.clients.vod import VodClient
from api.core.database import Session, engine
from api.core.services import Services, services
from api.errors import CatalogueError
from api.modules.accounts.models import Role
from api.modules.accounts.service import AccountService
from api.modules.curation.models import Section, SectionKind
from api.modules.playlists.models import Playlist


async def _create(email: str, password: str | None, admin: bool) -> str:
    # Prompted rather than passed as a flag: an argument ends up in the shell
    # history and in `ps`.
    password = password or getpass.getpass("password: ")
    async with Session() as session:
        user = await AccountService(session).register(
            email=email, password=password, role=Role.admin if admin else Role.user
        )
        return f"created {user.email} ({user.role.value}) — {user.public_id}"


async def _set_role(email: str, role: Role) -> str:
    async with Session() as session:
        accounts = AccountService(session)
        user = await accounts.users.by_email(email)
        if user is None:
            raise CatalogueError(f"no user {email!r}")
        await accounts.set_role(user.public_id, role)
        return f"{user.email} is now {role.value}"


async def _list() -> str:
    async with Session() as session:
        users, total = await AccountService(session).all_users(limit=200)
        lines = [
            f"{user.role.value:<5}  {'guest' if user.is_guest else 'member':<6}  "
            f"{user.email or user.display_name}"
            for user in users
        ]
        return "\n".join([*lines, f"— {total} user(s)"])


async def _sync_vods(since: int | None) -> str:
    """Walk the VOD service and file whatever is new.

    The same call the seeder makes over HTTP when it finishes registering, and
    the same one a cron would make — here so it can be run by hand when
    something looks out of step.
    """
    async with services() as api, VodClient() as vods:
        report = await api.catalogue.sync_vods(vods, since=since)
        return (
            f"{report.created} new, {report.updated} updated, "
            f"{report.skipped} skipped — now at vod {report.cursor}"
        )


async def _poster(key: str, url: str | None) -> str:
    """Artwork a person chose, which outranks whatever a crawl found."""
    async with services() as api:
        show = await api.catalogue.set_poster(key, url)
        return f"{show.key}: {show.poster or '(no poster)'}"


async def _sections(args: argparse.Namespace) -> str:
    """Every section command, over one wired session."""
    async with services() as api:
        curation = api.curation

        match args.action:
            case "add":
                section = await curation.create_section(
                    kind=SectionKind(args.kind),
                    title=args.title,
                    kicker=args.kicker,
                    link=args.link,
                    show_id=await _show_id(api, args.show),
                    playlist_id=await _playlist_id(api, args.playlist),
                    item_limit=args.limit,
                    visible=not args.hidden,
                )
                return _line(section)

            case "move":
                order = [section.id for section in await curation.all_sections()]
                if args.section_id not in order:
                    raise CatalogueError(f"no section {args.section_id}")
                order.remove(args.section_id)
                # Clamped rather than refused: "put it last" is a position past
                # the end, and that's a reasonable thing to type.
                order.insert(max(0, min(args.position, len(order))), args.section_id)
                await curation.reorder_sections(order)

            case "publish" | "hide":
                await curation.update_section(
                    args.section_id, {"visible": args.action == "publish"}
                )

            case "rm":
                await curation.delete_section(args.section_id)

        rows = await curation.all_sections()
        return "\n".join(_line(section) for section in rows) or "no sections yet"


async def _playlist_id(api: Services, name: str | None) -> int | None:
    """By name, because that's what a person has in front of them."""
    if not name:
        return None
    playlist = await api.session.scalar(select(Playlist).where(Playlist.name == name))
    if playlist is None:
        raise CatalogueError(f"no playlist named {name!r}")
    return playlist.id


async def _show_id(api: Services, key: str | None) -> int | None:
    return (await api.catalogue.show(key)).id if key else None


def _line(section: Section) -> str:
    if section.playlist is not None:
        source = f"playlist: {section.playlist.name}"
    elif section.show is not None:
        source = f"show: {section.show.key}"
    else:
        source = "—"
    return (
        f"{section.position:>2}  {section.id:>3}  {'' if section.visible else 'hidden':<6}  "
        f"{section.kind.value:<6}  {section.title[:32]:<32}  {source}"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="api-admin", description="User administration")
    commands = parser.add_subparsers(dest="command", required=True)

    create = commands.add_parser("create", help="a new account, claimed and admin by default")
    create.add_argument("email")
    create.add_argument("--password", default=None, help="prompted for if omitted")
    create.add_argument("--plain", action="store_true", help="an ordinary user, not an admin")

    grant = commands.add_parser("grant", help="make an existing account an admin")
    grant.add_argument("email")

    revoke = commands.add_parser("revoke", help="take the admin role away")
    revoke.add_argument("email")

    commands.add_parser("list", help="who exists")

    sync = commands.add_parser("sync-vods", help="read the VOD service from where we left off")
    sync.add_argument(
        "--since", type=int, default=None, help="rewind and read the list again from this id"
    )

    poster = commands.add_parser("poster", help="set or clear a show's artwork")
    poster.add_argument("key", help="the show key, as in /shows/<key>")
    poster.add_argument("url", nargs="?", default=None, help="omit to clear it")

    sections = commands.add_parser("sections", help="the rows of the home screen")
    actions = sections.add_subparsers(dest="action", required=True)

    actions.add_parser("list", help="in the order they're drawn")

    add = actions.add_parser("add", help="a new row, at the end")
    add.add_argument("title")
    add.add_argument(
        "--kind", default="rail", choices=[kind.value for kind in SectionKind],
        help="how it's drawn (default: rail)",
    )
    add.add_argument("--playlist", help="fill it from this playlist, by name — must be public")
    add.add_argument("--show", help="fill it from this show, by key")
    add.add_argument("--kicker", default=None, help="the small line above the title")
    add.add_argument("--link", default=None, help="where its 'view all' goes")
    add.add_argument("--limit", type=int, default=14, help="items drawn (default: 14)")
    add.add_argument("--hidden", action="store_true", help="create it unpublished")

    move = actions.add_parser("move", help="put a row at a position")
    move.add_argument("section_id", type=int)
    move.add_argument("position", type=int)

    publish = actions.add_parser("publish", help="put a row back on the home screen")
    publish.add_argument("section_id", type=int)

    hide = actions.add_parser("hide", help="take a row off the home screen")
    hide.add_argument("section_id", type=int)

    remove = actions.add_parser("rm", help="delete a row")
    remove.add_argument("section_id", type=int)

    args = parser.parse_args(argv)

    match args.command:
        case "create":
            work = _create(args.email, args.password, admin=not args.plain)
        case "grant":
            work = _set_role(args.email, Role.admin)
        case "revoke":
            work = _set_role(args.email, Role.user)
        case "sync-vods":
            work = _sync_vods(args.since)
        case "poster":
            work = _poster(args.key, args.url)
        case "sections":
            work = _sections(args)
        case _:
            work = _list()

    async def run() -> str:
        try:
            return await work
        finally:
            await engine.dispose()

    try:
        print(asyncio.run(run()))
    except CatalogueError as exc:
        parser.exit(1, f"{exc}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
