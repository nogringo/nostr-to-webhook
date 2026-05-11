# syntax=docker/dockerfile:1

FROM dart:stable AS build
WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY bin ./bin
COPY lib ./lib
RUN dart pub get --offline
RUN dart compile exe bin/nostr_to_webhook.dart -o /app/server

FROM debian:stable-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/server /app/server
ENTRYPOINT ["/app/server"]
