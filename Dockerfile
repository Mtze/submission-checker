# Build stage
FROM eclipse-temurin:11-jdk AS builder

# Set working directory for build
WORKDIR /build

# Copy Maven configuration files
COPY pom.xml .
COPY src ./src

# Install Maven and build the application
RUN apt-get update && apt-get install -y maven && \
    mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:11-jre

# Set metadata
LABEL maintainer="SIGSOFT Submission Checker"
LABEL description="The SIGSOFT Submission Checker (SSC) is a tool to check paper submissions for formatting and anonymity compliance"
LABEL version="0.4.3"

# Create app directory
WORKDIR /app

# Create user for running the application (security best practice)
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -m appuser

# Copy the JAR file from build stage
COPY --from=builder /build/target/submission-checker-*-jar-with-dependencies.jar submission-checker.jar

# Create directories for input and output with proper permissions
RUN mkdir -p /app/input /app/output && \
    chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Set entrypoint to java with the JAR
ENTRYPOINT ["java", "-jar", "submission-checker.jar"]

# Default command - show help
CMD ["--help"]

# Health check to verify the JAR can execute
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -jar submission-checker.jar --help || exit 1