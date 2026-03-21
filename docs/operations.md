# Operations guide

## Common container commands

```bash
# Follow logs
docker logs -f minecraft-server

# Attach to stdin/stdout (same as console)
docker attach minecraft-server

# Stop
docker stop minecraft-server

# Start
docker start minecraft-server

# Restart
docker restart minecraft-server
```

## Updating the server jar

The startup script calls `/app/download_jar.sh` before launching Java.

- Set `JAR_DOWNLOAD_MODE=always` to force refresh each startup.
- Set `JAR_DOWNLOAD_MODE=if-url-changed` to refresh only if `JAR_URL` changed.
- Set `JAR_DOWNLOAD_MODE=if-missing` to only download when `server.jar` is absent.

To force a re-download on next start:

```bash
rm -f ./data/server.jar
docker restart minecraft-server
```

## Backups

At minimum, back up your mounted data directory:

```bash
tar -czf "minecraft-backup-$(date +%F).tar.gz" ./data
```

For active servers, prefer plugin-assisted backups or stop the server first for strict consistency.

## Internal-only networking

If you do not want host exposure and only want service-to-service traffic on Docker network:

- In `examples/run-minecraft-server.sh`, set `ENABLE_JAVA_PORT="false"`.
- In `examples/run-proxy-server.sh`, set `ENABLE_JAVA_PORT="false"` (and keep Bedrock/Votifier disabled).
- For manual `docker run`, omit all `-p` flags.

## Troubleshooting startup failures

1. Confirm `JAR_URL` is reachable from the deployment host.
2. Check logs for download or checksum failures.
3. Verify `/data` is writable by UID/GID used in the container (default `10001:10001`).
4. Ensure `JVM_MEMORY` fits host capacity.
5. For Velocity/proxy jars, set `MC_NOGUI=false` (Velocity rejects `--nogui`).

## Script validation

Before opening a PR or cutting a release:

```bash
./scripts/validate.sh --with-docker-build
```
