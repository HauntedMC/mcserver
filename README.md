# mcserver

[![CI](https://github.com/hauntedmc/mcserver/actions/workflows/ci.yml/badge.svg)](https://github.com/hauntedmc/mcserver/actions/workflows/ci.yml)
[![Release](https://github.com/hauntedmc/mcserver/actions/workflows/release.yml/badge.svg)](https://github.com/hauntedmc/mcserver/actions/workflows/release.yml)
[![License: AGPL v3](https://img.shields.io/badge/license-AGPL%20v3-blue.svg)](./LICENSE)
[![Issues](https://img.shields.io/github/issues/hauntedmc/mcserver)](https://github.com/hauntedmc/mcserver/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/hauntedmc/mcserver)](https://github.com/hauntedmc/mcserver/pulls)

A production-oriented Docker image for running a Minecraft Java server as a non-root user, with the server JAR fetched at container start from a configurable URL.

## Why this repository exists

This repository packages a small, auditable container image for Minecraft server deployments where:

- the image itself can remain generic;
- the server JAR is supplied from your own distribution endpoint at runtime;
- persistent world data is stored under `/data`; and
- the process runs without root privileges by default.

## Features

- Runs as a dedicated non-root user inside the container.
- Downloads or refreshes `server.jar` on startup from `JAR_URL`.
- Stores server state under a mounted `/data` volume.
- Exposes straightforward JVM tuning through environment variables.
- Publishes multi-arch images to GitHub Container Registry.
- Ships with CI, contribution guidance, issue templates, and release automation.

## Quick start

### Pull the published image

```bash
docker pull ghcr.io/hauntedmc/mcserver:latest
```

### Recommended: use the example run script

The recommended way to start the image is with [`examples/run-container.sh`](./examples/run-container.sh), which sets up the data directory permissions and runs the container with the hardened flags from your original deployment script.

```bash
cp examples/run-container.sh ./run-mcserver.sh
chmod +x ./run-mcserver.sh
# edit ./run-mcserver.sh for your network, JAR_URL, memory, and timezone
./run-mcserver.sh
```

### Minimal manual start

```bash
docker run \
  --name minecraft-server \
  --restart unless-stopped \
  -d \
  -e JVM_MEMORY=8G \
  -e JAVA_ARGS='-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200' \
  -e JAR_URL='https://example.com/path/to/server.jar' \
  -v "$PWD/data:/data" \
  ghcr.io/hauntedmc/mcserver:latest
```

### Attach to the Minecraft console

```bash
docker attach minecraft-server
```

### Stop the container

```bash
docker stop minecraft-server
```

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `JVM_MEMORY` | `2G` | Sets both `-Xms` and `-Xmx`. |
| `JAVA_ARGS` | `""` | Additional JVM arguments appended to the Java command. |
| `JAR_URL` | `https://hauntedmc.nl/server.jar` | URL used by the startup helper to fetch `server.jar`. |
| `UMASK` | `0002` | File creation mask applied before startup. |

## Operating notes

- The deployment environment must be able to reach the configured `JAR_URL`.
- The startup sequence always refreshes `/data/server.jar` before launching Java.
- `/data` should be mounted from persistent storage for worlds, logs, configs, and downloaded artifacts.
- The example run script expects permission to `chown` the host data directory to UID/GID `10001`; adjust those values if your environment requires different ownership.
- The image does not bundle a server JAR, so you remain responsible for distributing any proprietary upstream binaries in a compliant way.

## Local development

### Build locally

```bash
./build.sh
```

### Export a local image into containerd

```bash
docker save -o mcserver.tar mcserver:nonroot
ctr -n=k8s.io i import mcserver.tar
```

## Release process

1. Update changes on the default branch.
2. Run `./update_version.sh <major|minor|patch>`.
3. Push the branch and the new tag.
4. GitHub Actions will build and publish a multi-architecture image and create a GitHub release for that tag.

## Open source and community

- License: GNU Affero General Public License v3.0. See [LICENSE](./LICENSE).
- Contributing guide: [CONTRIBUTING.md](./CONTRIBUTING.md).
- Security policy: [SECURITY.md](./SECURITY.md).
- Code of conduct: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

## License

This project is licensed under the GNU Affero General Public License v3.0 or later (AGPL-3.0-or-later). See [LICENSE](./LICENSE) for the full text.
