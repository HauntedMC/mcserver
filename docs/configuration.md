# Configuration reference

`mcserver` is configured through environment variables passed to the container.

## Required variables

| Variable | Default | Description |
| --- | --- | --- |
| `JAR_URL` | none (required) | Direct URL used to fetch the server jar. |
| `JVM_MEMORY` | none (required) | Sets both `-Xms` and `-Xmx` (for example `2G`, `4096M`). |

## Optional variables

| Variable | Default | Description |
| --- | --- | --- |
| `JAVA_ARGS` | `""` | Extra JVM arguments appended to the java command. |
| `UMASK` | `0002` | File creation mask applied before startup. |
| `JAR_DOWNLOAD_MODE` | `always` | `always`, `if-missing`, or `if-url-changed`. |
| `JAR_DOWNLOAD_TIMEOUT` | `300` | Download timeout in seconds when using `curl`. |
| `JAR_SHA256` | `""` | Optional SHA-256 checksum for jar integrity validation. |
| `EULA` | `false` | If `true`, writes `eula=true` to `/data/eula.txt` on startup. |
| `TZ` | unset | Optional timezone for JVM/container processes. |

## Recommended baseline

```bash
docker run \
  --name minecraft-server \
  --restart unless-stopped \
  -d \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  -e JVM_MEMORY=8G \
  -e JAR_URL='https://example.com/path/to/server.jar' \
  -e JAR_DOWNLOAD_MODE=if-url-changed \
  -v "$PWD/data:/data" \
  ghcr.io/hauntedmc/mcserver:latest
```

## Notes

- The image does not include a bundled server jar.
- `/data` should be mounted from persistent storage.
- If checksum validation is enabled with `JAR_SHA256`, startup fails when the hash does not match.
