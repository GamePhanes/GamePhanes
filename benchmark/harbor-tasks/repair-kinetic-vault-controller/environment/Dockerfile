FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GODOT_VERSION=4.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl libasound2 libfontconfig1 libgl1 libpulse0 \
        libudev1 libwayland-client0 libxcursor1 libxi6 libxinerama1 \
        libxrandr2 python3 unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --location --retry 3 \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
        --output /tmp/godot.zip \
    && unzip -q /tmp/godot.zip -d /usr/local/bin \
    && mv /usr/local/bin/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

COPY project /app/
WORKDIR /app

ENV GODOT_BIN=/usr/local/bin/godot
