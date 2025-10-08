#!/bin/bash
# Extends an ISO by adding all files from models/ and backends/ directories using xorriso
# Usage: ./extend-iso.sh <input-iso> [output-iso]
# Environment variable IMAGE_VARIANT can be set to "core" (default) or "standard"

set -e  # Exit on any error

# Set image variant (core or standard), default to core
IMAGE_VARIANT=${IMAGE_VARIANT:-core}

INPUT_ISO=$1
OUTPUT_ISO=$2

# Validate image variant
if [ "$IMAGE_VARIANT" != "core" ] && [ "$IMAGE_VARIANT" != "standard" ]; then
    echo "Error: IMAGE_VARIANT must be 'core' or 'standard', got: $IMAGE_VARIANT"
    exit 1
fi

# Set target paths based on image variant
if [ "$IMAGE_VARIANT" = "core" ]; then
    MODELS_TARGET_PATH="/usr/share/local-ai/models"
    BACKENDS_TARGET_PATH="/usr/share/local-ai/backends"
else
    MODELS_TARGET_PATH="/opt/local-ai/models"
    BACKENDS_TARGET_PATH="/opt/local-ai/backends"
fi

# Validate arguments
if [ -z "$INPUT_ISO" ]; then
    echo "Error: INPUT_ISO argument is required"
    echo "Usage: $0 <input-iso> [output-iso]"
    exit 1
fi

# Check if input ISO exists
if [ ! -f "$INPUT_ISO" ]; then
    echo "Error: Input ISO '$INPUT_ISO' not found"
    exit 1
fi

# Set default output ISO name if not provided
if [ -z "$OUTPUT_ISO" ]; then
    # Extract filename without extension
    BASENAME=$(basename "$INPUT_ISO" .iso)
    # Only add -extended if it's not already in the filename
    if [[ "$BASENAME" == *"-extended" ]]; then
        OUTPUT_ISO="build/${BASENAME}.iso"
    else
        OUTPUT_ISO="build/${BASENAME}-extended.iso"
    fi
fi

# Ensure build directory exists
mkdir -p build

# Check if models directory exists
MODELS_DIR="models"
BACKENDS_DIR="backends"

if [ ! -d "$MODELS_DIR" ]; then
    echo "Error: $MODELS_DIR directory not found"
    echo "Create the directory and place your model files in it"
    exit 1
fi

# Check if models directory has any files
if [ -z "$(find "$MODELS_DIR" -type f)" ]; then
    echo "Error: No files found in $MODELS_DIR directory"
    exit 1
fi

# Check if backends directory exists
if [ ! -d "$BACKENDS_DIR" ]; then
    echo "Error: $BACKENDS_DIR directory not found"
    echo "Create the directory and place your backend files in it"
    exit 1
fi

# Check if backends directory has any files
if [ -z "$(find "$BACKENDS_DIR" -type f)" ]; then
    echo "Error: No files found in $BACKENDS_DIR directory"
    exit 1
fi

# Check if xorriso is installed
if ! command -v xorriso &> /dev/null; then
    echo "Error: xorriso is not installed"
    echo "Install it with: sudo dnf install xorriso"
    exit 1
fi

echo "Extending ISO: $INPUT_ISO"
echo "Output ISO: $OUTPUT_ISO"
echo "Image variant: $IMAGE_VARIANT"
echo "Adding all files from $MODELS_DIR/ to $MODELS_TARGET_PATH/"
echo "Adding all files from $BACKENDS_DIR/ to $BACKENDS_TARGET_PATH/"

# Build xorriso command with all files in models directory
# Use the same approach as AuroraBoot to preserve boot information
XORRISO_CMD="xorriso -indev \"$INPUT_ISO\" -outdev \"$OUTPUT_ISO\""

# Add each file in the models directory
echo "Files to be added:"
echo "  Models:"
while IFS= read -r -d '' file; do
    # Get relative path from models directory
    rel_path="${file#$MODELS_DIR/}"
    target_path="$MODELS_TARGET_PATH/$rel_path"
    
    echo "    - $target_path"
    XORRISO_CMD="$XORRISO_CMD -map \"$file\" \"$target_path\""
done < <(find "$MODELS_DIR" -type f -print0)

# Add each file in the backends directory
echo "  Backends:"
while IFS= read -r -d '' file; do
    # Get relative path from backends directory
    rel_path="${file#$BACKENDS_DIR/}"
    target_path="$BACKENDS_TARGET_PATH/$rel_path"
    
    echo "    - $target_path"
    XORRISO_CMD="$XORRISO_CMD -map \"$file\" \"$target_path\""
done < <(find "$BACKENDS_DIR" -type f -print0)

# Add boot image replay to preserve boot information (same as AuroraBoot)
XORRISO_CMD="$XORRISO_CMD -boot_image any replay"

echo ""
echo "Executing xorriso with boot preservation..."
eval "$XORRISO_CMD"

echo "Successfully created extended ISO: $OUTPUT_ISO"

# Show the size difference
INPUT_SIZE=$(du -h "$INPUT_ISO" | cut -f1)
OUTPUT_SIZE=$(du -h "$OUTPUT_ISO" | cut -f1)
echo ""
echo "Size comparison:"
echo "  Original: $INPUT_SIZE"
echo "  Extended: $OUTPUT_SIZE"
