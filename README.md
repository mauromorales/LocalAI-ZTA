![LocalAI-ZTA Logo](LocalAI-ZTA-logo.png)

LocalAI ZTA (Zero-Touch Appliance): The zero-touch way to deploy and manage [LocalAI](https://localai.io/). It's built using [Kairos](https://kairos.io) an immutable OS that simplifies Day-2 operations, making it a great choice for EDGE locations.

> [!WARNING]  
> This project is in early development, expect functionality to change and break previous contracts until a v1 is released.

## Building an Appliance

Building an appliance is done fully with [Kairos](https://kairos.io), which means that if you need to do any changes to the system you can simply do them either on the [Dockerfile](./Dockerfile) and/or the [Configuration](./cloud-config.yaml). For simplicity, LocalAI ZTA also offers the following scripts so you can get started by running them, and only dig deeper if you need to.

### 1. Build an OCI image

First we need a container image, which will be used to create the installation artifacts. Create one, by running:

```
./scripts/build-oci.sh REPOSITORY/IMAGE LOCALAI_VERSION
```

e.g.:

```
./scripts/build-oci.sh quay.io/mauromorales/localai-zta
```

This will produce the image: `quay.io/mauromorales/localai-zta:v3.6.0` which we will need in the next step.

### 2. Build an ISO

An ISO can be created using the following script. You need to pass the previously generated image, and the configuration so it is embeded in the system.

```
./scripts/build-iso.sh IMAGE CONFIG
```

e.g.:

```
./scripts/build-iso.sh quay.io/mauromorales/localai-zta:v3.6.0 ./cloud-config.yaml
```

At this point you need to decide whether you want to add some models and backends to the ISO so they are available in the appliance. This is a good option if your device will not have a good network. If you don't need to, then you can simply jump to the flashing a USB step.


### 3. Adding models and backends to the ISO

> [!WARNING]  
> The ISO without models is already around 1.2G and models can be pretty heavy. The Qwen3 0.6B model added in the example below and it's required backend LlamaCPP add another 700M. Keep this in mind when deciding which models to add.

Install local-ai in prefered way e.g. downloading the binaries from github.com/mudler/LocalAI/releases and execute the following command to install a model:

```
local-ai models install NAME
```

or to install a backend

```
local-ai backends install NAME
```

Keep in mind that when you install a model it will automatically install the necessary backend for it to run.

For example you can install this small chat model

```
local-ai models install qwen3-0.6b
```

Now you should see the models in `./models` and backends in `./backends` and you can execute the extend command

```
scripts/extend-iso.sh ISO_PATH
```

An ISO with the suffix `-extended` will be generated in the same directory of the ISO_PATH

e.g.:

```
/scripts/extend-iso.sh ./build/kairos-ubuntu-24.04-core-amd64-generic-v3.5.6.iso
```

produces the ISO `build/kairos-ubuntu-24.04-core-amd64-generic-v3.5.6-extended.iso`

### 4. Flashing a USB drive

> [!NOTE]  
> If you're installing on a VM you can skip to the Provisioning step

> [!WARNING]  
> This step is destructive. By flashing a device you will write on top of it. Make sure you have the right device before running

#### On the CLI 

```
dd if=/path/to/iso of=/path/to/device bs=4MB
```

e.g.:

```
dd if=./build/kairos-ubuntu-24.04-core-amd64-generic-v3.5.6-extended.iso of=/dev/sda bs=4MB oflag=sync status=progress
```

#### On the GUI

Use [Balena Etcher](https://www.balena.io/etcher/) or similar software

### 5. Provisioning

Whether it is a VM or bare-metal that you are provisionig. Make sure you configure it to boot from the installation media. Once it boots you will see Kairos' LiveCD which will take care of the rest.