# Multi-stage Dockerfile for Java Maven application

# Build stage - use latest secure Maven image
FROM maven:3.9.6-eclipse-temurin-11-alpine AS builder

# Set the working directory for the build stage
WORKDIR /app

# Copy the pom.xml file first to leverage Docker layer caching
COPY pom.xml .

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN mvn dependency:go-offline -B

# Copy the source code
COPY src ./src

# Build the application with all dependencies included
RUN mvn clean compile dependency:copy-dependencies package -DskipTests

# Runtime stage - use more secure and updated base image
FROM eclipse-temurin:11-jre-alpine

# Set the working directory
WORKDIR /app

# Install security updates and create non-root user
RUN apk update && apk upgrade && apk add --no-cache \
    ca-certificates \
    && rm -rf /var/cache/apk/* \
    && addgroup -g 1000 appuser \
    && adduser -u 1000 -G appuser -s /bin/sh -D appuser

# Copy the compiled classes and dependencies from builder stage
COPY --from=builder --chown=appuser:appuser /app/target/classes ./classes
COPY --from=builder --chown=appuser:appuser /app/target/dependency/ ./libs/

# Create temp directory for application with proper permissions
RUN mkdir -p /tmp/app && chown -R appuser:appuser /tmp/app

# Expose the port that the SparkJava application runs on (default is 4567)
EXPOSE 4567

# Switch to non-root user
USER appuser

# Set the default command to run the web application
CMD ["java", "-cp", "classes:libs/*", "com.example.App"]