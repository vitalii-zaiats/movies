# Build from the repo root:  docker build -f apps/api/Dockerfile -t kino-api .
#
# `uv sync --package api` installs this service and its dependency closure and
# nothing else — no crawlers, no hub, no other member's code. The workspace only
# exists in the builder stage; what ships is a plain venv.

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY . .

# --no-editable installs real wheels, so the venv doesn't reference the sources.
# The build happens at /app because a venv's console scripts hard-code their own
# absolute path in a shebang — move the venv and they stop resolving.
RUN uv sync --frozen --no-dev --no-editable --package api


FROM python:3.13-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv

# Migrations live outside the package, so they're copied in as data.
COPY apps/api/alembic.ini ./
COPY apps/api/migrations ./migrations

RUN useradd --system --uid 10001 app && chown -R app /app
USER app

EXPOSE 8020

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request as r; r.urlopen('http://127.0.0.1:8020/health')"

CMD ["api", "--host", "0.0.0.0", "--port", "8020"]
