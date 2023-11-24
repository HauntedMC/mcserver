# Base image with Java 17 installed
FROM openjdk:17-oracle

# Set environment variables
ENV JAVA_ARGS="" \
    JVM_MEMORY=1G \
    JAR_URL="https://hauntedmc.nl/server.jar"

# Create data folder
RUN mkdir /data

# Copy scripts
COPY ./scripts/ .

# Start the server
CMD ["sh", "./start_server.sh"]

VOLUME /data
