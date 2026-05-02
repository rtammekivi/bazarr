# syntax=docker/dockerfile:1

ARG NODE_VERSION=22
ARG ALPINE_VERSION=3.22

FROM node:${NODE_VERSION}-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM alpine:${ALPINE_VERSION}

RUN \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    cargo \
    libffi-dev \
    libpq-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev && \
  apk add --no-cache \
    ffmpeg \
    libxml2 \
    libxslt \
    mediainfo \
    python3 \
    py3-pip \
    p7zip \
    bash \
    git && \
  mkdir -p \
    /app/bazarr/bin \
    /app/bazarr/data/config \
    /app/bazarr/data/cache \
    /app/bazarr/data/log

WORKDIR /app/bazarr/bin

COPY requirements.txt postgres-requirements.txt ./

RUN \
  pip install --break-system-packages -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.22/ \
    -r requirements.txt \
    -r postgres-requirements.txt && \
  apk del build-dependencies

COPY bazarr.py ./
COPY libs ./libs
COPY custom_libs ./custom_libs
COPY bazarr ./bazarr
COPY migrations ./migrations
COPY --from=frontend-builder /frontend/build ./frontend/build

EXPOSE 6767

VOLUME ["/app/bazarr/data"]

ENV SZ_USER_AGENT="bazarr"
ENV PYTHONPATH="/app/bazarr/bin/custom_libs:/app/bazarr/bin/libs:/app/bazarr/bin/bazarr:/app/bazarr/bin"

CMD ["python3", "bazarr.py", "--no-update", "--config", "/app/bazarr/data"]
