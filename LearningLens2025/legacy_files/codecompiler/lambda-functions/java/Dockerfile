FROM public.ecr.aws/lambda/java:11

# Copy source files
COPY . ${LAMBDA_TASK_ROOT}

# Install specific Maven version
RUN yum update -y && \
    yum install -y wget && \
    cd /opt && \
    wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \
    tar xzf apache-maven-3.6.3-bin.tar.gz && \
    ln -s apache-maven-3.6.3 maven && \
    yum clean all

# Set Maven path
ENV PATH="/opt/maven/bin:${PATH}"

# Verify Maven version
RUN mvn --version

# Build the project
WORKDIR ${LAMBDA_TASK_ROOT}
RUN mvn clean compile package -DskipTests

# Copy the built JAR
RUN cp target/java-executor-1.0.jar ${LAMBDA_TASK_ROOT}/lib/

# Set the CMD
CMD [ "JavaExecutor::handleRequest" ]
