# syntax=docker/dockerfile:1

FROM dart:stable AS build
WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY bin ./bin
COPY lib ./lib
RUN dart pub get --offline
# `dart build cli` is required because NDK ships a native (Rust) shared library
# via Dart's native-assets build hooks, which `dart compile exe` does not support.
RUN dart build cli --output /app/build

FROM debian:stable-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/build/bundle /app/bundle
ENTRYPOINT ["/app/bundle/bin/nostr_to_webhook"]
