# Runtime and script reference

This document explains the runtime image design and the scripts used to start and validate `mcserver`.

## Dockerfile design

`Dockerfile` intentionally keeps the image small and auditable:

- Base image: `eclipse-temurin:21-jre`
- Runtime tools: `ca-certificates` and `curl`
- Runtime user: non-root `mc` user (`UID`/`GID` build args)
- Mutable data path: `/data` (declared as `VOLUME`)
- Runtime scripts copied into `/app` as read+execute only

### Build args

| Name | Default | Purpose |
| --- | --- | --- |
| `UID` | `10001` | Container user id for file ownership alignment. |
| `GID` | `10001` | Container group id for file ownership alignment. |
| `SOURCE_URL` | `https://github.com/hauntedmc/mcserver` | OCI label metadata source URL. |

### Default env vars (image-level)

These are safe defaults only. Required runtime values such as `JAR_URL` and `JVM_MEMORY` must be supplied via `docker run`.

| Name | Default | Purpose |
| --- | --- | --- |
| `JAVA_ARGS` | `""` | Extra JVM flags. |
| `JAR_DOWNLOAD_MODE` | `always` | Download behavior for `server.jar`. |
| `EULA` | `false` | Whether to auto-write `eula.txt`. |
| `UMASK` | `0002` | File creation mask before startup. |

## Runtime startup flow

Container command is `/app/start_server.sh`. The flow is:

1. Apply `UMASK`.
2. Ensure required env (`JVM_MEMORY`) exists.
3. Optionally write `eula.txt` when `EULA=true`.
4. Call `/app/download_jar.sh`.
5. Verify `/data/server.jar` exists and is non-empty.
6. Start Java with `-Xms/-Xmx` from `JVM_MEMORY`.

## `scripts/` directory

### `scripts/lib.sh`

Shared POSIX helpers for runtime scripts:

- `_log`: structured timestamped logs
- `die`: log + exit
- `command_exists`: command availability checks
- `require_env`: required env validation
- `is_true`: boolean env parser

### `scripts/download_jar.sh`

Downloads and validates `/data/server.jar`.

Inputs:

- Required: `JAR_URL`
- Optional: `JAR_DOWNLOAD_MODE`, `JAR_DOWNLOAD_TIMEOUT`, `JAR_SHA256`

Behavior:

- Supports `always`, `if-missing`, `if-url-changed`.
- Downloads to temp file, then atomically moves to `server.jar`.
- Stores `.jar.url` for future mode decisions.
- Stores `.jar.sha256` when checksum verification is enabled.

### `scripts/start_server.sh`

Container entrypoint. It enforces required env and starts Java.

Inputs:

- Required: `JVM_MEMORY`, `JAR_URL` (checked by download script)
- Optional: `JAVA_ARGS`, `UMASK`, `EULA`, download-related vars

### `scripts/validate.sh`

Local and CI validation runner:

- Parser checks with `sh -n` and `bash -n`
- `shellcheck` linting (required or optional)
- Optional Docker build smoke test (`--with-docker-build`)

Run it with:

```bash
./scripts/validate.sh --require-shellcheck
```
