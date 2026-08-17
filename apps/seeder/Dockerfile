# Build from the repo root:  docker build -f apps/seeder/Dockerfile -t kino-seeder .
#
# A job, not a server. It needs the VOD service and the API to be up:
#   docker compose run --rm seed data/family-guy-streams.jsonl

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY . .

RUN uv sync --frozen --no-dev --no-editable --package seeder


FROM python:3.13-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv

RUN useradd --system --uid 10001 app && chown -R app /app
USER app

ENTRYPOINT ["seed-catalogue"]
