# Build from the repo root:  docker build -f apps/episode-resolver/Dockerfile -t kino-episode-resolver .
#
# A job, not a server:
#   docker run --rm -v "$PWD/data:/data" -e PROXY_URL=... kino-episode-resolver family-guy

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY . .

RUN uv sync --frozen --no-dev --no-editable --package episode-resolver


FROM python:3.13-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1

COPY --from=builder /app/.venv /app/.venv

RUN useradd --system --uid 10001 app && mkdir -p /data && chown -R app /app /data
USER app
VOLUME ["/data"]

WORKDIR /data

ENTRYPOINT ["resolve-episodes"]
CMD ["--keys"]
