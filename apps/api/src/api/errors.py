"""Domain errors.

Services raise these; the HTTP layer turns them into status codes. That way a
service never imports FastAPI and can be called from a script, a task or a test
without pretending to be a request.
"""


class CatalogueError(Exception):
    """Base for everything this API refuses to do."""


class NotFound(CatalogueError):
    pass


class Conflict(CatalogueError):
    pass


class Invalid(CatalogueError):
    pass
