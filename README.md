# mcserver

[![CI](https://github.com/hauntedmc/mcserver/actions/workflows/ci.yml/badge.svg)](https://github.com/hauntedmc/mcserver/actions/workflows/ci.yml)
[![Publish](https://github.com/hauntedmc/mcserver/actions/workflows/release.yml/badge.svg)](https://github.com/hauntedmc/mcserver/actions/workflows/release.yml)
[![License: AGPL v3](https://img.shields.io/badge/license-AGPL%20v3-blue.svg)](./LICENSE)
[![Issues](https://img.shields.io/github/issues/hauntedmc/mcserver)](https://github.com/hauntedmc/mcserver/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/hauntedmc/mcserver)](https://github.com/hauntedmc/mcserver/pulls)

A production-oriented Docker image for running a Minecraft Java server as a non-root user, with the server JAR downloaded at container startup.

## Highlights

- Runs as a dedicated non-root user.
- Downloads `server.jar` from `JAR_URL` at startup with retry support.
- Supports optional checksum verification via `JAR_SHA256`.
- Stores all mutable server state under `/data`.
- Includes hardened example run scripts for both Java server and proxy workflows.

## Quick start

### Pull the image

```bash
docker pull ghcr.io/hauntedmc/mcserver:latest
```

### Use the example runner (recommended)

```bash
cp examples/run-minecraft-server.sh ./run-mcserver.sh
chmod +x ./run-mcserver.sh
# Edit JAR_URL and other config values first
./run-mcserver.sh
```

For proxy deployments (for example Velocity), use [`examples/run-proxy-server.sh`](./examples/run-proxy-server.sh).

### Minimal manual run

```bash
docker run \
  --name minecraft-server \
  --restart unless-stopped \
  -d \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  -e JVM_MEMORY=8G \
  -e JAR_URL='https://example.com/path/to/server.jar' \
  -v "$PWD/data:/data" \
  ghcr.io/hauntedmc/mcserver:latest
```

## Documentation

- Configuration reference: [docs/configuration.md](./docs/configuration.md)
- Operations guide: [docs/operations.md](./docs/operations.md)
- Runtime and script reference: [docs/runtime-reference.md](./docs/runtime-reference.md)
- Project structure and naming conventions: [docs/project-structure.md](./docs/project-structure.md)

## Development

Run repository checks:

```bash
./scripts/validate.sh --with-docker-build
```

Build locally:

```bash
./build.sh
```

Bump release version and create tag:

```bash
./update_version.sh patch
```

## Release tags

Pushing a version tag such as `v1.2.3` publishes:

- `ghcr.io/hauntedmc/mcserver:latest`
- `ghcr.io/hauntedmc/mcserver:v1.2.3`
- `ghcr.io/hauntedmc/mcserver:1.2.3`
- `ghcr.io/hauntedmc/mcserver:sha-<commit>`

## Community and policy

- Contributing: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Security policy: [SECURITY.md](./SECURITY.md)
- Code of conduct: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
- License: [LICENSE](./LICENSE)
