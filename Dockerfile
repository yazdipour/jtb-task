FROM maven:3.9-eclipse-temurin-21

# Install runtime dependencies for scripts
# curl: for fetching release notes
# tar: for archiving
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Pre-download Maven dependencies to cache them in the layer
# This improves build speed by caching dependencies in the Docker image
COPY pom.xml .
RUN mvn dependency:go-offline -B
