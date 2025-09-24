# ---------- Build Stage ----------
# Use Maven with Java 17 (Eclipse Temurin JDK) to build the application
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set working directory inside the container
WORKDIR /app

# Copy everything from the project into the container
COPY . .

# Run Maven build, skip tests, use default profile
RUN mvn clean package -DskipTests -Pdefault


# ---------- Run Stage ----------
# Use a lightweight Java 17 runtime image (Debian-based)
FROM eclipse-temurin:17-jdk

# Set working directory inside the container
WORKDIR /app

# Copy the built JAR file from the build stage into the runtime container
COPY --from=build /app/target/*.jar app.jar


# ---------- Environment Setup ----------
# Install curl (optional, useful for health checks or debugging inside container)
RUN apt-get update && apt-get install -y curl

# Copy environment configuration and entry script into the container
COPY .env /app/.env
COPY env-entry.sh /app/env-entry.sh

# Ensure the entry script is executable
RUN chmod +x /app/env-entry.sh

# Use the entry script as the container startup command
# (typically this script will export env vars from .env and then run `java -jar app.jar`)
ENTRYPOINT ["/app/env-entry.sh"]
