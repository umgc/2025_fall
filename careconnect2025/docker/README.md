# **CareConnect OCR Processor**

This project contains a standalone OCR (Optical Character Recognition) processing service designed to be run as a container. It can extract text from images (PNG, JPG) and PDF documents using Tesseract.

The service is intended to be deployed as an AWS Lambda function, triggered by file uploads to an S3 bucket, with the results stored in a DynamoDB table.

This guide provides instructions for building the Docker container, running it locally for testing, and deploying the full AWS stack.

## **Prerequisites**

* [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine installed and running.  
* (Optional) An account on [Docker Hub](https://hub.docker.com/) for sharing the image publicly.  
* (Optional) An AWS account and the [AWS CLI](https://aws.amazon.com/cli/) configured for cloud deployment.  
* (Optional) [Node.js and npm](https://nodejs.org/en/) to use the Serverless Framework for deployment.

## **1\. Local Development and Testing**

This section covers how to build the Docker container and test its functionality on your local machine.

### **Building the Docker Container**

The container includes all necessary system libraries (like Tesseract and Poppler) and Python dependencies.

**Important**: To ensure compatibility with AWS Lambda, you must build the image for the linux/amd64 architecture, especially if you are on a Mac with Apple Silicon (M1/M2/M3).

Use the following command from the root of this project to build the image:

docker buildx build \--platform linux/amd64 \--provenance=false \-t ocr-processor:latest \--load .

### **Running Local Tests**

The app.py script includes a local test block that will process sample files without needing any AWS connections.

1. **Prepare Test Files**: Make sure you have invoiceSample.png and invoiceSample.pdf in the same directory where you will run the command.  
2. **Run the Container**: Execute the following command to start the container. It will mount your current directory into the container, run the OCR script on your test files, print the output to your terminal, and then clean itself up.  
   docker run \-it \--rm \-v "$PWD":/var/task \--entrypoint python3 ocr-processor:latest app.py

## **2\. Sharing the Container Image**

To allow others to use your container without building it from the source, you can push the image to a public container registry like Docker Hub.

### **Step 1: Log in to Docker Hub**

From your terminal, log in with your Docker Hub username and password.

docker login

### **Step 2: Tag the Image**

Tag your locally built ocr-processor image with your Docker Hub username. Replace \<your-dockerhub-username\> with your actual username.

docker tag ocr-processor:latest \<your-dockerhub-username\>/ocr-processor:latest

*Example:*

docker tag ocr-processor:latest alltheelephants/ocr-processor:latest

### **Step 3: Push the Image to Docker Hub**

Push the tagged image to the public repository.

docker push \<your-dockerhub-username\>/ocr-processor:latest

*Example:*

docker push alltheelephants/ocr-processor:latest

### **Step 4: Public Usage**

Once the image is public on Docker Hub, anyone can download and run it with the following commands.

**Download the image:**

docker pull \<your-dockerhub-username\>/ocr-processor:latest

**Run the local test:**

docker run \-it \--rm \-v "$PWD":/var/task \--entrypoint python3 \<your-dockerhub-username\>/ocr-processor:latest app.py

## **3\. (Optional) Full AWS Deployment**

For instructions on deploying the full serverless backend (S3, Lambda, DynamoDB, IAM Role) using the serverless.yml file, please refer to the DEPLOYMENT.md guide.