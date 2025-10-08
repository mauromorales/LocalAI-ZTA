ARG BASE_IMAGE=ubuntu:24.04
ARG VARIANT=core

FROM ${BASE_IMAGE} AS mdns-packages
# Install required packages
RUN apt-get update && apt-get install -y \
    # to advertise the hostname on the local network
    avahi-daemon \
    libnss-mdns \
    && rm -rf /var/lib/apt/lists/*

FROM mdns-packages AS core
# Set LocalAI version and detect architecture
ARG LOCALAI_VERSION=v3.5.4
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    && rm -rf /var/lib/apt/lists/*
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) ARCH="amd64" ;; \
        aarch64|arm64) ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    echo "Installing LocalAI ${LOCALAI_VERSION} for architecture ${ARCH}" && \
    # Download LocalAI binary
    curl --fail --location --progress-bar -o /tmp/local-ai \
        "https://github.com/mudler/LocalAI/releases/download/${LOCALAI_VERSION}/local-ai-${LOCALAI_VERSION}-linux-${ARCH}" && \
    # Install binary to /usr/bin (not /usr/local/bin due to Kairos overlay)
    install -o0 -g0 -m755 /tmp/local-ai /usr/bin/local-ai && \
    rm /tmp/local-ai

FROM mdns-packages AS standard
# TODO: Add standard variant packages

FROM ${VARIANT}