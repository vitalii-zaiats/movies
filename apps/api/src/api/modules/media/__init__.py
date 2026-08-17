"""Files the admin uploaded, and the URLs they're served at.

Content-addressed: a file's name is the SHA-256 of its bytes, so uploading the
same banner twice is the same row and the same URL. That also makes every URL
immutable, which is what lets them be cached forever.

An artwork can point here or at somebody else's server — see
`modules/curation`. This module only stores bytes; it has no opinion about what
they're a banner *of*.
"""
