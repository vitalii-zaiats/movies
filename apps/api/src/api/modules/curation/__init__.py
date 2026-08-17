"""The editorial layer: what the home screen shows, and what it looks like.

Until now the client worked this out for itself — it asked for every show, read
each one's `total`, sorted by size and put the biggest in the hero. That's a
guess dressed as a layout, and it costs a request per show. This module replaces
it with a decision somebody made: an ordered list of sections, each pointing at
a show or a public playlist, each able to carry its own artwork.

Two tables:

* `sections` — the rows of the home screen, in order.
* `artwork`  — an image at one *placement* (hero, tile, poster, square, logo)
  attached to a show, a playlist or a section. Same picture in five shapes is
  the normal case, which is why placement is a column and not five columns.

The direction of dependency is downwards only: curation reads the catalogue and
playlists, and neither of them knows this module exists.
"""
