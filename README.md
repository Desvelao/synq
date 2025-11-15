# Description

**synq** is a portable tool to synchronize directories that uses **rsync** under the hood and allow synchronizing different syncs between two directories (buckets).

This can be as another syncing tool and works ideally for external drives.

# Installation

```
SYNQ_INSTALLATION_DIR=/usr/local/bin/synq
wget https://raw.githubusercontent.com/Desvelao/synq/refs/tags/v0.1.0/synq
chmod +x $SYNQ_INSTALLATION_DIR
synq --version
```

```bash
wget https://raw.githubusercontent.com/Desvelao/synq/refs/tags/v0.1.0/synq.conf.example -O $HOME/.synq/synq.conf
```

Edit the `$HOME/.synq/synq.conf` example file for your use case.

# Usage

Synchronize all the buckets in the configuration file:

```bash
synq -y
```
> `-y` avoids to ask for configuration.

By default, the tool uses the following configuration files:

- `SYNQ_CONF` environment variable
- `$HOME/.synq/synq.conf` file
- use the `--config/-c <file>` flag to define another configuration file

Sync specific buckets:

```bash
synq -y bucket1 bucket2
```

Invert the synchronization, that synchronizes the destination into the source:

```bash
synq -y -r bucket1 bucket2
```

Dry-run the synchronization:

```bash
synq -y -n bucket1 bucket2
```

# Development

## Code format

This uses [shfmt](https://webinstall.dev/shfmt/).

```
shfmt -w -i 2 synq
```

## Test

The test suite uses [bats](https://bats-core.readthedocs.io/en/stable/)

```bash
bats tests
```

Running using Docker:

```bash
docker compose up
```
