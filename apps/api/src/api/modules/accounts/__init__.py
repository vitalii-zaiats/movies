"""Who is asking.

Every request has a user. If the caller brought no token we mint a guest and
hand one back, so "watch this, remember where I stopped" works before anyone has
typed an email. A guest is a real row with real history — claiming it later
attaches an email and a password to *that* row, which is why nothing is lost in
the process.
"""
