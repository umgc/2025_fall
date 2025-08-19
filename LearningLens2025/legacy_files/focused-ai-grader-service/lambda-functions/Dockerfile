FROM public.ecr.aws/lambda/java:17

# Install build tools and Maven
RUN yum update -y && \
    yum install -y maven tar gzip wget && \
    yum clean all

# Verify Java and Maven versions
RUN java -version && mvn --version

# Copy source code
COPY pom.xml ${LAMBDA_TASK_ROOT}
COPY src ${LAMBDA_TASK_ROOT}/src

# Build the application
WORKDIR ${LAMBDA_TASK_ROOT}
RUN mvn clean compile package -DskipTests

# Copy the built JAR and verify it exists
RUN ls -la target/ && cp target/java-executor-1.0.jar ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD [ "JavaExecutor::handleRequest" ]
