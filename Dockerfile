# Reproducible Build Environment for Javadoc Generation
# Uses fixed versions to ensure deterministic builds

FROM maven:3.9.9-eclipse-temurin-17

# Set fixed locale and timezone for reproducibility
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

# Set Maven to run in non-interactive batch mode
ENV MAVEN_OPTS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"

# Create workspace directory
WORKDIR /workspace

# Copy only pom.xml first to leverage Docker layer caching for dependencies
COPY pom.xml .

# Download dependencies (this layer is cached unless pom.xml changes)
RUN mvn dependency:go-offline -B -q

# Copy source files
COPY src/ src/

# Generate Javadoc in non-interactive batch mode
# The -B flag ensures reproducible output without terminal-dependent formatting
RUN mvn clean javadoc:javadoc -B -q \
    && echo "Javadoc generation completed successfully"

# Set default command to display build info
CMD ["echo", "Build complete. Javadoc available in target/reports/apidocs/"]
