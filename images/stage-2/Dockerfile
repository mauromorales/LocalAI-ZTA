ARG BASE_IMAGE
ARG KAIROS_INIT=v0.5.20
ARG VARIANT=core

FROM quay.io/kairos/kairos-init:${KAIROS_INIT} AS kairos-init

FROM ${BASE_IMAGE} AS kairos-core
ARG VERSION

RUN --mount=type=bind,from=kairos-init,src=/kairos-init,dst=/kairos-init \
    /kairos-init -l debug -s install -m "generic" --version "${VERSION}" && \
    /kairos-init -l debug -s init -m "generic" --version "${VERSION}"

FROM ${BASE_IMAGE} AS kairos-standard
ARG VERSION

RUN --mount=type=bind,from=kairos-init,src=/kairos-init,dst=/kairos-init \
    /kairos-init -l debug -s install -m "generic" -k "k0s" --k8sversion "v1.33.4+k0s.0" --version "${VERSION}" && \
    /kairos-init -l debug -s init -m "generic" -k "k0s" --k8sversion "v1.33.4+k0s.0" --version "${VERSION}"

FROM kairos-core AS core
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

# Standard variant stage (Kubernetes-based)
FROM kairos-standard AS standard
# TODO: Add Kubernetes-specific configuration for standard variant
# This is where you would add Kubernetes manifests, Helm charts, etc.

FROM ${VARIANT}