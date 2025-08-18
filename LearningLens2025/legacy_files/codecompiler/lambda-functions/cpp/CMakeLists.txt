cmake_minimum_required(VERSION 3.13)
project(cpp-executor)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find AWS Lambda Runtime
find_package(aws-lambda-runtime REQUIRED)

# Add executable
add_executable(${PROJECT_NAME} main.cpp)

# Link AWS Lambda Runtime
target_link_libraries(${PROJECT_NAME} 
    AWS::aws-lambda-runtime
    pthread
)

# Compile flags for comprehensive C++ environment
target_compile_options(${PROJECT_NAME} PRIVATE 
    -Wall 
    -Wextra 
    -O2 
    -fstack-protector-strong
)
