![LocalAI-ZTA Logo](LocalAI-ZTA-logo.png)

# LocalAI-ZTA

LocalAI-ZTA (Zero-Touch Appliance): The zero-touch way to deploy LocalAI anywhere, from bare metal to the edge.

## Adding models and backends to the ISO

Install local-ai in prefered way e.g. downloading the binaries from github.com/mudler/LocalAI/releases and execute the following command to install a model:

```
local-ai models install NAME
```

or to install a backend

```
local-ai backends install NAME
```

Keep in mind that when you install a model it will automatically install the necessary backend for it to run.

Now you should see the models in `./models` and backends in `./backends` and you can execute the extend command

TODO: change this to be a Makefile command and not the script itself

```
scripts/extend-iso.sh ISO_PATH
```