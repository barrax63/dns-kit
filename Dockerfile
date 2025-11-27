# =============================================================================
# Stage 1: download and verify
# =============================================================================
FROM debian:bookworm-slim AS builder

ARG TARGETARCH

ENV DNSCRYPT_PUBLIC_KEY="RWTk1xXqcTODeYttYMCMLo0YJHaFEHn7a3akqHlb/7QvIQXHVPxKbjB5"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates minisign jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN case "${TARGETARCH}" in \
        "amd64") echo "linux_amd64" > /tmp/platform ;; \
        "arm64") echo "linux_arm64" > /tmp/platform ;; \
        "arm")   echo "linux_arm" > /tmp/platform ;; \
        *)       echo "Unsupported: ${TARGETARCH}" && exit 1 ;; \
    esac

RUN PLATFORM=$(cat /tmp/platform) && \
    LATEST_URL="https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest" && \
    VERSION=$(curl -sL "$LATEST_URL" | jq -r '.tag_name') && \
    DOWNLOAD_URL=$(curl -sL "$LATEST_URL" | jq -r ".assets[] | select(.name | contains(\"${PLATFORM}\")) | select(.name | endswith(\".tar.gz\")) | .browser_download_url") && \
    echo "Downloading dnscrypt-proxy ${VERSION} for ${PLATFORM}..." && \
    curl -sL -o dnscrypt-proxy.tar.gz "$DOWNLOAD_URL" && \
    curl -sL -o dnscrypt-proxy.tar.gz.minisig "${DOWNLOAD_URL}.minisig" && \
    echo "$VERSION" > /tmp/version

RUN minisign -Vm dnscrypt-proxy.tar.gz -P "$DNSCRYPT_PUBLIC_KEY"

RUN PLATFORM=$(cat /tmp/platform) && \
    tar -xzf dnscrypt-proxy.tar.gz && \
    mv ${PLATFORM}/dnscrypt-proxy /build/dnscrypt-proxy && \
    chmod +x /build/dnscrypt-proxy

# =============================================================================
# Stage 2: Minimal runtime image
# =============================================================================
FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="dnscrypt-proxy" \
      org.opencontainers.image.description="DNS proxy with encryption support"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -d /opt/dnscrypt-proxy -s /usr/sbin/nologin dnscrypt

RUN mkdir -p /opt/dnscrypt-proxy /var/cache/dnscrypt-proxy \
    && chown -R dnscrypt:dnscrypt /opt/dnscrypt-proxy /var/cache/dnscrypt-proxy

WORKDIR /opt/dnscrypt-proxy

COPY --from=builder --chown=dnscrypt:dnscrypt /build/dnscrypt-proxy ./
COPY --from=builder /tmp/version ./version

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD nc -z 127.0.0.1 5053 || exit 1

USER dnscrypt

EXPOSE 5053/udp 5053/tcp

ENTRYPOINT ["/opt/dnscrypt-proxy/dnscrypt-proxy"]
CMD ["-config", "/config/dnscrypt-proxy.toml"]
