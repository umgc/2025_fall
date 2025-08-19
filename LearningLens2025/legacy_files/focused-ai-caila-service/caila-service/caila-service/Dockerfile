# Base image with JDK
FROM eclipse-temurin:17-jdk-alpine

# Set work directory inside container
WORKDIR /app

# Copy project files
COPY . .

# Package the application using Maven Wrapper
RUN chmod +x mvnw
RUN ./mvnw clean package -DskipTests

# Expose the port the app runs on
EXPOSE 8080

# Run the jar file (update name if needed)
CMD ["java", "-jar", "target/caila-service-0.0.1-SNAPSHOT.jar"]
