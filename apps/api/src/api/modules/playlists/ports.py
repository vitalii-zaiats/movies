"""What this module needs from the rest of the app, stated by this module.

The port lives with the *consumer*, not the provider — that's the whole trick.
`PlaylistService` says "I need something I can tell that a thing happened", and
`ActivityService` happens to satisfy it. Nothing here imports activity, and
nothing in activity knows playlists exist; `deps.py` is the only file that has
met both.

Why this seam and not every seam: recording an event is a *side effect*, and
side effects are the things that later want to be queued, batched, sent
elsewhere or dropped. A read of an episode inside the same transaction is not —
`playlist_items.episode_id` is a foreign key with a real cascade, so pretending
the two modules are strangers would be a fiction the schema contradicts.
"""

from typing import Any, Protocol


class ActivityRecorder(Protocol):
    """Somewhere to put "this happened", satisfied structurally.

    `event` is a plain string on purpose. The column behind it is a `String`
    precisely so a module can name its own events without a migration and
    without a shared enum that every module has to import to add a line to.
    """

    async def record(
        self,
        user_id: int,
        event: str,
        *,
        subject_type: str | None = None,
        subject_id: int | None = None,
        payload: dict[str, Any] | None = None,
    ) -> Any: ...
