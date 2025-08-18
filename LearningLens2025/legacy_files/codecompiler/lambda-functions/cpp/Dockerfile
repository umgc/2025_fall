FROM public.ecr.aws/lambda/provided:al2-x86_64

# Install C++ development environment
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        gcc-c++ \
        cmake3 \
        make \
        curl-devel \
        openssl-devel \
        which \
        wget \
        tar \
        gzip && \
    yum clean all

# Create cmake symlink
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# Install AWS Lambda C++ Runtime
WORKDIR /tmp
RUN curl -sSL https://github.com/awslabs/aws-lambda-cpp/archive/v0.2.7.tar.gz | tar xz && \
    cd aws-lambda-cpp-0.2.7 && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/aws-lambda && \
    make -j$(nproc) && \
    make install

# Set environment
ENV CMAKE_PREFIX_PATH="/opt/aws-lambda:${CMAKE_PREFIX_PATH}"
ENV LD_LIBRARY_PATH="/opt/aws-lambda/lib:${LD_LIBRARY_PATH}"

# Copy source files
COPY . ${LAMBDA_TASK_ROOT}/

# Build the application
WORKDIR ${LAMBDA_TASK_ROOT}
RUN mkdir -p build && \
    cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=/opt/aws-lambda && \
    make -j$(nproc)

# Verify the executable was built
RUN ls -la build/
RUN file build/cpp-executor

# Copy the executable to the correct location
RUN cp build/cpp-executor ${LAMBDA_RUNTIME_DIR}/bootstrap

# Set executable permissions
RUN chmod +x ${LAMBDA_RUNTIME_DIR}/bootstrap

# Verify the bootstrap file exists and is executable
RUN ls -la ${LAMBDA_RUNTIME_DIR}/
RUN ldd ${LAMBDA_RUNTIME_DIR}/bootstrap || true

# Set the CMD properly
CMD [ "bootstrap" ]
