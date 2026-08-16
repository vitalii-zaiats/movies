# Build from the repo root:  docker build -f apps/proxy/Dockerfile -t kino-proxy .
#
# An open proxy by default. Inside a compose network that's fine; anywhere it
# can be reached from outside, pass --allow-host.

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY . .

RUN uv sync --frozen --no-dev --no-editable --package proxy


FROM python:3.13-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv

RUN useradd --system --uid 10001 app && chown -R app /app
USER app

EXPOSE 8001

CMD ["proxy", "--host", "0.0.0.0", "--port", "8001"]
