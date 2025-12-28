FROM maven:3.9-eclipse-temurin-21

WORKDIR /app

# Copy pom.xml and download dependencies (cached unless pom.xml changes)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build (no need for 'clean' in Docker)
COPY src/ src/
RUN mvn javadoc:javadoc -B

CMD ["echo", "Javadoc generated in target/reports/apidocs/"]
