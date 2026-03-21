FROM eclipse-temurin:21-jre

# UID/GID are build-time overrides so operators can match host ownership models.
ARG UID=10001
ARG GID=10001
ARG SOURCE_URL="https://github.com/hauntedmc/mcserver"

LABEL org.opencontainers.image.title="mcserver" \
      org.opencontainers.image.description="Production-oriented non-root Minecraft server image that downloads the server JAR at startup." \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.source="${SOURCE_URL}"

# Install only runtime dependencies and create a dedicated non-root account.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g ${GID} mc \
 && useradd -m -u ${UID} -g ${GID} -r -s /usr/sbin/nologin mc \
 && mkdir -p /data /app \
 && chown -R mc:mc /data /app

# Copy only required runtime entrypoint files; keep permissions read/execute.
COPY --chown=mc:mc ./scripts/lib.sh /app/lib.sh
COPY --chown=mc:mc ./scripts/start_server.sh /app/start_server.sh
COPY --chown=mc:mc ./scripts/download_jar.sh /app/download_jar.sh
RUN chmod 0555 /app/lib.sh /app/start_server.sh /app/download_jar.sh

# These are optional defaults; required runtime values (JAR_URL, JVM_MEMORY)
# must be provided at `docker run` time.
ENV JAVA_ARGS="" \
    JAR_DOWNLOAD_MODE=always \
    EULA=false \
    UMASK=0002

# All mutable server state lives under /data.
WORKDIR /data
VOLUME ["/data"]

USER mc

# Entrypoint validates env, downloads jar, then execs Java.
CMD ["/app/start_server.sh"]
