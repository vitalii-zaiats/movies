"""What a user did: where they stopped, what they finished, what they made.

Two tables with two different jobs. `watch_progress` is *state* — one row per
user and episode, rewritten as the player reports in, which is what "continue
watching" reads. `activity_events` is *history* — append-only, one row per thing
that happened, which is what a feed reads and what any future recommendation or
"you watched this in March" needs.

Keeping them apart is the point. A heartbeat every ten seconds must not grow the
history table, and finishing an episode must not be something you can lose by
scrubbing backwards.
"""
