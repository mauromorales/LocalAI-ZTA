ARG BASE_IMAGE=ubuntu:24.04
ARG KAIROS_INIT=v0.5.20

FROM quay.io/kairos/kairos-init:${KAIROS_INIT} AS kairos-init

FROM ${BASE_IMAGE} AS base-kairos
ARG MODEL=generic
ARG TRUSTED_BOOT=false
ARG VERSION

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    systemctl \
    # to advertise the hostname on the local network
    avahi-daemon \
    libnss-mdns \
    && rm -rf /var/lib/apt/lists/*

# Set LocalAI version and detect architecture
ARG LOCALAI_VERSION=v3.5.4
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


RUN --mount=type=bind,from=kairos-init,src=/kairos-init,dst=/kairos-init \
    /kairos-init -l debug -s install -m "${MODEL}" -t "${TRUSTED_BOOT}" --version "${VERSION}" && \
    /kairos-init -l debug -s init -m "${MODEL}" -t "${TRUSTED_BOOT}" --version "${VERSION}"

# Create local-ai user and group
RUN useradd -r -s /bin/false -U -m -d /usr/share/local-ai local-ai

# Create models and backends directories and set permissions
RUN mkdir -p /usr/share/local-ai/models /usr/share/local-ai/backends && \
    chown -R local-ai:local-ai /usr/share/local-ai

# Create systemd service
RUN mkdir -p /etc/systemd/system
COPY <<EOF /etc/systemd/system/local-ai.service
[Unit]
Description=LocalAI Service
After=network-online.target

[Service]
ExecStart=/usr/bin/local-ai run
User=local-ai
Group=local-ai
Restart=always
EnvironmentFile=/etc/localai.env
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WorkingDirectory=/usr/share/local-ai

[Install]
WantedBy=default.target
EOF

# Create environment file with default settings
RUN touch /etc/localai.env && \
    echo "ADDRESS=0.0.0.0:8080" > /etc/localai.env && \
    echo "API_KEY=" >> /etc/localai.env && \
    echo "THREADS=4" >> /etc/localai.env && \
    echo "MODELS_PATH=/usr/share/local-ai/models" >> /etc/localai.env