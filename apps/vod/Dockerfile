# Build from the repo root:  docker build -f apps/vod/Dockerfile -t kino-vod .
#
# Serves HTTP for players and gRPC for the API. Its SQLite file belongs on a
# volume: mount one at /data and point VOD_DB at it.

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY . .

RUN uv sync --frozen --no-dev --no-editable --package vod


FROM python:3.13-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    VOD_DB=/data/vod.db

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv

RUN useradd --system --uid 10001 app && mkdir -p /data && chown -R app /app /data
USER app
VOLUME ["/data"]

EXPOSE 8030 50051

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request as r; r.urlopen('http://127.0.0.1:8030/health')"

CMD ["vod", "--host", "0.0.0.0", "--http-port", "8030", "--grpc-port", "50051"]
