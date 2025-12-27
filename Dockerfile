FROM maven:3.9.9-eclipse-temurin-17

WORKDIR /workspace

# Copy and build
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src/ src/
RUN mvn clean javadoc:javadoc -B

CMD ["echo", "Javadoc generated in target/reports/apidocs/"]
