# Description

**synq** is a portable tool to synchronize directories that uses **rsync** under the hood and allow synchronizing different syncs between two directories (buckets).

This can be as another syncing tool and works ideally for external drives.

# Installation

```
SYNQ_INSTALLATION_DIR=/usr/local/bin/synq
wget https://github.com/Desvelao/synq/releases/download/v0.2.0/synq-0.2.0-linux-amd64.tar.gz \
&& tar -xzf synq-0.2.0-linux-amd64.tar.gz \
&& sudo mv synq "$SYNQ_INSTALLATION_DIR" \
&& chmod +x "$SYNQ_INSTALLATION_DIR"
```

Check installation:

```bash
synq --version
```

Download the configuration example file:
```bash
wget https://raw.githubusercontent.com/Desvelao/synq/refs/tags/v0.2.0/synq.yml.example -O $HOME/.synq/synq.yml
```

Edit the `$HOME/.synq/synq.yml` example file for your use case.

# Usage

Synchronize all the buckets in the configuration file:

```bash
synq -y
```
> `-y` avoids to ask for configuration.

By default, the tool uses the following configuration files:

- `SYNQ_CONF` environment variable
- `$HOME/.synq/synq.yml` file
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

# Configuration

Default config resolution:

1. `SYNQ_CONF` environment variable
2. `$HOME/.synq/synq.yml`

You can override it with `--config` / `-c`.

Config file format (`.yaml` / `.yml`):

```yaml
log_dir: path/to/logs/dir
buckets:
  - name: bucket1
    src: path/to/src1/
    dest: path/to/dest1/
    rsync_options:
  - name: bucket2
    src: path/to/src2/
    dest: path/to/dest2/
    rsync_options: -hz
  - src: path/to/src3/
    dest: path/to/dest3/
    rsync_options: -hz
```

**name** is optional, if not provided, buckets are auto-named in order as `bucket1`, `bucket2`, etc. for CLI selection.

# Development

## Install dependencies

```bash
cd src && go mod tidy
```

## Build

```bash
export VERSION="<version>" && scripts/build.sh
```

Docker compose:

```bash
docker compose -f docker-compose.build.yml up
```

This will build the binary and place it in the `output` directory.

## Code format

```bash
scripts/format.sh
```

## Test

```bash
scripts/test.sh
```

Running using Docker:

```bash
docker compose -f docker-compose.test.yml up
```
