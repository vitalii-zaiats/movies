# Build from the repo root:  docker build -f web/Dockerfile -t kino-web .
#
# The only Dockerfile here that isn't Python. Node builds the bundle; nginx
# serves it and fronts the API and the socket so the app stays same-origin.

FROM node:24-alpine AS builder

WORKDIR /src

# Manifests first: dependencies only reinstall when they actually change.
COPY web/package.json web/package-lock.json ./
RUN npm ci

COPY web/ ./
RUN npm run build


FROM nginx:1.29-alpine

COPY --from=builder /src/dist /usr/share/nginx/html
COPY web/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1
