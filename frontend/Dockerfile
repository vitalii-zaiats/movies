# Build from the repo root:  docker build -f frontend/Dockerfile -t kino-frontend .
#
# Node builds the static site; nginx serves it and fronts the API, the media,
# the video and the socket, so the whole thing stays one origin.

FROM node:24-alpine AS builder

WORKDIR /src

# Manifests first: dependencies only reinstall when they actually change.
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
# `ssr: false`, so this is a static bundle and not a Node server — the whole
# reason the runtime image below is just nginx. The client seam is decided at
# build time: NUXT_PUBLIC_USE_MOCKS defaults to false, which is what puts the
# real API behind it.
RUN npm run generate


FROM nginx:1.29-alpine

COPY --from=builder /src/.output/public /usr/share/nginx/html
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1
