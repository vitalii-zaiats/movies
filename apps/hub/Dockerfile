# Build from the repo root:  docker build -f apps/hub/Dockerfile -t kino-hub .
#
# Needs Redis: set REDIS_URL, or pass --redis.

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY . .

RUN uv sync --frozen --no-dev --no-editable --package hub


FROM python:3.13-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    REDIS_URL=redis://redis:6379/0

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv

RUN useradd --system --uid 10001 app && chown -R app /app
USER app

EXPOSE 8010

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request as r; r.urlopen('http://127.0.0.1:8010/health')"

CMD ["hub", "--host", "0.0.0.0", "--port", "8010"]
