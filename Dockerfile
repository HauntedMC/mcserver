# Base image with Java 21
FROM eclipse-temurin:21-jre

ARG UID=10001
ARG GID=10001

# Create non-root user and group
RUN groupadd -g ${GID} mc \
 && useradd -m -u ${UID} -g ${GID} -r -s /usr/sbin/nologin mc


# Create dirs and set ownership
RUN mkdir -p /data /app && chown -R mc:mc /data /app

# Copy scripts with correct ownership + execute bit
COPY --chown=mc:mc ./scripts/ /app/
RUN chmod +x /app/start_server.sh \
    # satisfy start_server.sh's '../download_jar.sh' by making /download_jar.sh resolve
    && [ -f /app/download_jar.sh ] && ln -s /app/download_jar.sh /download_jar.sh || true

# Environment
ENV JAVA_ARGS="" \
    JVM_MEMORY=2G \
    JAR_URL="https://hauntedmc.nl/server.jar" \
    UMASK=0002

WORKDIR /data
VOLUME ["/data"]

USER mc

CMD ["sh","-lc","umask ${UMASK} && exec /app/start_server.sh"]

