# mcserver image repo

## Installation

### Build Locally
```bash
./build.sh
```

### Get Access to GPR
```bash
docker login ghcr.io
```

### Pull Image
```bash
docker pull ghcr.io/hauntedmc/mcserver:latest
```

## Usage

Note: 
Deployment environment needs access to jar repository.

### Run Image
```bash
NAME="CONTAINER_NAME_HERE"
ARGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
MOUNT="LOCAL_DATA_PATH_HERE:/data"
MEM="1G"
IMAGE="ghcr.io/hauntedmc/mcserver:latest"
JAR_URL="https://hauntedmc.nl/server.jar"
SERVER_PORT="SERVER_PORT_HERE"

docker rm $NAME
docker run --name $NAME --network bridge -d -p $SERVER_PORT:$SERVER_PORT -e JVM_MEMORY=$MEM -e JAVA_ARGS="$ARGS" -e JAR_URL=$JAR_URL -v $MOUNT -it $IMAGE
```

### Attach Minecraft Console
```bash
docker attach CONTAINER_NAME_HERE
```

### Stop Container
```bash
docker stop CONTAINER_NAME_HERE
```

## Development

### Build and Release
```bash
./update_version.sh <major|minor|patch>
```

### Export local build to containerd (Kubernetes)
```bash
docker save -o CONTAINER_NAME_HERE.tar CONTAINER_NAME_HERE
ctr -n=k8s.io i import CONTAINER_NAME_HERE.tar
```

