# Base image with Java 21
FROM eclipse-temurin:21-jre
# (You can keep openjdk:21-oracle if you prefer. Commands below still work.)

ARG UID=10001
ARG GID=10001

# Create non-root user and group
RUN groupadd -g ${GID} mc \
 && useradd -m -u ${UID} -g ${GID} -r -s /usr/sbin/nologin mc

# Tools your start script likely needs to download the JAR
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Create dirs and set ownership
RUN mkdir -p /data /app && chown -R mc:mc /data /app

# Copy scripts with correct ownership + execute bit
COPY --chown=mc:mc ./scripts/ /app/
RUN chmod +x /app/start_server.sh

# Environment
ENV JAVA_ARGS="" \
    JVM_MEMORY=2G \
    JAR_URL="https://hauntedmc.nl/server.jar"

WORKDIR /app
VOLUME ["/data"]

# Drop root
USER mc

# Start the server
CMD ["sh", "/app/start_server.sh"]
