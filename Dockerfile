# syntax=docker/dockerfile:1

FROM dart:stable AS build
WORKDIR /app

# NDK's native-assets build hook compiles a Rust shared library via rustup +
# cargo, neither of which ship in dart:stable. The NDK package pins the exact
# toolchain in rust-toolchain.toml, so installing rustup with the stable
# default is enough — rustup auto-installs the pinned version on first use.
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --no-modify-path
ENV PATH=/root/.cargo/bin:$PATH

COPY pubspec.* ./
RUN dart pub get

COPY bin ./bin
COPY lib ./lib
RUN dart pub get --offline
RUN dart build cli --output /app/build

FROM debian:stable-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/build/bundle /app/bundle
ENTRYPOINT ["/app/bundle/bin/nostr_to_webhook"]
