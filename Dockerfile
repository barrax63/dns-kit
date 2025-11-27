# =============================================================================
# DNSCrypt Proxy - Encrypted DNS Proxy
# =============================================================================
# Multi-stage build for minimal, secure runtime image
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Download and Verify
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

ARG TARGETARCH

# DNSCrypt official signing key for release verification
ENV DNSCRYPT_PUBLIC_KEY="RWTk1xXqcTODeYttYMCMLo0YJHaFEHn7a3akqHlb/7QvIQXHVPxKbjB5"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        minisign \
        jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Map Docker architecture to DNSCrypt release naming
RUN case "${TARGETARCH}" in \
        "amd64") echo "linux_x86_64" > /tmp/platform ;; \
        "arm64") echo "linux_arm64" > /tmp/platform ;; \
        "arm")   echo "linux_arm" > /tmp/platform ;; \
        *)       echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac

# Download latest release with signature verification
RUN PLATFORM=$(cat /tmp/platform) && \
    LATEST_URL="https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest" && \
    VERSION=$(curl -sL "$LATEST_URL" | jq -r '.tag_name') && \
    DOWNLOAD_URL=$(curl -sL "$LATEST_URL" | jq -r ".assets[] | select(.name | contains(\"${PLATFORM}\")) | select(.name | endswith(\".tar.gz\")) | .browser_download_url") && \
    echo "Downloading dnscrypt-proxy ${VERSION} for ${PLATFORM}..." && \
    curl -sL -o dnscrypt-proxy.tar.gz "$DOWNLOAD_URL" && \
    curl -sL -o dnscrypt-proxy.tar.gz.minisig "${DOWNLOAD_URL}.minisig" && \
    echo "$VERSION" > /tmp/version

# Verify cryptographic signature
RUN minisign -Vm dnscrypt-proxy.tar.gz -P "$DNSCRYPT_PUBLIC_KEY"

# Extract binary
RUN tar -xzf dnscrypt-proxy.tar.gz && \
    mv */dnscrypt-proxy /build/dnscrypt-proxy && \
    chmod +x /build/dnscrypt-proxy

# -----------------------------------------------------------------------------
# Stage 2: Minimal Runtime Image
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim

# OCI Image Specification Labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="dnscrypt-proxy" \
      org.opencontainers.image.description="DNS proxy with support for encrypted DNS protocols (DNSCrypt v2, DoH, ODoH)" \
      org.opencontainers.image.authors="Noah Nowak <nnowak@cryshell.com>" \
      org.opencontainers.image.url="https://github.com/barrax63/dns-kit" \
      org.opencontainers.image.source="https://github.com/barrax63/dns-kit" \
      org.opencontainers.image.documentation="https://github.com/barrax63/dns-kit/blob/main/README.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/debian:bookworm-slim"

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -r -d /opt/dnscrypt-proxy -s /usr/sbin/nologin dnscrypt

# Setup directories with proper permissions
RUN mkdir -p /opt/dnscrypt-proxy /var/cache/dnscrypt-proxy /config \
    && chown -R dnscrypt:dnscrypt /opt/dnscrypt-proxy /var/cache/dnscrypt-proxy /config

WORKDIR /opt/dnscrypt-proxy

# Copy binary and version from builder
COPY --from=builder --chown=dnscrypt:dnscrypt /build/dnscrypt-proxy ./
COPY --from=builder /tmp/version ./version

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD nc -z 127.0.0.1 5053 || exit 1

# Run as non-root user
USER dnscrypt

# Expose DNS ports
EXPOSE 5053/udp 5053/tcp

ENTRYPOINT ["/opt/dnscrypt-proxy/dnscrypt-proxy"]
CMD ["-config", "/config/dnscrypt-proxy.toml"]
