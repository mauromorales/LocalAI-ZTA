#!/bin/bash
# Builds the LocalAI ZTA appliance

set -e

VARIANT=$1

# Build the OCI image
REPOSITORY=quay.io/mauromorales/localai-zta ARTIFACT_VERSION=v0.0.1 VARIANT=$VARIANT ./scripts/build-oci.sh

# Build the ISO
./scripts/build-iso.sh quay.io/mauromorales/localai-zta:v0.0.1_${VARIANT} ./cloud-config/${VARIANT}.yaml

# Extend the ISO
ISO_PATH=$(ls build/*${VARIANT}*v0.0.1*.iso | head -n 1)
IMAGE_VARIANT=$VARIANT ./scripts/extend-iso.sh $ISO_PATH