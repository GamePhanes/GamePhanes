FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

ARG GODOT_VERSION=4.6.1
ARG TARGETARCH

RUN apt-get -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 -o Acquire::Retries=3 update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 \
    && GODOT_ARCH="$(if [ "$TARGETARCH" = amd64 ]; then echo x86_64; else echo arm64; fi)" \
    && curl --fail --silent --show-error --location --connect-timeout 30 --max-time 300 --retry 3 --retry-all-errors -o /tmp/godot.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.${GODOT_ARCH}.zip" \
    && unzip -q /tmp/godot.zip -d /opt/godot \
    && mv "/opt/godot/Godot_v${GODOT_VERSION}-stable_linux.${GODOT_ARCH}" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -rf /var/lib/apt/lists/* /tmp/godot.zip /opt/godot

COPY tests/test.sh /grader/tests/test.sh
COPY tests/status_bars_probe.gd /grader/tests/status_bars_probe.gd
COPY project.godot /grader/baseline/project.godot
COPY assets/ui/battle/battle_status_fill_hp.svg /grader/baseline/assets/ui/battle/battle_status_fill_hp.svg
COPY assets/ui/battle/battle_status_fill_mp.svg /grader/baseline/assets/ui/battle/battle_status_fill_mp.svg

RUN chmod +x /grader/tests/test.sh

RUN printf '%s\n' \
        Main.tscn \
        assets/ui/battle/battle_status_fill_hp.svg \
        assets/ui/battle/battle_status_fill_mp.svg \
        project.godot \
        scripts/status_bars.gd \
        > /grader/baseline/files.txt

WORKDIR /workspace/desktop
ENTRYPOINT ["/grader/tests/test.sh"]
