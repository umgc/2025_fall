#!/bin/bash

echo "======================================="
echo " Building Spring Boot ZIP for AWS Lambda"
echo "======================================="

# Make sure the maven wrapper is executable
chmod +x mvnw

# Run Maven clean and package commands, skipping tests
./mvnw clean package  -DskipTests

# Check the exit code of the last command
if [ $? -eq 0 ]; then
  echo ""
  echo "************************"
  echo "* BUILD SUCCESSFUL   *"
  echo "************************"
  echo "Your ZIP file is located in the 'target' directory."
else
  echo ""
  echo "********************"
  echo "* BUILD FAILED   *"
  echo "********************"
fi

echo ""