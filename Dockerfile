# Base image with Java 17 installed
FROM openjdk:17-oracle

# Set environment variables
ENV SERVER_PORT=25565 \
    JAVA_ARGS="" \
    JVM_MEMORY=1G \
    JAR_URL="https://hauntedmc.nl/server.jar"

# Create data folder
RUN mkdir /data

# Copy scripts
COPY ./start_server.sh .

# Set the JVM memory options
ENV JVM_MEMORY_OPTIONS="-Xms${JVM_MEMORY} -Xmx${JVM_MEMORY}"

# Start the server
CMD ["sh", "./start_server.sh"]

# Expose the server port
EXPOSE ${SERVER_PORT}

VOLUME /data
