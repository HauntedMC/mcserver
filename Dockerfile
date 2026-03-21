FROM eclipse-temurin:21-jre

ARG UID=10001
ARG GID=10001
ARG SOURCE_URL="https://github.com/your-org/mcserver"

LABEL org.opencontainers.image.title="mcserver" \
      org.opencontainers.image.description="Production-oriented non-root Minecraft server image that downloads the server JAR at startup." \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.source="${SOURCE_URL}"

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g ${GID} mc \
 && useradd -m -u ${UID} -g ${GID} -r -s /usr/sbin/nologin mc \
 && mkdir -p /data /app \
 && chown -R mc:mc /data /app

COPY --chown=mc:mc ./scripts/ /app/
RUN chmod +x /app/start_server.sh /app/download_jar.sh

ENV JAVA_ARGS="" \
    JVM_MEMORY=2G \
    JAR_URL="https://example.com/path/to/server.jar" \
    UMASK=0002

WORKDIR /data
VOLUME ["/data"]

USER mc

CMD ["sh", "-lc", "umask ${UMASK} && exec /app/start_server.sh"]
