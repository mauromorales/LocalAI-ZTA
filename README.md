![LocalAI-ZTA Logo](LocalAI-ZTA-logo.png)

LocalAI ZTA (Zero-Touch Appliance): The zero-touch way to deploy and manage [LocalAI](https://localai.io/). It's built using [Kairos](https://kairos.io), an immutable OS that simplifies Day-2 operations, making it a great choice for EDGE locations.

> [!WARNING]  
> This project is in early development, expect functionality to change and break previous contracts until a v1 is released.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building an Appliance](#building-an-appliance)
  - [1. Build an OCI image](#1-build-an-oci-image)
  - [2. Build an ISO](#2-build-an-iso)
  - [3. Adding models and backends to the ISO](#3-adding-models-and-backends-to-the-iso)
  - [4. Flashing a USB drive](#4-flashing-a-usb-drive)
  - [5. Provisioning](#5-provisioning)
- [Configuration](#configuration)
- [Post-Installation](#post-installation)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## Prerequisites

Before building your LocalAI ZTA appliance, ensure you have the following tools installed:

### Required Tools
- **Podman** - Container runtime for building OCI images
- **jq** - JSON processor (for parsing GitHub API responses)
- **xorriso** - ISO manipulation tool (for extending ISOs with models/backends)
- **curl** - For downloading LocalAI releases

### Installation Commands

#### On Fedora/RHEL/CentOS:
```bash
sudo dnf install podman jq xorriso curl
```

#### On Ubuntu/Debian:
```bash
sudo apt update && sudo apt install podman jq xorriso curl
```

#### On macOS:
```bash
brew install podman jq xorriso curl
```

### Podman Setup
Ensure Podman socket is running:
```bash
systemctl --user start podman.socket
```

## Building an Appliance

Building an appliance is done fully with [Kairos](https://kairos.io), which means that if you need to do any changes to the system you can simply do them either on the [Dockerfile](./Dockerfile) and/or the [Configuration](./cloud-config.yaml). For simplicity, LocalAI ZTA also offers the following scripts so you can get started by running them, and only dig deeper if you need to.

### 1. Build an OCI image

First we need a container image, which will be used to create the installation artifacts. Create one by running:

```bash
./scripts/build-oci.sh [REPOSITORY] [VERSION] [--push]
```

**Parameters:**
- `REPOSITORY`: Repository name (default: `localai-zta`)
- `VERSION`: Version tag for the image (optional, defaults to latest LocalAI release)
- `--push`: Push the built image to the repository (optional)

**Examples:**

```bash
# Build with latest LocalAI version
./scripts/build-oci.sh

# Build with custom repository, latest version
./scripts/build-oci.sh quay.io/mauromorales/localai-zta

# Build with custom repository and specific version
./scripts/build-oci.sh quay.io/mauromorales/localai-zta v3.6.0

# Build and push to custom repository
./scripts/build-oci.sh quay.io/mauromorales/localai-zta v3.6.0 --push
```

This will produce the image: `quay.io/mauromorales/localai-zta:v3.6.0` which we will need in the next step.

### 2. Build an ISO

An ISO can be created using the following script. You need to pass the previously generated image and the configuration so it is embedded in the system.

```bash
./scripts/build-iso.sh IMAGE CONFIG
```

**Parameters:**
- `IMAGE`: The OCI image built in step 1
- `CONFIG`: Path to the cloud-config.yaml file

**Example:**

```bash
./scripts/build-iso.sh quay.io/mauromorales/localai-zta:v3.6.0 ./cloud-config.yaml
```

At this point you need to decide whether you want to add some models and backends to the ISO so they are available in the appliance. This is a good option if your device will not have a good network connection. If you don't need to, then you can simply jump to the flashing a USB step.


### 3. Adding models and backends to the ISO

> [!WARNING]  
> The ISO without models is already around 1.2G and models can be pretty heavy. The Qwen3 0.6B model added in the example below and its required backend LlamaCPP add another 700M. Keep this in mind when deciding which models to add.

#### Installing Models and Backends

Install LocalAI in your preferred way (e.g., downloading the binaries from [github.com/mudler/LocalAI/releases](https://github.com/mudler/LocalAI/releases)) and execute the following commands:

**Install a model:**
```bash
local-ai models install NAME
```

**Install a backend:**
```bash
local-ai backends install NAME
```

> [!NOTE]  
> When you install a model, it will automatically install the necessary backend for it to run.

**Example - Install a small chat model:**
```bash
local-ai models install qwen3-0.6b
```

#### Extending the ISO

After installing models and backends, you should see the models in `./models` and backends in `./backends`. Now you can execute the extend command:

```bash
./scripts/extend-iso.sh ISO_PATH [OUTPUT_ISO]
```

**Parameters:**
- `ISO_PATH`: Path to the input ISO file
- `OUTPUT_ISO`: Optional output ISO path (defaults to `build/{basename}-extended.iso`)

**Example:**
```bash
./scripts/extend-iso.sh ./build/kairos-ubuntu-24.04-core-amd64-generic-v3.5.6.iso
```

This produces the ISO: `build/kairos-ubuntu-24.04-core-amd64-generic-v3.5.6-extended.iso`

### 4. Flashing a USB drive

> [!NOTE]  
> If you're installing on a VM, you can skip to the [Provisioning](#5-provisioning) step.

> [!WARNING]  
> This step is destructive. By flashing a device you will write on top of it. Make sure you have the right device before running.

#### Command Line Interface

```bash
dd if=/path/to/iso of=/path/to/device bs=4MB oflag=sync status=progress
```

**Example:**
```bash
dd if=./build/kairos-ubuntu-24.04-core-amd64-generic-v3.5.6-extended.iso of=/dev/sda bs=4MB oflag=sync status=progress
```

> [!WARNING]  
> Replace `/dev/sda` with the correct device path for your USB drive. Use `lsblk` or `fdisk -l` to identify the correct device.

#### Graphical Interface

Use [Balena Etcher](https://www.balena.io/etcher/) or similar software for a user-friendly approach.

### 5. Provisioning

Whether it is a VM or bare-metal that you are provisioning, make sure you configure it to boot from the installation media. Once it boots, you will see Kairos' LiveCD which will take care of the rest.

The system will automatically:
- Install the LocalAI ZTA appliance to the target disk
- Configure the system according to your cloud-config.yaml
- Set up the LocalAI service to start automatically
- Reboot into the installed system

## Configuration

The `cloud-config.yaml` file contains the configuration for your LocalAI ZTA appliance. Here are the key configuration options:

### Basic Settings
- **hostname**: Sets the system hostname (default: `localai`)
- **users**: Defines system users and their credentials
- **install**: Configures automatic installation settings

### LocalAI Configuration
- **bind_mounts**: Sets up persistent storage for models and backends
- **stages**: Configures system initialization and service setup

### Network Configuration
- **mDNS**: Enables hostname advertisement on the local network via Avahi
- **LocalAI Service**: Automatically starts the LocalAI service

### Example Configuration
```yaml
hostname: "localai"
users:
  - name: "admin"
    groups: ["admin"]
    passwd: "admin"
install:
  auto: true
  reboot: true
  device: auto
```

For more advanced configuration options, refer to the [Kairos documentation](https://kairos.io/docs/).

## Post-Installation

After successful installation, your LocalAI ZTA appliance will be accessible at:

### Access Information
- **Hostname**: `localai.local` (via mDNS) or the IP address assigned by DHCP
- **LocalAI API**: `http://localai.local:8080` or `http://<IP>:8080`
- **SSH Access**: `ssh admin@localai.local` (password: `admin`)

### Default LocalAI Configuration
- **API Endpoint**: `http://0.0.0.0:8080`
- **Models Path**: `/usr/share/local-ai/models`
- **Backends Path**: `/usr/share/local-ai/backends`
- **Threads**: 4 (configurable via environment)

### Testing the Installation
You can test your LocalAI installation by making a simple API call:

```bash
curl http://localai.local:8080/v1/models
```

This should return a list of available models if any are installed.

## Troubleshooting

### Common Issues

#### Podman Socket Not Found
**Error**: `Podman socket not found at $XDG_RUNTIME_DIR/podman/podman.sock`

**Solution**:
```bash
systemctl --user start podman.socket
```

#### ISO Build Fails
**Error**: AuroraBoot container fails to start

**Solutions**:
1. Ensure Podman is running and accessible
2. Check that the OCI image was built successfully
3. Verify the cloud-config.yaml file exists and is valid

#### Models/Backends Not Found
**Error**: `No files found in models/backends directory`

**Solution**:
1. Install LocalAI locally first
2. Use `local-ai models install <model-name>` to download models
3. Ensure the `models/` and `backends/` directories contain files before running `extend-iso.sh`

#### Device Not Bootable
**Issue**: System doesn't boot from USB

**Solutions**:
1. Verify the ISO was flashed correctly
2. Check BIOS/UEFI boot order
3. Ensure the target system supports the architecture (amd64/arm64)

#### LocalAI Service Not Starting
**Issue**: LocalAI API not accessible after installation

**Solutions**:
1. Check service status: `systemctl status local-ai`
2. View logs: `journalctl -u local-ai -f`
3. Verify network connectivity and firewall settings

#### mDNS Not Working
**Issue**: Can't access via `localai.local` hostname

**Solutions**:
1. Ensure Avahi daemon is running: `systemctl status avahi-daemon`
2. Check if mDNS is supported on your network
3. Use IP address instead: `http://<IP>:8080`

### Getting Help

- Check the [LocalAI documentation](https://localai.io/)
- Review [Kairos documentation](https://kairos.io/docs/)
- Open an issue on the [project repository](https://github.com/your-org/LocalAI-ZTA)

## Project Structure

```
LocalAI-ZTA/
├── backends/                    # Backend binaries and libraries
│   ├── cpu-llama-cpp/          # CPU-optimized LlamaCPP backend
│   └── llama-cpp/              # Standard LlamaCPP backend
├── build/                      # Build artifacts (ISOs, etc.)
├── models/                     # AI model files
├── scripts/                    # Build and utility scripts
│   ├── build-oci.sh           # OCI image builder
│   ├── build-iso.sh           # ISO builder
│   └── extend-iso.sh          # ISO extender for models/backends
├── cloud-config.yaml          # Kairos configuration
├── Dockerfile                 # Container image definition
├── README.md                  # This file
└── LICENSE                    # Project license
```

### Key Files

- **`Dockerfile`**: Defines the container image with LocalAI and Kairos integration
- **`cloud-config.yaml`**: Kairos configuration for system setup and LocalAI service
- **`scripts/build-oci.sh`**: Builds the OCI container image with LocalAI
- **`scripts/build-iso.sh`**: Creates bootable ISO from the OCI image
- **`scripts/extend-iso.sh`**: Adds models and backends to an existing ISO
- **`models/`**: Directory for AI model files (GGUF format)
- **`backends/`**: Directory for backend binaries and dependencies